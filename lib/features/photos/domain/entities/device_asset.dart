import 'package:equatable/equatable.dart';

class DeviceAsset extends Equatable {
  const DeviceAsset({
    required this.id,
    required this.modifiedDateTime,
    this.title,
    this.width,
    this.height,
    this.duration,
  });

  final String id;
  final DateTime modifiedDateTime;
  final String? title;
  final int? width;
  final int? height;
  final Duration? duration;

  @override
  List<Object?> get props => [id, modifiedDateTime, title, width, height, duration];
}
