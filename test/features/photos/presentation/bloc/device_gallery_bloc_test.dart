import 'package:arvan_photos/features/photos/data/datasources/device_gallery_datasource.dart';
import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:arvan_photos/features/photos/domain/repositories/photo_command_repository.dart';
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDeviceGalleryDataSource extends Mock implements DeviceGalleryDataSource {}
class MockEnqueueBackupUseCase extends Mock implements EnqueueBackupUseCase {}
class MockBackupLocalDataSource extends Mock implements BackupLocalDataSource {}
class MockPhotoCommandRepository extends Mock implements PhotoCommandRepository {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  late DeviceGalleryBloc bloc;
  late MockDeviceGalleryDataSource mockDataSource;
  late MockEnqueueBackupUseCase mockEnqueueUseCase;
  late MockBackupLocalDataSource mockBackupLocalDataSource;
  late MockPhotoCommandRepository mockRepository;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockDataSource = MockDeviceGalleryDataSource();
    mockEnqueueUseCase = MockEnqueueBackupUseCase();
    mockBackupLocalDataSource = MockBackupLocalDataSource();
    mockRepository = MockPhotoCommandRepository();
    mockPrefs = MockSharedPreferences();

    when(() => mockRepository.watchBackupStatus()).thenAnswer((_) => const Stream.empty());

    bloc = DeviceGalleryBloc(
      mockDataSource,
      mockEnqueueUseCase,
      mockBackupLocalDataSource,
      mockRepository,
      mockPrefs,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('DeviceGalleryBloc', () {
    final now = DateTime.now();
    final todayAsset = MockAssetEntity();
    final yesterdayAsset = MockAssetEntity();
    final olderAsset = MockAssetEntity();

    setUp(() {
      when(() => todayAsset.createDateTime).thenReturn(now);
      when(() => todayAsset.id).thenReturn('today_id');
      
      when(() => yesterdayAsset.createDateTime).thenReturn(now.subtract(const Duration(days: 1)));
      when(() => yesterdayAsset.id).thenReturn('yesterday_id');

      when(() => olderAsset.createDateTime).thenReturn(DateTime(2023, 1, 1));
      when(() => olderAsset.id).thenReturn('older_id');
    });

    blocTest<DeviceGalleryBloc, DeviceGalleryState>(
      'emits [LoadInProgress, LoadSuccess] with grouped assets when requested',
      build: () {
        when(() => mockDataSource.getLocalAssets())
            .thenAnswer((_) async => [todayAsset, yesterdayAsset, olderAsset]);
        when(() => mockPrefs.getBool(any())).thenReturn(false);
        when(() => mockBackupLocalDataSource.getSyncedIds()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(const DeviceGalleryRequested()),
      expect: () => [
        DeviceGalleryLoadInProgress(),
        isA<DeviceGalleryLoadSuccess>().having(
          (s) => s.groups.length,
          'groups length',
          3,
        ).having(
          (s) => s.groups[0].title,
          'first group title',
          'Today',
        ).having(
          (s) => s.groups[1].title,
          'second group title',
          'Yesterday',
        ),
      ],
    );

    blocTest<DeviceGalleryBloc, DeviceGalleryState>(
      'toggles selection correctly',
      build: () {
        when(() => mockDataSource.getLocalAssets())
            .thenAnswer((_) async => [todayAsset]);
        return bloc;
      },
      seed: () => const DeviceGalleryLoadSuccess(
        groups: [],
        selectedAssetIds: {'id1'},
      ),
      act: (bloc) => bloc.add(const DeviceGallerySelectionToggled('id1')),
      expect: () => [
        const DeviceGalleryLoadSuccess(groups: [], selectedAssetIds: {}),
      ],
    );
  });
}
