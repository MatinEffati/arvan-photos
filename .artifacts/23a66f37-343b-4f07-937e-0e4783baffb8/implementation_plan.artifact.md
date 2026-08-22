# Upload Status Badge Implementation Plan

This plan outlines the changes required to add upload status badges (progress and "backed up" states) to the device gallery grid, integrated with BLoC and Clean Architecture.

## Proposed Changes

### 1. Data Layer & Use Cases

#### [MODIFY] [ArvanS3Client](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/core/network/arvan_s3_client.dart)
- Update `upload` method to accept an optional `void Function(int sent, int total)? onProgress` callback.
- Pass `onProgress` to `Dio.putUri`.

#### [MODIFY] [PhotosRemoteDataSource](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/data/datasources/photos_remote_data_source.dart)
- Update `uploadPhoto` signature to accept `onProgress`.

#### [MODIFY] [PhotosRepository](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/repositories/photos_repository.dart)
- Update `uploadPhoto` signature to accept `onProgress`.

#### [MODIFY] [UploadPhotoUseCase](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/usecases/upload_photo_usecase.dart)
- Update `call` signature to accept `onProgress`.

### 2. BLoC (State Management)

#### [MODIFY] [UploadState](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/upload/upload_state.dart)
- Update `UploadState` to include `final Map<String, double> progressMap`.
- Ensure all subclasses (`UploadInitial`, `UploadInProgress`, `UploadSuccess`, `UploadFailure`) preserve this map so concurrent uploads are tracked.

#### [MODIFY] [UploadBloc](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/upload/upload_bloc.dart)
- Update `_onUploadRequested` to:
    - Update `progressMap` when progress changes.
    - Show notifications via `NotificationService`.
    - Handle success/failure by updating `progressMap` and emitting corresponding states.
- Inject `NotificationService` (or use it statically if it's a utility).

#### [MODIFY] [DeviceGalleryState](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/device_gallery/device_gallery_state.dart)
- Add `final Set<String> backedUpAssetIds` to `DeviceGalleryLoadSuccess`.

#### [MODIFY] [DeviceGalleryBloc](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart)
- Inject `PhotosLocalDataSource`.
- In `_onRequested`, query all registered backups and populate `backedUpAssetIds`.
- Listen to `UploadBloc` stream to refresh when a success occurs (or manually add a refresh event).

### 3. Presentation (UI)

#### [NEW] [UploadStatusBadge](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/upload_status_badge.dart)
- A new widget that renders either the circular progress or the "cloud done" icon.
- Uses a `CustomPainter` for the dashed arc progress.

#### [MODIFY] [LocalPhotoGridItem](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/local_photo_grid_item.dart)
- Add two `BlocSelector`s:
    1. `BlocSelector<UploadBloc, UploadState, double?>` for active upload progress.
    2. `BlocSelector<DeviceGalleryBloc, DeviceGalleryState, bool>` for backup status.
- Position the `UploadStatusBadge` at the bottom-right (4px margin).

### 4. Notifications

#### [MODIFY] [NotificationService](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/core/services/notification_service.dart)
- Add a method `showUploadProgress(int id, String title, int progress)` to show a notification with a progress bar.
- Ensure it uses the correct channel.

## Verification Plan

### Manual Verification
- Start an upload and verify the circular progress badge appears with the dashed arc.
- Verify the badge updates in real-time.
- Verify a notification appears with the progress bar.
- Verify the badge changes to the "cloud done" icon once the upload is complete.
- Restart the app and verify the "cloud done" icon persists (loading from local DB).
- Verify the badge is visible on both very light and very dark photos due to the semi-transparent background.
