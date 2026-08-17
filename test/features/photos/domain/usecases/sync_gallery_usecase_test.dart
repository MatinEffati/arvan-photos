import 'dart:io';

import 'package:arvan_photos/core/error/failures.dart';
import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/sync_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/usecases/sync_gallery_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';

class MockDeviceGalleryDataSource extends Mock implements DeviceGalleryDataSource {}
class MockSyncLocalDataSource extends Mock implements SyncLocalDataSource {}
class MockPhotoCommandRepository extends Mock implements PhotoCommandRepository {}
class MockAssetEntity extends Mock implements AssetEntity {}
class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

void main() {
  late SyncGalleryUseCase useCase;
  late MockDeviceGalleryDataSource mockDeviceDataSource;
  late MockSyncLocalDataSource mockSyncLocalDataSource;
  late MockPhotoCommandRepository mockCommandRepository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockDeviceDataSource = MockDeviceGalleryDataSource();
    mockSyncLocalDataSource = MockSyncLocalDataSource();
    mockCommandRepository = MockPhotoCommandRepository();
    useCase = SyncGalleryUseCase(
      mockDeviceDataSource,
      mockSyncLocalDataSource,
      mockCommandRepository,
    );
  });

  test('should sync only new photos and skip already synced ones', () async {
    // Arrange
    final asset1 = MockAssetEntity();
    final asset2 = MockAssetEntity();
    final file2 = MockFile();
    
    when(() => asset1.id).thenReturn('id1');
    when(() => asset2.id).thenReturn('id2');
    when(() => asset2.file).thenAnswer((_) async => file2);
    
    when(() => mockDeviceDataSource.getLocalAssets())
        .thenAnswer((_) async => [asset1, asset2]);
    
    when(() => mockSyncLocalDataSource.getAllSyncedIds())
        .thenAnswer((_) async => ['id1']); // asset1 is already synced
    
    when(() => mockCommandRepository.uploadPhoto(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    
    when(() => mockSyncLocalDataSource.markSynced(any(), any()))
        .thenAnswer((_) async => {});

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Right<Failure, Unit>(unit));
    
    // Check that only asset2 was uploaded
    verify(() => mockCommandRepository.uploadPhoto(file2)).called(1);
    verifyNever(() => mockCommandRepository.uploadPhoto(any(that: isNot(file2))));
    
    // Check registry update
    verify(() => mockSyncLocalDataSource.markSynced('id2', any())).called(1);
  });
}
