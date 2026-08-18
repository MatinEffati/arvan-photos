import 'package:arvan_photos/features/cloud/domain/entities/cloud_photo.dart';
import 'package:equatable/equatable.dart';

abstract class CloudState extends Equatable {
  const CloudState();

  @override
  List<Object?> get props => [];
}

class CloudInitial extends CloudState {}

class CloudLoadInProgress extends CloudState {}

class CloudLoadSuccess extends CloudState {
  const CloudLoadSuccess(this.photos);
  final List<CloudPhoto> photos;

  @override
  List<Object> get props => [photos];
}

class CloudLoadFailure extends CloudState {
  const CloudLoadFailure(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

class CloudDeleteInProgress extends CloudState {}

class CloudDeleteSuccess extends CloudState {}
