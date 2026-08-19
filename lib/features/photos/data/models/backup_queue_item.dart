class BackupQueueItem {
  final String localAssetId;
  final String status;
  final double progress;
  final String? remoteKey;
  final String? filePath;
  final DateTime? queuedAt;
  final DateTime? syncedAt;

  BackupQueueItem({
    required this.localAssetId,
    required this.status,
    this.progress = 0.0,
    this.remoteKey,
    this.filePath,
    this.queuedAt,
    this.syncedAt,
  });

  factory BackupQueueItem.fromMap(Map<String, dynamic> map) {
    return BackupQueueItem(
      localAssetId: map['local_asset_id'] as String,
      status: map['status'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      remoteKey: map['remote_key'] as String?,
      filePath: map['file_path'] as String?,
      queuedAt: map['queued_at'] != null ? DateTime.parse(map['queued_at'] as String) : null,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_asset_id': localAssetId,
      'status': status,
      'progress': progress,
      'remote_key': remoteKey,
      'file_path': filePath,
      'queued_at': queuedAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }
}
