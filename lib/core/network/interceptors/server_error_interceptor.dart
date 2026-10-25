import 'package:dio/dio.dart';

import '../../errors/app_error_resolver.dart';
import '../../service/language/language_provider.dart';

/// Intercepts any 5xx HTTP response or server-side failure
/// and replaces technical backend errors with a localized, user-friendly message.
class ServerErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? 0;
    if (status >= 500) {
      final lang = LanguageNotifier.activeLanguageCode;
      final resolved = AppErrorResolver.resolve(err, languageCode: lang);

      final sanitizedError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: resolved,
        message: resolved.displayMessage,
      );
      return handler.next(sanitizedError);
    }
    handler.next(err);
  }
}
