import 'dart:io';
import 'package:arvan_photos/features/photos/data/models/remote_photos_response.dart';

import 'package:dio/dio.dart';

abstract class PhotosRemoteDataSource {
  Future<RemotePhotosResponse> getPhotos({
    String? continuationToken,
    int maxKeys = 20,
  });

  Future<void> uploadPhoto(
    String key,
    File file, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });

  Future<void> deletePhoto(String key);
}
