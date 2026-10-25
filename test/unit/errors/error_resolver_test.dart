import 'package:aula360/core/enums/backend_enums.dart';
import 'package:aula360/core/errors/app_error_resolver.dart';
import 'package:aula360/core/errors/app_failure.dart';
import 'package:aula360/core/errors/error_handler.dart';
import 'package:aula360/core/errors/failure_mapper.dart';
import 'package:aula360/core/network/api_exception.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorResolver and Decent Failure Messaging Tests', () {
    test(
      'Resolves backend INVALID_CREDENTIALS body into decent message with directory guidance',
      () {
        final backendResponse = {
          'success': false,
          'errorType': 'INVALID_CREDENTIALS',
          'message': 'Invalid Credential,Check Your Email And Password',
          'traceId': 'db20038c-5367-4fd1-936c-d699887baa13',
        };

        final englishMsg = AppErrorResolver.resolve(
          backendResponse,
          languageCode: 'en',
        );

        expect(englishMsg.title, equals('Incorrect Credentials'));
        expect(
          englishMsg.message,
          contains('The email or password entered does not match our records.'),
        );
        expect(englishMsg.directive, contains("Forgot password?"));
        expect(englishMsg.errorType, equals(ApiErrorType.invalidCredentials));
        expect(
          englishMsg.traceId,
          equals('db20038c-5367-4fd1-936c-d699887baa13'),
        );

        // Verify that no raw technical tokens are presented in display message
        expect(englishMsg.displayMessage, isNot(contains('Exception')));
        expect(englishMsg.displayMessage, isNot(contains('traceId')));
        expect(englishMsg.displayMessage, isNot(contains('db20038c')));
      },
    );

    test(
      'Resolves backend INVALID_CREDENTIALS in Spanish when active language is es',
      () {
        final backendResponse = {
          'success': false,
          'errorType': 'INVALID_CREDENTIALS',
          'message': 'Invalid Credential,Check Your Email And Password',
          'traceId': 'db20038c-5367-4fd1-936c-d699887baa13',
        };

        final spanishMsg = AppErrorResolver.resolve(
          backendResponse,
          languageCode: 'es',
        );

        expect(spanishMsg.title, equals('Credenciales incorrectas'));
        expect(
          spanishMsg.message,
          contains(
            'El correo electrónico o la contraseña ingresados no coinciden',
          ),
        );
        expect(spanishMsg.directive, contains('¿Olvidaste tu contraseña?'));
        expect(spanishMsg.errorType, equals(ApiErrorType.invalidCredentials));
      },
    );

    test('Resolves USER_SUSPENDED with administrative guidance', () {
      final backendResponse = {
        'success': false,
        'errorType': 'USER_SUSPENDED',
        'message': 'Account is suspended',
      };

      final msg = AppErrorResolver.resolve(backendResponse, languageCode: 'en');

      expect(msg.title, equals('Account Suspended'));
      expect(msg.errorType, equals(ApiErrorType.userSuspended));
      expect(msg.directive, contains('administration'));
    });

    test('Resolves ACCOUNT_INACTIVE with activation guidance', () {
      final backendResponse = {
        'success': false,
        'errorType': 'ACCOUNT_INACTIVE',
        'message': 'Your account is not active. Please verify your email or contact support.',
      };

      final msg = AppErrorResolver.resolve(backendResponse, languageCode: 'en');

      expect(msg.title, equals('Account Inactive'));
      expect(msg.errorType, equals(ApiErrorType.accountInactive));
      expect(msg.directive, contains('activate'));
    });

    test('Resolves INVALID_OTP with resend guidance', () {
      final backendResponse = {
        'success': false,
        'errorType': 'INVALID_OTP',
        'message': 'Code mismatch',
      };

      final msg = AppErrorResolver.resolve(backendResponse, languageCode: 'en');

      expect(msg.title, equals('Invalid Verification Code'));
      expect(msg.errorType, equals(ApiErrorType.invalidOtp));
      expect(msg.directive, contains('code'));
    });

    test('Resolves DioException badResponse into decent message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {
            'success': false,
            'errorType': 'INVALID_CREDENTIALS',
            'message': 'Invalid Credential,Check Your Email And Password',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final msg = AppErrorResolver.resolve(dioException, languageCode: 'en');

      expect(msg.errorType, equals(ApiErrorType.invalidCredentials));
      expect(msg.title, equals('Incorrect Credentials'));
      expect(msg.directive, isNotNull);
    });

    test('Resolves network timeout into connection guidance message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/classes'),
        type: DioExceptionType.connectionTimeout,
      );

      final msg = AppErrorResolver.resolve(dioException, languageCode: 'en');

      expect(msg.title, equals('Connection Problem'));
      expect(msg.errorType, equals(ApiErrorType.networkError));
      expect(msg.directive, contains('internet connection'));
    });

    test(
      'FailureMapper maps DioException to AuthenticationFailure and integrates with ErrorHandler',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {
              'success': false,
              'errorType': 'INVALID_CREDENTIALS',
              'message': 'Invalid Credential,Check Your Email And Password',
            },
          ),
        );

        final failure = FailureMapper.fromException(dioException);
        expect(failure, isA<AuthenticationFailure>());
        expect(failure.title, equals('Incorrect Credentials'));
        expect(failure.directive, isNotNull);

        final userMessage = ErrorHandler.displayMessage(dioException);
        expect(userMessage, isNotEmpty);
        expect(userMessage, isNot(contains('DioException')));
      },
    );

    test(
      'Sanitizes raw string exception tokens and retains on-point message',
      () {
        final rawString =
            'Exception: Invalid Credential,Check Your Email And Password';
        final msg = AppErrorResolver.resolve(rawString, languageCode: 'en');

        expect(msg.errorType, equals(ApiErrorType.invalidCredentials));
        expect(msg.title, equals('Incorrect Credentials'));
        expect(msg.displayMessage, isNot(contains('Exception:')));
      },
    );

    test('Customizes and translates validation error response in English', () {
      final backendResponse = {
        'success': false,
        'message': 'Request body validation failed',
        'errors': [
          {'field': 'phone', 'message': 'Invalid phone number'},
          {
            'field': 'password',
            'message': 'Password must contain at least one uppercase letter',
          },
          {
            'field': 'password',
            'message': 'Password must contain at least one lowercase letter',
          },
          {
            'field': 'password',
            'message': 'Password must contain at least one special character',
          },
        ],
        'traceId': '04215f08-2d1a-4a76-b26c-d8145b3cbaf6',
      };

      final msg = AppErrorResolver.resolve(backendResponse, languageCode: 'en');

      expect(msg.title, equals('Validation Error'));
      expect(msg.errorType, equals(ApiErrorType.validationError));
      expect(msg.errors, hasLength(4));
      expect(msg.message, contains('• Invalid phone number'));
      expect(
        msg.message,
        contains('• Password must contain at least one uppercase letter'),
      );
      expect(
        msg.message,
        contains('• Password must contain at least one lowercase letter'),
      );
      expect(
        msg.message,
        contains('• Password must contain at least one special character'),
      );
      expect(msg.directive, contains('Please correct the indicated fields'));
    });

    test('Customizes and translates validation error response in Spanish', () {
      final backendResponse = {
        'success': false,
        'message': 'Request body validation failed',
        'errors': [
          {'field': 'phone', 'message': 'Invalid phone number'},
          {
            'field': 'password',
            'message': 'Password must contain at least one uppercase letter',
          },
          {
            'field': 'password',
            'message': 'Password must contain at least one lowercase letter',
          },
          {
            'field': 'password',
            'message': 'Password must contain at least one special character',
          },
        ],
        'traceId': '04215f08-2d1a-4a76-b26c-d8145b3cbaf6',
      };

      final msg = AppErrorResolver.resolve(backendResponse, languageCode: 'es');

      expect(msg.title, equals('Error de validación'));
      expect(msg.errorType, equals(ApiErrorType.validationError));
      expect(msg.errors, hasLength(4));
      expect(msg.message, contains('• Número de teléfono no válido'));
      expect(
        msg.message,
        contains('• La contraseña debe contener al menos una letra mayúscula'),
      );
      expect(
        msg.message,
        contains('• La contraseña debe contener al menos una letra minúscula'),
      );
      expect(
        msg.message,
        contains('• La contraseña debe contener al menos un carácter especial'),
      );
      expect(msg.directive, contains('Por favor corrige los campos señalados'));
    });

    test('Re-translates UserFriendlyMessage when language code changes', () {
      final backendResponse = {
        'success': false,
        'message': 'Request body validation failed',
        'errors': [
          {'field': 'phone', 'message': 'Invalid phone number'},
          {
            'field': 'password',
            'message': 'Password must contain at least one uppercase letter',
          },
        ],
      };

      final englishMsg = AppErrorResolver.resolve(
        backendResponse,
        languageCode: 'en',
      );
      expect(englishMsg.title, equals('Validation Error'));

      final spanishMsg = AppErrorResolver.resolve(
        englishMsg,
        languageCode: 'es',
      );
      expect(spanishMsg.title, equals('Error de validación'));
      expect(spanishMsg.message, contains('Número de teléfono no válido'));
      expect(
        spanishMsg.message,
        contains('La contraseña debe contener al menos una letra mayúscula'),
      );
    });

    test(
      'Resolves backend 500 map without exposing backend technical error in English',
      () {
        final backend500 = {
          'statusCode': 500,
          'message': 'NullPointerException in AuthMicroservice: connection pool exhausted',
          'error': 'Internal Server Error',
          'traceId': 'trace-500-test-id',
        };

        final msg = AppErrorResolver.resolve(backend500, languageCode: 'en');

        expect(msg.title, equals('Service Interruption'));
        expect(
          msg.message,
          equals('The academy servers are currently experiencing technical difficulties.'),
        );
        expect(
          msg.directive,
          equals('Our team is working on it. Please try again in a few moments.'),
        );
        expect(msg.errorType, equals(ApiErrorType.serverError));
        expect(msg.displayMessage, isNot(contains('NullPointerException')));
        expect(msg.displayMessage, isNot(contains('AuthMicroservice')));
        expect(msg.displayMessage, isNot(contains('connection pool')));
      },
    );

    test(
      'Resolves backend 500 map into user-friendly message in Spanish',
      () {
        final backend500 = {
          'statusCode': 500,
          'message': 'Database query failed: syntax error at or near SELECT * FROM users',
          'error': 'Internal Server Error',
        };

        final msg = AppErrorResolver.resolve(backend500, languageCode: 'es');

        expect(msg.title, equals('Servicio no disponible'));
        expect(
          msg.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
        expect(
          msg.directive,
          equals('Nuestro equipo está trabajando en ello. Inténtalo de nuevo en unos minutos.'),
        );
        expect(msg.errorType, equals(ApiErrorType.serverError));
        expect(msg.displayMessage, isNot(contains('Database query')));
        expect(msg.displayMessage, isNot(contains('syntax error')));
        expect(msg.displayMessage, isNot(contains('SELECT')));
      },
    );

    test(
      'Resolves DioException 500 badResponse into user-friendly message translated by selected language',
      () {
        final dio500 = DioException(
          requestOptions: RequestOptions(path: '/api/v1/sessions'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/sessions'),
            statusCode: 500,
            data: {
              'message': 'Failed to execute query: table does not exist',
              'statusCode': 500,
            },
          ),
          type: DioExceptionType.badResponse,
        );

        final englishMsg = AppErrorResolver.resolve(dio500, languageCode: 'en');
        expect(englishMsg.title, equals('Service Interruption'));
        expect(
          englishMsg.message,
          equals('The academy servers are currently experiencing technical difficulties.'),
        );
        expect(englishMsg.displayMessage, isNot(contains('table does not exist')));

        final spanishMsg = AppErrorResolver.resolve(dio500, languageCode: 'es');
        expect(spanishMsg.title, equals('Servicio no disponible'));
        expect(
          spanishMsg.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
        expect(spanishMsg.displayMessage, isNot(contains('table does not exist')));
      },
    );

    test(
      'ApiException with 500 status code masks technical backend error with user-friendly translated text',
      () {
        final apiException = ApiException(
          message: 'Failed to fetch teacher sessions: DioException [bad response] 500',
          statusCode: 500,
          traceId: 'trace-test-uuid',
        );

        LanguageNotifier.activeLanguageCode = 'es';
        expect(
          apiException.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica. Inténtalo de nuevo en unos minutos.'),
        );
        expect(
          apiException.toString(),
          equals('Los servidores de la academia están experimentando una interrupción técnica. Inténtalo de nuevo en unos minutos.'),
        );
        expect(apiException.rawMessage, contains('Failed to fetch teacher sessions'));

        LanguageNotifier.activeLanguageCode = 'en';
        expect(
          apiException.message,
          equals('The academy servers are currently experiencing technical difficulties. Please try again in a few moments.'),
        );
        expect(
          apiException.toString(),
          equals('The academy servers are currently experiencing technical difficulties. Please try again in a few moments.'),
        );

        final resolved = AppErrorResolver.resolve(apiException, languageCode: 'es');
        expect(resolved.title, equals('Servicio no disponible'));
        expect(
          resolved.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
        expect(resolved.displayMessage, isNot(contains('DioException')));
      },
    );

    test(
      'Raw string with 500 or internal server error is resolved to user-friendly message',
      () {
        final rawString = 'ApiException: Failed to fetch child schedule: DioException [bad response] 500';

        final englishMsg = AppErrorResolver.resolve(rawString, languageCode: 'en');
        expect(englishMsg.title, equals('Service Interruption'));
        expect(
          englishMsg.message,
          equals('The academy servers are currently experiencing technical difficulties.'),
        );
        expect(englishMsg.displayMessage, isNot(contains('DioException')));
        expect(englishMsg.displayMessage, isNot(contains('500')));

        final spanishMsg = AppErrorResolver.resolve(rawString, languageCode: 'es');
        expect(spanishMsg.title, equals('Servicio no disponible'));
        expect(
          spanishMsg.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
        expect(spanishMsg.displayMessage, isNot(contains('DioException')));
      },
    );

    test(
      'Re-translates server error UserFriendlyMessage when language code changes',
      () {
        final backend500 = {
          'statusCode': 500,
          'message': 'Internal Server Error',
        };

        final englishMsg = AppErrorResolver.resolve(backend500, languageCode: 'en');
        expect(englishMsg.title, equals('Service Interruption'));

        final retranslatedSpanish = AppErrorResolver.resolve(englishMsg, languageCode: 'es');
        expect(retranslatedSpanish.title, equals('Servicio no disponible'));
        expect(
          retranslatedSpanish.message,
          equals('Los servidores de la academia están experimentando una interrupción técnica.'),
        );
      },
    );
  });
}
