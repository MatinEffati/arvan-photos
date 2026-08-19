import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:arvan_photos/features/photos/domain/usecases/delete_backup_from_cloud_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/enqueue_backup_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_asset_path_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_backup_status_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_cloud_count_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_local_gallery_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/get_synced_ids_usecase.dart';
import 'package:arvan_photos/features/photos/domain/usecases/watch_backup_status_usecase.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetLocalGalleryUseCase extends Mock implements GetLocalGalleryUseCase {}
class MockGetBackupStatusUseCase extends Mock implements GetBackupStatusUseCase {}
class MockGetSyncedIdsUseCase extends Mock implements GetSyncedIdsUseCase {}
class MockGetAssetPathUseCase extends Mock implements GetAssetPathUseCase {}
class MockGetCloudCountUseCase extends Mock implements GetCloudCountUseCase {}
class MockEnqueueBackupUseCase extends Mock implements EnqueueBackupUseCase {}
class MockDeleteBackupFromCloudUseCase extends Mock implements DeleteBackupFromCloudUseCase {}
class MockWatchBackupStatusUseCase extends Mock implements WatchBackupStatusUseCase {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeviceGalleryBloc bloc;
  late MockGetLocalGalleryUseCase mockGetLocalGallery;
  late MockGetBackupStatusUseCase mockGetBackupStatuses;
  late MockGetSyncedIdsUseCase mockGetSyncedIds;
  late MockGetAssetPathUseCase mockGetAssetPath;
  late MockGetCloudCountUseCase mockGetCloudCount;
  late MockEnqueueBackupUseCase mockEnqueueBackup;
  late MockDeleteBackupFromCloudUseCase mockDeleteBackup;
  late MockWatchBackupStatusUseCase mockWatchBackupStatus;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    mockGetLocalGallery = MockGetLocalGalleryUseCase();
    mockGetBackupStatuses = MockGetBackupStatusUseCase();
    mockGetSyncedIds = MockGetSyncedIdsUseCase();
    mockGetAssetPath = MockGetAssetPathUseCase();
    mockGetCloudCount = MockGetCloudCountUseCase();
    mockEnqueueBackup = MockEnqueueBackupUseCase();
    mockDeleteBackup = MockDeleteBackupFromCloudUseCase();
    mockWatchBackupStatus = MockWatchBackupStatusUseCase();
    mockPrefs = MockSharedPreferences();

    when(() => mockWatchBackupStatus()).thenAnswer((_) => const Stream.empty());

    bloc = DeviceGalleryBloc(
      mockGetLocalGallery,
      mockGetBackupStatuses,
      mockGetSyncedIds,
      mockGetAssetPath,
      mockGetCloudCount,
      mockEnqueueBackup,
      mockDeleteBackup,
      mockWatchBackupStatus,
      mockPrefs,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('DeviceGalleryBloc', () {
    final now = DateTime.now();
    final todayAsset = DeviceAsset(id: 'today_id', modifiedDateTime: now);
    final yesterdayAsset = DeviceAsset(id: 'yesterday_id', modifiedDateTime: now.subtract(const Duration(days: 1)));
    final olderAsset = DeviceAsset(id: 'older_id', modifiedDateTime: DateTime(2023, 1, 1));

    blocTest<DeviceGalleryBloc, DeviceGalleryState>(
      'emits [LoadInProgress, LoadSuccess] with grouped assets when requested',
      build: () {
        when(() => mockGetLocalGallery())
            .thenAnswer((_) async => [todayAsset, yesterdayAsset, olderAsset]);
        when(() => mockPrefs.getBool(any())).thenReturn(false);
        when(() => mockPrefs.getInt(any())).thenReturn(3);
        when(() => mockGetSyncedIds()).thenAnswer((_) async => []);
        when(() => mockGetBackupStatuses()).thenAnswer((_) async => []);
        when(() => mockGetCloudCount()).thenAnswer((_) async => const Right(0));
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
        return bloc;
      },
      seed: () => const DeviceGalleryLoadSuccess(
        groups: [],
        selectedAssetIds: {'id1'},
      ),
      act: (bloc) => bloc.add(const DeviceGallerySelectionToggled('id1')),
      expect: () => [
        isA<DeviceGalleryLoadSuccess>().having(
          (s) => s.selectedAssetIds,
          'selectedAssetIds',
          <String>{},
        ),
      ],
    );
  });
}
