import 'package:arvan_photos/features/photos/domain/entities/upload_cancel_token.dart';
import 'package:dio/dio.dart';

class DioUploadCancelToken implements UploadCancelToken {
  final CancelToken _cancelToken = CancelToken();

  @override
  void cancel([String? reason]) {
    _cancelToken.cancel(reason);
  }

  @override
  bool get isCancelled => _cancelToken.isCancelled;

  CancelToken get dioToken => _cancelToken;
}
