import 'package:equatable/equatable.dart';
import 'photo_entity.dart';

class PaginatedPhotos extends Equatable {
  const PaginatedPhotos({
    required this.photos,
    this.nextContinuationToken,
  });

  final List<PhotoEntity> photos;
  final String? nextContinuationToken;

  bool get hasMore => nextContinuationToken != null;

  @override
  List<Object?> get props => [photos, nextContinuationToken];
}
