import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:equatable/equatable.dart';

class PaginatedPhotos extends Equatable {
  const PaginatedPhotos({
    required this.photos,
    this.nextContinuationToken,
  });

  final List<PhotoEntity> photos;
  final String? nextContinuationToken;

  @override
  List<Object?> get props => [photos, nextContinuationToken];
}
