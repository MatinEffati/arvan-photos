import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:xml/xml.dart';

class CloudPhotoModel extends CloudPhoto {
  const CloudPhotoModel({
    required super.key,
    required super.url,
    required super.lastModified,
    required super.size,
    required super.name,
  });

  factory CloudPhotoModel.fromXmlElement(XmlElement element, String baseUrl) {
    final key = element.findElements('Key').first.innerText;
    final lastModifiedStr = element.findElements('LastModified').first.innerText;
    final sizeStr = element.findElements('Size').first.innerText;

    return CloudPhotoModel(
      key: key,
      url: '$baseUrl/$key',
      lastModified: DateTime.parse(lastModifiedStr),
      size: int.parse(sizeStr),
      name: key.split('/').last,
    );
  }
}
