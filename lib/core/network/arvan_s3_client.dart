import 'dart:io';
import 'package:arvan_photos/core/config/app_config.dart';
import 'package:arvan_photos/core/network/models/s3_list_response.dart';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

@lazySingleton
class ArvanS3Client {
  ArvanS3Client(this._config, this._dio);

  final AppConfig _config;
  final Dio _dio;

  AWSSigV4Signer _getSigner() {
    return AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(
          _config.arvanAccessKey,
          _config.arvanSecretKey,
        ),
      ),
    );
  }

  Future<void> upload(File file, String remoteKey) async {
    final bytes = await file.readAsBytes();
    final baseUri = Uri.parse(_config.arvanEndpoint);
    
    // Build URI properly. Using pathSegments ensures correct encoding of special characters.
    // If remoteKey contains '/', we need to split it or use replace(path: ...) carefully.
    final uri = baseUri.replace(
      path: '${baseUri.path}/$remoteKey'.replaceAll('//', '/'),
    );
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: uri,
      body: bytes,
      headers: {
        'Content-Type': _getContentType(file),
        'Host': uri.host.toLowerCase(),
      },
    );

    final signedRequest = await _getSigner().sign(
      request,
      credentialScope: AWSCredentialScope(
        region: _config.arvanRegion,
        service: AWSService.s3,
      ),
      serviceConfiguration: S3ServiceConfiguration(),
    );

    // Send raw bytes to ensure Dio calculates Content-Length correctly.
    // Streams might trigger Transfer-Encoding: chunked, which breaks S3 SigV4.
    await _dio.putUri<void>(
      uri,
      data: bytes,
      options: Options(
        headers: signedRequest.headers,
      ),
    );
  }

  Future<void> delete(String remoteKey) async {
    final baseUri = Uri.parse(_config.arvanEndpoint);
    final uri = baseUri.replace(
      path: '${baseUri.path}/$remoteKey'.replaceAll('//', '/'),
    );
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.delete,
      uri: uri,
      headers: {
        'Host': uri.host.toLowerCase(),
      },
    );

    final signedRequest = await _getSigner().sign(
      request,
      credentialScope: AWSCredentialScope(
        region: _config.arvanRegion,
        service: AWSService.s3,
      ),
      serviceConfiguration: S3ServiceConfiguration(),
    );

    await _dio.deleteUri<void>(
      uri,
      options: Options(
        headers: signedRequest.headers,
      ),
    );
  }

  Future<S3ListResponse> list({String? continuationToken}) async {
    final baseUri = Uri.parse(_config.arvanEndpoint);
    final queryParameters = <String, String>{
      'list-type': '2',
    };
    if (continuationToken != null) {
      queryParameters['continuation-token'] = continuationToken;
    }
    
    final uri = baseUri.replace(queryParameters: queryParameters);

    final request = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: uri,
      headers: {
        'Host': uri.host.toLowerCase(),
      },
    );

    final signedRequest = await _getSigner().sign(
      request,
      credentialScope: AWSCredentialScope(
        region: _config.arvanRegion,
        service: AWSService.s3,
      ),
      serviceConfiguration: S3ServiceConfiguration(),
    );

    final response = await _dio.getUri<dynamic>(
      uri,
      options: Options(
        headers: signedRequest.headers,
      ),
    );

    final document = XmlDocument.parse(response.data.toString());
    final contents = document.findAllElements('Contents').toList();
    final nextToken = document.findAllElements('NextContinuationToken').firstOrNull?.innerText;

    return S3ListResponse(contents: contents, nextContinuationToken: nextToken);
  }

  String _getContentType(File file) {
    final extension = p.extension(file.path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
