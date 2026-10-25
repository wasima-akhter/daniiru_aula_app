import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aula360/core/network/interceptors/server_error_interceptor.dart';
import 'package:aula360/core/errors/app_error_resolver.dart';
import 'package:aula360/core/service/language/language_provider.dart';

class Mock500Adapter implements HttpClientAdapter {
  final int statusCode;
  final String responseBody;

  Mock500Adapter({
    this.statusCode = 500,
    this.responseBody = '{"statusCode": 500, "message": "Raw internal database deadlock error"}',
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ServerErrorInterceptor Tests', () {
    late Dio dio;
    late ServerErrorInterceptor interceptor;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://alua.localbox.online'));
      interceptor = ServerErrorInterceptor();
      dio.interceptors.add(interceptor);
    });

    test('intercepts 500 response and produces user-friendly error message in English', () async {
      dio.httpClientAdapter = Mock500Adapter();
      LanguageNotifier.activeLanguageCode = 'en';

      try {
        await dio.get('/api/v1/test-endpoint');
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(500));
        expect(
          e.message,
          equals('The academy servers are currently experiencing technical difficulties.'),
        );
        expect(e.error, isA<UserFriendlyMessage>());
        final userMsg = e.error as UserFriendlyMessage;
        expect(userMsg.title, equals('Service Interruption'));
        expect(userMsg.displayMessage, isNot(contains('deadlock')));
      }
    });

    test('intercepts 500 response and produces user-friendly error message in Spanish', () async {
      dio.httpClientAdapter = Mock500Adapter();
      LanguageNotifier.activeLanguageCode = 'es';

      try {
        await dio.get('/api/v1/test-endpoint');
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(500));
        expect(
          e.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
        expect(e.error, isA<UserFriendlyMessage>());
        final userMsg = e.error as UserFriendlyMessage;
        expect(userMsg.title, equals('Servicio no disponible'));
        expect(userMsg.displayMessage, isNot(contains('deadlock')));
      }
    });
  });
}
