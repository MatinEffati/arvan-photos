import 'dart:io';
import 'package:arvan_photos/core/config/app_config.dart';
import 'package:arvan_photos/core/network/models/s3_list_response.dart';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:xml/xml.dart';

@lazySingleton
class ArvanS3Client {
  ArvanS3Client(this._dio, this._config) {
    _signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(_config.arvanAccessKey, _config.arvanSecretKey),
      ),
    );

    _scope = AWSCredentialScope(
      region: _config.arvanRegion,
      service: AWSService.s3,
    );
  }

  final Dio _dio;
  final AppConfig _config;
  late final AWSSigV4Signer _signer;
  late final AWSCredentialScope _scope;

  String get baseUrl => _config.arvanEndpoint;

  Future<S3ListResponse> listObjects({
    String? continuationToken,
    int maxKeys = 20,
  }) async {
    final queryParams = {
      'list-type': '2',
      'max-keys': maxKeys.toString(),
      if (continuationToken != null) 'continuation-token': continuationToken,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final uri = Uri.parse('$baseUrl/?$queryString');
    final request = AWSHttpRequest(method: AWSHttpMethod.get, uri: uri);

    final signedRequest = await _signer.sign(request, credentialScope: _scope);
    
    final response = await _dio.getUri<dynamic>(
      uri,
      options: Options(headers: signedRequest.headers),
    );

    final document = XmlDocument.parse(response.data.toString());
    final contents = document.findAllElements('Contents').toList();
    final nextTokenElement = document.findAllElements('NextContinuationToken').firstOrNull;
    
    return S3ListResponse(
      contents: contents,
      nextContinuationToken: nextTokenElement?.innerText,
    );
  }

  Future<void> putObject(
    String key, 
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final uri = Uri.parse('$baseUrl/$key');
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: uri,
      body: bytes,
      headers: const {
        AWSHeaders.contentType: 'image/jpeg',
        'x-amz-acl': 'public-read',
      },
    );

    final signedRequest = await _signer.sign(request, credentialScope: _scope);

    await _dio.putUri<dynamic>(
      uri,
      data: Stream.fromIterable([bytes]),
      onSendProgress: onProgress,
      options: Options(
        headers: signedRequest.headers,
        contentType: 'image/jpeg',
      ),
    );
  }

  Future<void> deleteObject(String key) async {
    final uri = Uri.parse('$baseUrl/$key');
    final request = AWSHttpRequest(method: AWSHttpMethod.delete, uri: uri);

    final signedRequest = await _signer.sign(request, credentialScope: _scope);

    await _dio.deleteUri<dynamic>(
      uri,
      options: Options(headers: signedRequest.headers),
    );
  }
}
