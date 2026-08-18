import 'package:equatable/equatable.dart';

abstract class CloudEvent extends Equatable {
  const CloudEvent();

  @override
  List<Object> get props => [];
}

class CloudPhotosRequested extends CloudEvent {
  const CloudPhotosRequested({this.isRefresh = false});
  final bool isRefresh;

  @override
  List<Object> get props => [isRefresh];
}

class CloudLoadMoreRequested extends CloudEvent {}

class CloudPhotoDeleteRequested extends CloudEvent {
  const CloudPhotoDeleteRequested(this.key);
  final String key;

  @override
  List<Object> get props => [key];
}
