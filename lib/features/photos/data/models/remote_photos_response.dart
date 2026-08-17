import 'package:arvan_photos/features/photos/data/models/photo_model.dart';

class RemotePhotosResponse {
  RemotePhotosResponse({
    required this.photos,
    this.nextToken,
  });

  final List<PhotoModel> photos;
  final String? nextToken;
}
