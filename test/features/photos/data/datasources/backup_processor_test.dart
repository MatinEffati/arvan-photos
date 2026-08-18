import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Logic simulator to verify the concurrency limit of 5.
/// This mimics the behavior in BackupBackgroundService.
class ConcurrentUploadProcessor {
  final int maxConcurrent;
  final Set<String> activeUploads = {};
  int startedCount = 0;

  ConcurrentUploadProcessor(this.maxConcurrent);

  Future<void> processQueue(List<String> pendingIds, Future<void> Function(String id) startUpload) async {
    // Mimic the check:
    if (activeUploads.length >= maxConcurrent) {
      return;
    }

    // Mimic the limit in getPending:
    final toFetch = maxConcurrent - activeUploads.length;
    final fetchResult = pendingIds.take(toFetch).toList();

    for (final id in fetchResult) {
      if (activeUploads.contains(id)) continue;
      
      activeUploads.add(id);
      startedCount++;
      // We don't await startUpload here to simulate concurrent execution
      startUpload(id).then((_) => activeUploads.remove(id));
    }
  }
}

void main() {
  test('ConcurrentUploadProcessor should never exceed 5 concurrent uploads', () async {
    const maxConcurrent = 5;
    final processor = ConcurrentUploadProcessor(maxConcurrent);
    
    final completers = <String, Completer>{};
    final pendingIds = List.generate(20, (i) => 'id_$i');

    Future<void> startUpload(String id) {
      final completer = Completer<void>();
      completers[id] = completer;
      return completer.future;
    }

    // First pass: Should start 5
    await processor.processQueue(pendingIds, startUpload);
    expect(processor.activeUploads.length, 5);
    expect(processor.startedCount, 5);

    // Second pass: Should start 0 more because already at 5
    final remainingPending = pendingIds.sublist(5);
    await processor.processQueue(remainingPending, startUpload);
    expect(processor.activeUploads.length, 5);
    expect(processor.startedCount, 5);

    // Complete 2 uploads
    completers['id_0']!.complete();
    completers['id_1']!.complete();
    await Future.delayed(Duration.zero); // Let then() callbacks run

    expect(processor.activeUploads.length, 3);

    // Third pass: Should start 2 more to reach 5
    final pendingForThirdPass = pendingIds.sublist(5); 
    await processor.processQueue(pendingForThirdPass, startUpload);
    expect(processor.activeUploads.length, 5);
    expect(processor.startedCount, 7);
  });
}
