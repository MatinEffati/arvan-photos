import 'package:equatable/equatable.dart';
import 'package:photo_manager/photo_manager.dart';

class LocalPhotoGroup extends Equatable {
  const LocalPhotoGroup({
    required this.title,
    required this.date,
    required this.assets,
  });

  final String title;
  final DateTime date;
  final List<AssetEntity> assets;

  @override
  List<Object?> get props => [title, date, assets];
}
