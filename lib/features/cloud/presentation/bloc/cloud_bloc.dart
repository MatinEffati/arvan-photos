import 'package:arvan_photos/features/cloud/domain/usecases/get_cloud_photos.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_event.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class CloudBloc extends Bloc<CloudEvent, CloudState> {
  CloudBloc(this._getCloudPhotos) : super(CloudInitial()) {
    on<CloudPhotosRequested>(_onPhotosRequested);
  }

  final GetCloudPhotos _getCloudPhotos;

  Future<void> _onPhotosRequested(
    CloudPhotosRequested event,
    Emitter<CloudState> emit,
  ) async {
    emit(CloudLoadInProgress());
    try {
      final photos = await _getCloudPhotos();
      emit(CloudLoadSuccess(photos));
    } catch (e) {
      emit(CloudLoadFailure(e.toString()));
    }
  }
}
