import 'package:xml/xml.dart';

class S3ListResponse {
  S3ListResponse({required this.contents, this.nextContinuationToken});
  final List<XmlElement> contents;
  final String? nextContinuationToken;
}
