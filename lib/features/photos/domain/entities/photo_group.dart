import 'package:equatable/equatable.dart';
import 'photo_entity.dart';

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
