# Arvan Photos Cleanup & Architecture Refactoring Plan

This plan follows the detailed task list provided by the user, focusing on cleaning up dead code, improving security, fixing architecture layering violations, and unifying error handling.

## User Review Required

> [!IMPORTANT]
> The `assets/env` file will be removed from the entire git history. This requires a force push to the repository. Please ensure all team members are aware of this.
> After history cleanup, **you must refresh your ArvanCloud Access/Secret keys** in the console as they have been exposed in the history.

## Proposed Changes

### 1. Cleanup & Dead Code Removal
- Finalize deletion of orphaned files:
  - `lib/features/photos/presentation/bloc/photos/photos_bloc.dart` (and related files)
  - `lib/features/photos/presentation/screens/photo_detail_screen.dart`
  - `lib/features/photos/presentation/bloc/detail/photo_detail_cubit.dart`
  - `lib/features/photos/domain/entities/photo_entity.dart`
  - `lib/features/photos/domain/usecases/upload_photo_usecase.dart`
  - `lib/features/photos/data/datasources/photos_remote_data_source_impl.dart` (Move `uploadPhoto` and `getCloudCount` to `CloudRemoteDataSource` first).
- Fix broken imports in `main.dart` and `app_background_service.dart`.
- Remove `sync_registry` table from `lib/core/database/app_database.dart`.
- Remove `getCloudCount()` from `PhotoCommandRepository` (it should stay only in `PhotoQueryRepository`).
- Clean up unused imports and variables as identified in the task list.

### 2. Security Improvements
- Remove `assets/env` from git history using `git filter-repo` or `git filter-branch`.
- Update `.gitignore` to include `assets/env`.
- Create `assets/env.example` as a template.

### 3. Clean Architecture Layering
- **Domain Layer Fixes:**
  - Create `UploadCancelToken` abstraction to replace Dio's `CancelToken` in Domain.
  - Pass `String path` instead of `File` in `PhotoCommandRepository`.
  - Introduce `DeviceAsset` entity to replace `photo_manager`'s `AssetEntity` in Domain/Presentation.
- **UseCase Integration:**
  - Create `GetLocalGalleryUseCase`, `GetBackupStatusUseCase`, `EnqueueUploadUseCase`, and `GetUploadTasksUseCase`.
  - Refactor `DeviceGalleryBloc` and `UploadBloc` to use these UseCases.
- **Typed Models & Entities:**
  - Replace `Map<String, dynamic>` with `BackupStatus` entity and `BackupQueueItem` model.

### 4. Error Handling Unification
- Update `CloudRepository` to return `Either<Failure, T>`.
- Use `try/catch` with `ErrorMapper` in `CloudRepositoryImpl`.
- Update `CloudBloc` to handle `Either` results and properly manage "load-more" errors.
- Improve error messages in `DeviceGalleryBloc`.

### 5. Bug Fixes
- Fix hardcoded `cloudCount: 0` in `DeviceGalleryBloc` using `GetCloudCountUseCase`.
- Handle load-more errors in `CloudBloc` (don't swallow exceptions).
- Fix double state emission in `DeviceGalleryBloc` after deletion failure.

### 6. Documentation & DI
- Document intentional stubs in `PhotosViewStubScreen` and `MainNavigationScreen`.
- Refactor DI in `AppBackgroundService` to use a shared module.
- Move feature-specific Blocs from root to screen-level providers.
- Add `bloc` package to `pubspec.yaml` dependencies.

## Verification Plan

### Automated Tests
- Run existing unit tests (if any) to ensure no regressions.
- Verify DI container builds successfully.

### Manual Verification
- Verify that `cloud` and `photos` (device gallery) tabs both function correctly.
- Check that backup status icons appear correctly in the device gallery.
- Verify that deleting a photo from the cloud updates the status icon to "unsynced".
- Test the background service by enqueuing a backup and checking the notification.
