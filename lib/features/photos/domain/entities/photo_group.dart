import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:equatable/equatable.dart';

class PhotoGroup extends Equatable {
  const PhotoGroup({
    required this.date,
    required this.photos,
  });

  final DateTime date;
  final List<PhotoEntity> photos;

  @override
  List<Object?> get props => [date, photos];
}
