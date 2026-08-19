class BackupQueueItem {
  final String localAssetId;
  final String? remoteKey;
  final String? filePath;
  final String status;
  final double progress;
  final String? queuedAt;
  final String? syncedAt;

  BackupQueueItem({
    required this.localAssetId,
    this.remoteKey,
    this.filePath,
    required this.status,
    this.progress = 0.0,
    this.queuedAt,
    this.syncedAt,
  });

  factory BackupQueueItem.fromMap(Map<String, dynamic> map) {
    return BackupQueueItem(
      localAssetId: map['local_asset_id'] as String,
      remoteKey: map['remote_key'] as String?,
      filePath: map['file_path'] as String?,
      status: map['status'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      queuedAt: map['queued_at'] as String?,
      syncedAt: map['synced_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_asset_id': localAssetId,
      'remote_key': remoteKey,
      'file_path': filePath,
      'status': status,
      'progress': progress,
      'queued_at': queuedAt,
      'synced_at': syncedAt,
    };
  }
}
