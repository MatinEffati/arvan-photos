import 'package:arvan_photos/features/photos/data/datasources/backup_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase extends Mock implements Database {}

class MockBatch extends Mock implements Batch {}

void main() {
  late BackupLocalDataSourceImpl dataSource;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;

  setUp(() {
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();
    dataSource = BackupLocalDataSourceImpl(mockDatabase);
  });

  group('BackupLocalDataSource', () {
    test('enqueue should use batch insert for non-synced items', () async {
      // Arrange
      // Mock getSyncedIds call which is used inside enqueue
      when(() => mockDatabase.query(
            'backup_queue',
            columns: ['local_asset_id'],
            where: 'status = ?',
            whereArgs: ['synced'],
          )).thenAnswer((_) async => []);

      when(() => mockDatabase.batch()).thenReturn(mockBatch);
      when(() => mockBatch.insert(
            any(),
            any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'),
          )).thenReturn(null);
      when(() => mockBatch.commit(noResult: any(named: 'noResult')))
          .thenAnswer((_) async => []);

      // Act
      await dataSource.enqueue([
        {'id': 'id1', 'path': 'path1'},
        {'id': 'id2', 'path': 'path2'},
      ]);

      // Assert
      verify(() => mockDatabase.batch()).called(1);
      verify(() => mockBatch.insert(
            'backup_queue',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          )).called(2);
      verify(() => mockBatch.commit(noResult: true)).called(1);
    });

    test('updateStatus should update the correct row', () async {
      // Arrange
      when(() => mockDatabase.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      // Act
      await dataSource.updateStatus('id1', 'uploading', progress: 0.5);

      // Assert
      verify(() => mockDatabase.update(
            'backup_queue',
            {'status': 'uploading', 'progress': 0.5},
            where: 'local_asset_id = ?',
            whereArgs: ['id1'],
          )).called(1);
    });
  });
}
