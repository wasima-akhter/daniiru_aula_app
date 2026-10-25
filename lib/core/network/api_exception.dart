import '../service/language/language_provider.dart';

class ApiException implements Exception {
  final String rawMessage;
  final int statusCode;
  final dynamic data;
  final String? errorType;
  final String? traceId;

  ApiException({
    required String message,
    required this.statusCode,
    this.data,
    this.errorType,
    this.traceId,
  }) : rawMessage = message;

  /// Returns a user-friendly message when statusCode >= 500,
  /// otherwise returns the regular message.
  String get message {
    if (statusCode >= 500) {
      return localizedMessage();
    }
    return rawMessage;
  }

  /// Returns localized user-friendly message for server errors.
  String localizedMessage([String? languageCode]) {
    return getFriendlyServerError(languageCode);
  }

  /// Static helper for localized 500 message in active or provided language.
  static String getFriendlyServerError([String? languageCode]) {
    final effective = languageCode ?? LanguageNotifier.activeLanguageCode;
    final isSpanish = effective.toLowerCase().startsWith('es');
    return isSpanish
        ? 'Los servidores de la academia están experimentando una interrupción técnica. Inténtalo de nuevo en unos minutos.'
        : 'The academy servers are currently experiencing technical difficulties. Please try again in a few moments.';
  }

  @override
  String toString() => message;
}
