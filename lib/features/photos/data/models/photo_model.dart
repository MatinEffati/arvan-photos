import 'package:arvan_photos/features/photos/domain/entities/photo_entity.dart';
import 'package:xml/xml.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.key,
    required super.url,
    required super.lastModified,
    required super.size,
    required super.name,
  });

  factory PhotoModel.fromXmlElement(XmlElement element, String baseUrl) {
    final key = element.findElements('Key').first.innerText;
    final lastModifiedStr = element.findElements('LastModified').first.innerText;
    final sizeStr = element.findElements('Size').first.innerText;

    return PhotoModel(
      key: key,
      url: '$baseUrl/$key',
      lastModified: DateTime.parse(lastModifiedStr),
      size: int.parse(sizeStr),
      name: key.split('/').last,
    );
  }

  PhotoModel copyWithUrl(String newUrl) {
    return PhotoModel(
      key: key,
      url: newUrl,
      lastModified: lastModified,
      size: size,
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'url': url,
      'lastModified': lastModified.toIso8601String(),
      'size': size,
      'name': name,
    };
  }
}
