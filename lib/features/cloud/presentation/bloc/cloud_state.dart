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
  const CloudLoadSuccess({
    required this.photos,
    this.hasReachedMax = false,
    this.nextContinuationToken,
    this.errorMessage,
  });

  final List<CloudPhoto> photos;
  final bool hasReachedMax;
  final String? nextContinuationToken;
  final String? errorMessage;

  @override
  List<Object?> get props => [photos, hasReachedMax, nextContinuationToken, errorMessage];

  CloudLoadSuccess copyWith({
    List<CloudPhoto>? photos,
    bool? hasReachedMax,
    String? nextContinuationToken,
    String? errorMessage,
  }) {
    return CloudLoadSuccess(
      photos: photos ?? this.photos,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      nextContinuationToken: nextContinuationToken ?? this.nextContinuationToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CloudLoadFailure extends CloudState {
  const CloudLoadFailure(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

class CloudDeleteInProgress extends CloudState {}

class CloudDeleteSuccess extends CloudState {}
