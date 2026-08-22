# Restore & Merge Upload/Delete Functionality

This plan restores the previously removed cloud upload and delete capabilities, integrating them fully into the `photos` feature following Clean Architecture principles.

## User Review Required

> [!IMPORTANT]
> - **S3 Configuration**: Ensure your `.env` file contains `ARVAN_BUCKET`, `ARVAN_ACCESS_KEY`, `ARVAN_SECRET_KEY`, `ARVAN_ENDPOINT`, and `ARVAN_REGION`.
> - **Background Service**: The background upload logic will be restored to allow uploads to continue even when the app is minimized.

## Proposed Changes

### [Infrastructure] Core & Network

#### [MODIFY] [app_config.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/core/config/app_config.dart)
- Add `arvanBucket` getter.

#### [NEW] [arvan_s3_client.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/core/network/arvan_s3_client.dart)
- Implement S3 request signing using `aws_signature_v4`.
- Methods: `upload`, `delete`, `list`.

---

### [Data Layer] Features/Photos

#### [NEW] [photos_remote_data_source.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/data/datasources/photos_remote_data_source.dart)
- Interface and implementation using `ArvanS3Client`.

#### [NEW] [photos_repository_impl.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/data/repositories/photos_repository_impl.dart)
- Coordinate between local device gallery and remote cloud storage.

---

### [Domain Layer] Features/Photos

#### [NEW] [photos_repository.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/repositories/photos_repository.dart)
- Interface defining `uploadPhoto`, `deletePhoto`, and `getCloudPhotos`.

#### [NEW] [upload_photo_usecase.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/usecases/upload_photo_usecase.dart)
- Usecase for uploading a single photo.

#### [NEW] [delete_photo_usecase.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/domain/usecases/delete_photo_usecase.dart)
- Usecase for deleting a photo from cloud and/or device.

---

### [Presentation Layer] Features/Photos

#### [NEW] [upload_bloc.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/upload/upload_bloc.dart)
- Manage upload queue, background service communication, and progress updates.

#### [NEW] [delete_bloc.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/bloc/delete/delete_bloc.dart)
- Manage deletion requests and UI feedback.

#### [MODIFY] [device_gallery_screen.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/screens/device_gallery_screen.dart)
- Wire "Back up" button to `UploadBloc`.
- Wire "Trash" and "Delete from device" buttons to `DeleteBloc`.
- Display upload progress/status on grid items.

---

## Verification Plan

### Automated Tests
- Unit tests for `ArvanS3Client` signing logic.
- Mocked repository tests for `UploadPhotoUseCase`.

### Manual Verification
1.  **Upload**: Select photos in the gallery, tap "Back up", and verify they appear in ArvanCloud bucket.
2.  **Delete**: Select a photo, tap "Trash", and verify it is removed from cloud storage.
3.  **Background**: Start an upload, minimize the app, and check the notification for progress.
4.  **Status**: Verify that synced photos show the cloud icon in the gallery.
