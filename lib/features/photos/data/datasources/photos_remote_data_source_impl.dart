import 'dart:io';

import 'package:arvan_photos/core/error/exceptions.dart';
import 'package:arvan_photos/core/network/arvan_s3_client.dart';
import 'package:arvan_photos/features/photos/data/datasources/photos_remote_data_source.dart';
import 'package:arvan_photos/features/photos/data/models/photo_model.dart';
import 'package:arvan_photos/features/photos/data/models/remote_photos_response.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PhotosRemoteDataSource)
class PhotosRemoteDataSourceImpl implements PhotosRemoteDataSource {
  PhotosRemoteDataSourceImpl(this._client);

  final ArvanS3Client _client;

  @override
  Future<RemotePhotosResponse> getPhotos({
    String? continuationToken,
    int maxKeys = 20,
  }) async {
    try {
      final response = await _client.listObjects(
        continuationToken: continuationToken,
        maxKeys: maxKeys,
      );

      final photos = response.contents
          .map((e) => PhotoModel.fromXmlElement(e, _client.baseUrl))
          .toList();

      return RemotePhotosResponse(
        photos: photos,
        nextToken: response.nextContinuationToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> uploadPhoto(
    String key,
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      await _client.putObject(key, file, onProgress: onProgress);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deletePhoto(String key) async {
    try {
      await _client.deleteObject(key);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(message: e.message);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 403) {
          return PermissionException(message: 'Access Denied (403)');
        }
        return ServerException(
          message: e.message,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return ServerException(message: e.message);
    }
  }
}
