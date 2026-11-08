import 'package:dio/dio.dart';

/// Interceptor that attaches the active locale headers (`x-locale` and `Accept-Language`)
/// to all outgoing HTTP requests, ensuring localized dynamic content from the backend.
class LocaleInterceptor extends Interceptor {
  final String Function() getCurrentLocale;

  LocaleInterceptor({required this.getCurrentLocale});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final currentLocale = getCurrentLocale();
    options.headers['x-locale'] = currentLocale;
    options.headers['Accept-Language'] = '$currentLocale;q=1.0,en;q=0.5';
    super.onRequest(options, handler);
  }
}

