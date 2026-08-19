import 'dart:io';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:xml/xml.dart';

class S3ListResponse {
  S3ListResponse({required this.contents, this.nextContinuationToken});
  final List<XmlElement> contents;
  final String? nextContinuationToken;
}

@lazySingleton
class ArvanS3Client {
  ArvanS3Client(this._dio) {
    _baseUrl = dotenv.env['ARVAN_ENDPOINT'] ?? '';
    _region = dotenv.env['ARVAN_REGION'] ?? '';
    _accessKey = dotenv.env['ARVAN_ACCESS_KEY'] ?? '';
    _secretKey = dotenv.env['ARVAN_SECRET_KEY'] ?? '';
    
    _signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(_accessKey, _secretKey),
      ),
    );

    _scope = AWSCredentialScope(
      region: _region,
      service: AWSService.s3,
    );
  }

  final Dio _dio;
  late final String _baseUrl;
  late final String _region;
  late final String _accessKey;
  late final String _secretKey;
  late final AWSSigV4Signer _signer;
  late final AWSCredentialScope _scope;

  String get baseUrl => _baseUrl;

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
    
    final uri = Uri.parse('$_baseUrl/?$queryString');
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: uri,
    );

    final signedRequest = await _signer.sign(
      request,
      credentialScope: _scope,
    );
    
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

  Future<void> putObject(String key, File file) async {
    final bytes = await file.readAsBytes();
    final uri = Uri.parse('$_baseUrl/$key');
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: uri,
      body: bytes,
      headers: const {
        AWSHeaders.contentType: 'image/jpeg',
        'x-amz-acl': 'public-read', // هدر برای دسترسی پابلیک به فایل جدید
      },
    );

    final signedRequest = await _signer.sign(
      request,
      credentialScope: _scope,
    );

    await _dio.putUri<dynamic>(
      uri,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: signedRequest.headers,
        contentType: 'image/jpeg',
      ),
    );
  }

  Future<void> deleteObject(String key) async {
    final uri = Uri.parse('$_baseUrl/$key');
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.delete,
      uri: uri,
    );

    final signedRequest = await _signer.sign(
      request,
      credentialScope: _scope,
    );

    await _dio.deleteUri<dynamic>(
      uri,
      options: Options(headers: signedRequest.headers),
    );
  }
}
