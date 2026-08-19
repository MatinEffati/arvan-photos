# Arvan Photos 📸

A Flutter photo backup and gallery application, built as an engineering exercise to closely replicate the core experience of **Google Photos**: device gallery browsing grouped by date, manual and automatic backup, real-time upload status, and background sync — backed by **ArvanCloud Object Storage** (S3-compatible) instead of Google's infrastructure.

This document explains not just *what* was built, but *why* each architectural decision was made — every choice below should be defensible in a code review or a technical interview.

---

## 🌍 Language Versions
- [**Persian (فارسی)**](README_FA.md)

---

## 🎯 Scope

Built to closely mirror Google Photos' main screen and backup flow:

| Included | Explicitly out of scope |
|---|---|
| Device gallery grouped by date, with manual selection (single / date-group / select-all) | Sharing photos, albums with collaborators |
| Opt-in automatic backup (off by default) for the whole device, existing + future photos | Face grouping / "Memories" / any ML-based features |
| Background upload that survives app closure (Android foreground service) | True background execution on iOS (see [Known Limitations](#-known-limitations--trade-offs)) |
| Per-photo status overlay: not backed up / uploading (%) / synced / failed, with retry | "Stack similar photos" / "Show shimmer" (present in UI as stubs, not functional — see below) |
| Crop & rotate editing (overwrites the original) | Multi-version edit history, filters |
| Persistent notification with live progress ("X of Y backed up") | Wifi-only backup toggle (documented as a natural future addition) |

Search, Library, Collections, and Trash exist as navigable stub screens with an explicit empty state — this was a deliberate scope decision, not an oversight.

---

## 🚀 Features

- ☁️ **ArvanCloud S3 Integration** — full object lifecycle (List, Upload, Delete) against S3-compatible storage
- 🖼️ **Google Photos–style gallery** — date-grouped grid, single/group/select-all, per-photo backup status icons
- 🔄 **Dual backup model** — manual selection *and* an opt-in automatic backup toggle, sharing the same underlying queue so they never conflict or double-upload
- 🧵 **Concurrency-controlled upload queue** — max 5 simultaneous uploads regardless of how many photos are queued, so a 5,000-photo library doesn't flood the network or the device
- 📴 **True background execution (Android)** — uploads continue via a foreground service even after the app is closed
- 🔔 **Live progress notification** — persistent notification reflecting queue state
- 💾 **Offline-first local state** — SQLite (`sqflite`) tracks per-photo backup status, so the UI is always consistent with reality, even after app restarts
- ✂️ **Crop & rotate editing** — overwrites the original object on the same key

---

## 🏗️ Architecture

**Clean Architecture**, three layers, one dependency rule: dependencies point inward only.

```
presentation  ──depends on──>  domain  <──depends on── data
   (UI, BLoC)                (Entities,          (Repository Impl,
                            UseCases,              Remote/Local
                            Repo Interfaces)       DataSources)
```

- **Domain** has zero imports from Flutter, S3, or SQLite — pure Dart. This is what makes UseCases trivially unit-testable without a device or emulator.
- **Data** implements the interfaces `domain` defines. Swapping ArvanCloud for another S3-compatible provider touches this layer only.
- **Presentation** talks to `domain` exclusively — never reaches into `data` directly.

Folder structure is **feature-first**, layered inside each feature (`features/photos/{data,domain,presentation}`), which scales better than a single top-level `data/domain/presentation` split once a project grows past one feature.

### SOLID, concretely

| Principle | Where | Why it matters here |
|---|---|---|
| **S**ingle Responsibility | Each UseCase does exactly one thing (`UploadPhotoUseCase`, `DeletePhotoUseCase`, `EnqueueBackupUseCase`); `ArvanS3Client` only signs and sends HTTP — it knows nothing about BLoC or UI | Changing delete logic can't accidentally break upload logic |
| **O**pen/Closed | `PhotoRepository` is an abstract interface; a new data source can be added without touching existing callers | Adding a caching layer later doesn't require editing every BLoC |
| **L**iskov Substitution | Any `PhotoRepository` implementation (real or `FakePhotoRepository` in tests) is interchangeable | This is literally what makes BLoC unit tests possible without a network |
| **I**nterface Segregation | Read and write concerns are kept on separate, focused interfaces rather than one bloated repository | A BLoC that only lists photos isn't forced to depend on delete/upload methods |
| **D**ependency Inversion | Presentation and Domain depend on `PhotoRepository` (an abstraction), never on `ArvanS3Client` directly; wiring is done via `get_it` + `injectable` | The core of Clean Architecture — this is the one principle that, if violated, collapses the whole structure |

### Design patterns in use

| Pattern | Where | Why |
|---|---|---|
| Repository | `PhotoRepository` / `PhotoRepositoryImpl` | Isolates domain logic from storage details |
| UseCase (Command) | One class per operation, each with a `call()` method | Each action is independently testable and composable |
| Adapter | `ArvanS3Client` | Hides raw AWS SigV4 signing and HTTP details behind a clean interface |
| Strategy | Sort options (date/name/size) | New sort criteria can be added without touching grid rendering code |
| Result/Either | `Either<Failure, T>` (via `dartz`) as the return type of every UseCase | Errors are explicit and type-checked, not discovered via uncaught exceptions |
| Dependency Injection | `get_it` + `injectable` | No manual wiring in widgets; trivial to substitute mocks in tests |
| Observer (via BLoC/Streams) | Every BLoC exposes a `Stream<State>` | UI reacts to state changes without polling |

### Why a hand-rolled S3 client instead of an SDK

Rather than pulling in the full `minio` package, the S3 client here is built directly on `dio` + `aws_signature_v4` + manual XML parsing (`xml` package). This was a deliberate trade-off:

- **Pro:** full visibility into exactly what's being signed and sent — genuinely useful for debugging ArvanCloud-specific response quirks (e.g. `204 No Content` on delete, which some naive integrations mishandle by only checking for `200`)
- **Con:** more code to maintain than a battle-tested SDK would require
- This is the kind of trade-off worth being able to explain out loud, not just make silently

---

## 🔄 Backup Model in Detail

This is the most nuanced part of the project, so it's worth spelling out precisely:

1. **Manual backup (always available):** select any combination of individual photos, whole date groups, or the entire gallery, then tap **Back Up**.
2. **Automatic backup (opt-in, off by default):** a single toggle in Backup Settings. Turning it on enqueues every existing not-yet-synced photo *and* causes the background service to pick up new photos going forward. Turning it off stops future auto-enqueueing but does not cancel uploads already in flight.
3. **One shared queue:** both paths write to the same `backup_queue` table and are processed by the same background service loop — there is no separate "manual queue" vs "auto queue" to keep in sync, which is what prevents duplicate uploads or race conditions between the two triggers.
4. **Concurrency cap:** exactly 5 uploads active at any time, regardless of queue size — verified with a dedicated unit test that asserts this invariant under load (20+ queued items).
5. **Failure handling:** failed items are marked `failed`, shown with an error icon, and retried only when the user re-selects and re-triggers backup (an explicit UPSERT, not a silent automatic retry — silent retries would risk masking a real connectivity problem).

---

## 🛠️ Tech Stack

| Category | Tools | Why |
|---|---|---|
| State management | `flutter_bloc` | Explicit event/state contracts, first-class testability via `bloc_test` |
| Dependency Injection | `get_it`, `injectable` | Compile-time-safe wiring, no service-locator anti-pattern sprawl |
| Networking | `dio`, `aws_signature_v4`, `xml` | Fine-grained control over S3 request signing (see rationale above) |
| Local persistence | `sqflite` | The backup registry is inherently relational (per-photo status, progress, timestamps); a key-value store would mean hand-rolling what SQL already does. `sqflite` was chosen over `hive` specifically because Hive is no longer actively maintained by its creator |
| Background execution | `flutter_background_service`, `flutter_local_notifications` | The only reliable way to keep an upload queue alive after the Flutter UI isolate is gone (Android) |
| Device gallery | `photo_manager` | Efficient native gallery indexing, exposes stable per-asset identifiers |
| Image editing | `image_cropper` | Crop/rotate is the only editing requirement in scope |
| Error handling | `dartz` (`Either`) | See Design Patterns above |
| Testing | `bloc_test`, `mocktail` | Standard, actively maintained pairing for BLoC/Clean Architecture testing |
| Linting | `very_good_analysis` | Stricter than default `flutter_lints`; zero warnings on build |

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (recent stable channel)
- An ArvanCloud Object Storage bucket, set to **Public Read** (so `Image.network` can display photos without signing every GET)
- A Machine User (Access Key / Secret Key) — ideally scoped to just this bucket, not the full account

### Installation
```bash
git clone <repository-url>
cd arvan_photos
flutter pub get
```

### Environment Variables
Create a `.env` file (git-ignored — never commit real credentials):
```env
ARVAN_ACCESS_KEY=your_access_key
ARVAN_SECRET_KEY=your_secret_key
ARVAN_BUCKET=your_bucket_name
ARVAN_ENDPOINT=https://your-bucket.s3.ir-thr-at1.arvanstorage.ir
ARVAN_REGION=ir-thr-at1
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run
```bash
flutter run
```

> **Note:** `build_runner` >= 2.15.2 can conflict with the `meta` package version pinned by the Flutter SDK's `flutter_test`. If `flutter pub get` fails with a `meta` version solving error, pin `build_runner` to `^2.15.1`.

---

## 🧪 Testing

```bash
flutter test
```

| Layer | What's covered | Tooling |
|---|---|---|
| UseCases | Each UseCase in isolation, with a mocked repository | `mocktail` |
| BLoC | Event → expected state sequence for each BLoC | `bloc_test` |
| Concurrency invariant | Never more than 5 simultaneous uploads under a 20+ item queue | `mocktail` + custom fake queue |
| Date grouping | Correct bucketing of mixed-date asset lists into "Today"/"Yesterday"/date sections | plain unit test |

---

## ⚠️ Known Limitations & Trade-offs

Being explicit about these is intentional — they're scope decisions, not bugs:

- **Android only.** iOS background execution is aggressively limited by the OS and would require a materially different approach (e.g. `BGTaskScheduler` / background `URLSession`); this was out of scope from the start.
- **"Comfortable" and "Month" layout options, "Stack similar photos," and "Show shimmer"** exist visually in the Photos View settings screen but are non-functional stubs — they'd require on-device ML (similarity detection, subject recognition) that is well beyond a "clone the main screen" task.
- **No Wifi-only backup toggle.** A natural next addition, not implemented here.
- **Retry is manual, not automatic-with-backoff.** A deliberate choice: silent auto-retry can mask a real, ongoing connectivity problem from the user.
- **The Machine User's Access/Secret Key ship inside the app** (there's no backend to hold them server-side). This is acceptable for a demo/interview project scoped to one disposable bucket, but would need a backend-issued short-lived credential (or presigned URLs) in a production app with real user data.

---

## 📄 License

Built for an internal engineering task / portfolio purposes.