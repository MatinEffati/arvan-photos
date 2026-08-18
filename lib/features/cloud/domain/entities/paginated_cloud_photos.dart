import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:equatable/equatable.dart';

class PaginatedCloudPhotos extends Equatable {
  const PaginatedCloudPhotos({
    required this.photos,
    this.nextContinuationToken,
  });

  final List<CloudPhoto> photos;
  final String? nextContinuationToken;

  @override
  List<Object?> get props => [photos, nextContinuationToken];
}
