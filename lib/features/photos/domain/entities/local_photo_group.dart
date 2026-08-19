import 'package:arvan_photos/features/photos/domain/entities/device_asset.dart';
import 'package:equatable/equatable.dart';

class LocalPhotoGroup extends Equatable {
  const LocalPhotoGroup({
    required this.title,
    required this.date,
    required this.assets,
  });

  final String title;
  final DateTime date;
  final List<DeviceAsset> assets;

  @override
  List<Object?> get props => [title, date, assets];
}
