import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class CoreModule {
  @lazySingleton
  Dio get dio {
    final dio = Dio();
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('DIO_LOG: $object'),
      ),
    );
    return dio;
  }
}
