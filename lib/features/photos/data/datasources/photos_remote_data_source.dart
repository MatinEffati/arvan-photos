import 'dart:io';
import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:injectable/injectable.dart';
import 'package:xml/xml.dart';

abstract class PhotosRemoteDataSource {
  Future<void> uploadPhoto(
    File file,
    String remoteKey, {
    void Function(int sent, int total)? onProgress,
  });
  Future<void> deletePhoto(String remoteKey);
  Future<List<String>> listPhotos();
}

@LazySingleton(as: PhotosRemoteDataSource)
class PhotosRemoteDataSourceImpl implements PhotosRemoteDataSource {
  PhotosRemoteDataSourceImpl(this._s3client);

  final ArvanS3Client _s3client;

  @override
  Future<void> uploadPhoto(
    File file,
    String remoteKey, {
    void Function(int sent, int total)? onProgress,
  }) {
    return _s3client.upload(file, remoteKey, onProgress: onProgress);
  }

  @override
  Future<void> deletePhoto(String remoteKey) {
    return _s3client.delete(remoteKey);
  }

  @override
  Future<List<String>> listPhotos() async {
    final response = await _s3client.list();
    return response.contents
        .map<String>((e) => e.findAllElements('Key').first.innerText)
        .toList();
  }
}
