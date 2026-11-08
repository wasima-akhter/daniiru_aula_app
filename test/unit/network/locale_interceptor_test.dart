import 'package:aula360/core/network/interceptors/locale_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleInterceptor', () {
    test('attaches correct x-locale and Accept-Language headers for English', () async {
      String activeLocale = 'en';
      final interceptor = LocaleInterceptor(getCurrentLocale: () => activeLocale);

      final options = RequestOptions(path: '/api/v1/parent/announcements');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['x-locale'], equals('en'));
      expect(options.headers['Accept-Language'], equals('en;q=1.0,en;q=0.5'));
    });

    test('attaches correct x-locale and Accept-Language headers for Spanish', () async {
      String activeLocale = 'es';
      final interceptor = LocaleInterceptor(getCurrentLocale: () => activeLocale);

      final options = RequestOptions(path: '/api/v1/parent/announcements');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['x-locale'], equals('es'));
      expect(options.headers['Accept-Language'], equals('es;q=1.0,en;q=0.5'));
    });

    test('dynamically updates outgoing request headers when locale changes', () async {
      String activeLocale = 'en';
      final interceptor = LocaleInterceptor(getCurrentLocale: () => activeLocale);

      final options1 = RequestOptions(path: '/api/v1/teacher/homework');
      interceptor.onRequest(options1, RequestInterceptorHandler());
      expect(options1.headers['x-locale'], equals('en'));

      // Switch language to Spanish
      activeLocale = 'es';

      final options2 = RequestOptions(path: '/api/v1/teacher/homework');
      interceptor.onRequest(options2, RequestInterceptorHandler());
      expect(options2.headers['x-locale'], equals('es'));
      expect(options2.headers['Accept-Language'], equals('es;q=1.0,en;q=0.5'));
    });
  });
}

