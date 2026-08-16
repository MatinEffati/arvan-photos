import 'package:equatable/equatable.dart';

class PhotoEntity extends Equatable {
  const PhotoEntity({
    required this.key,
    required this.url,
    required this.lastModified,
    required this.size,
    required this.name,
  });

  final String key;
  final String url;
  final DateTime lastModified;
  final int size;
  final String name;

  @override
  List<Object?> get props => [key, url, lastModified, size, name];
}
