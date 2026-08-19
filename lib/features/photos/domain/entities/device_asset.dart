import 'package:equatable/equatable.dart';

class DeviceAsset extends Equatable {
  final String id;
  final DateTime modifiedDateTime;
  final int width;
  final int height;
  final Duration duration;
  final int typeInt;

  const DeviceAsset({
    required this.id,
    required this.modifiedDateTime,
    required this.width,
    required this.height,
    required this.duration,
    required this.typeInt,
  });

  @override
  List<Object?> get props => [id, modifiedDateTime, width, height, duration, typeInt];
}
