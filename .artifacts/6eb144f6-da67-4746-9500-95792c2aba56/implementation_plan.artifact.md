# Gallery & Backup Implementation Plan

This plan outlines the implementation of a manual backup feature with background processing, similar to Google Photos. It replaces the previous automatic gallery sync logic.

## User Review Required

> [!IMPORTANT]
> **Manual Backup Only**: Automatic uploads are removed. Users must explicitly select photos and tap "Back Up".
> **Background Execution**: Background uploads will work reliably on Android using a Foreground Service. On iOS, background execution is limited and will be documented as a known constraint.

## Proposed Changes

### Core & Infrastructure

#### [MODIFY] [database_module.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/core/database/database_module.dart)
- Increment database version to 4.
- Add `backup_queue` table:
  ```sql
  CREATE TABLE backup_queue (
    local_asset_id TEXT PRIMARY KEY,
    remote_key TEXT,
    status TEXT NOT NULL,
    progress REAL DEFAULT 0,
    queued_at TEXT,
    synced_at TEXT
  );
  ```

---

### Data & Background Service

#### [NEW] [backup_local_datasource.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/data/datasources/backup_local_datasource.dart)
- CRUD operations for `backup_queue`.
- Methods: `enqueue`, `updateStatus`, `getAll`, `getPending`.

#### [NEW] [backup_background_service.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/data/datasources/backup_background_service.dart)
- Setup `flutter_background_service`.
- Logic for processing the queue (max 5 concurrent uploads).
- Notification updates using `flutter_local_notifications`.
- Communication with UI via `invoke`/`on`.

#### [MODIFY] [photo_command_repository.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/repositories/photo_command_repository.dart)
- Add methods to watch backup status and enqueue backups.

---

### Domain Layer

#### [NEW] [enqueue_backup_usecase.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/usecases/enqueue_backup_usecase.dart)
- Usecase to add selected assets to the backup queue and wake up the service.

---

### Presentation Layer

#### [NEW] [device_gallery_bloc.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart)
- Fetch local assets using `photo_manager`.
- Group assets by date (Today, Yesterday, Date).
- Handle selection state (Single, Multiple, Group, All).

#### [NEW] [backup_status_bloc.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart)
- Listen to background service events to update specific item statuses in the UI.

#### [NEW] [date_section_header.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/date_section_header.dart)
- Header with date text and a checkbox for group selection.

#### [NEW] [backup_action_bar.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/backup_action_bar.dart)
- Floating bottom bar appearing when items are selected.

#### [MODIFY] [photo_grid_item.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/photo_grid_item.dart)
- Add status overlays:
  - None/Grey: Not backed up.
  - Spinner/Progress: Uploading.
  - Cloud: Synced.
  - Error Icon: Failed.

---

## Verification Plan

### Automated Tests
- Unit tests for date grouping logic in `DeviceGalleryBloc`.
- Unit tests for `BackupLocalDataSource` CRUD operations.

### Manual Verification
1.  Open the gallery.
2.  Select a few photos and tap "Back Up".
3.  Observe the persistent notification on Android.
4.  Kill the app and check if the upload continues (via logs/notification).
5.  Re-open the app and verify the cloud icon appears on backed-up photos.
6.  Test "Select All" and group selection via date headers.
