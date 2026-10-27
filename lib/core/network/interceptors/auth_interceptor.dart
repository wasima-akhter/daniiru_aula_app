import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../session/session_manager.dart';
import '../../storage/storage_service.dart';
import '../../utils/jwt_helper.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storageService, this.sessionManager});

  final StorageService storageService;
  final SessionManager? sessionManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If authorization header is already explicitly set by caller, proceed
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    // OTP Token endpoints
    if (options.path.contains(ApiConstants.verify) ||
        options.path.contains(ApiConstants.resend)) {
      final otpToken = await storageService.getOtpPageToken();
      if (otpToken != null && otpToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $otpToken';
      } else {
        final accessToken = await storageService.getAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      handler.next(options);
      return;
    }

    // Password Recovery endpoints (resend, verify, reset)
    if (options.path.contains(ApiConstants.recoverResend) ||
        options.path.contains(ApiConstants.recoverVerify) ||
        options.path.contains(ApiConstants.recoverReset)) {
      final resetToken = await storageService.getPasswordResetToken();
      if (resetToken != null && resetToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $resetToken';
      }
      handler.next(options);
      return;
    }

    // Public endpoints that don't need authentication
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Authenticated endpoints require Access Token
    final accessToken = await storageService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      // Proactive session validation: check if the access token has already expired client-side
      if (JwtHelper.isExpired(accessToken)) {
        if (sessionManager != null) {
          await sessionManager!.handleSessionExpired();
        }
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {
                'success': false,
                'errorType': 'TOKEN_EXPIRED',
                'message': 'Session has expired',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }

      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    final errorType = err.response?.data is Map
        ? err.response!.data['errorType']?.toString()
        : null;

    // Check if error represents an expired or invalidated session (401 Unauthorized)
    // Note: INVALID_OTP is simply a wrong code entry, never a session expiry.
    final isAuthError = (statusCode == 401 && errorType != 'INVALID_OTP') ||
        (errorType == 'TOKEN_EXPIRED' ||
            errorType == 'UNAUTHORIZED' ||
            errorType == 'TOKEN_BLACKLISTED' ||
            errorType == 'SESSION_EXPIRED');

    // Trigger session expiry only for authenticated routes (not login, signup, recovery, otp verify/resend, etc.)
    if (isAuthError && !_isExcludedFromSessionExpiry(path)) {
      if (sessionManager != null) {
        await sessionManager!.handleSessionExpired();
      }
    }

    handler.next(err);
  }

  bool _isPublicEndpoint(String path) {
    if (path.contains('/legal/')) return true;
    const publicEndpoints = <String>{
      ApiConstants.signup,
      ApiConstants.login,
      ApiConstants.forgotPassword,
      ApiConstants.resetPassword,
      ApiConstants.recoverFind,
      ApiConstants.legal,
    };

    return publicEndpoints.any((endpoint) => path.endsWith(endpoint));
  }

  bool _isExcludedFromSessionExpiry(String path) {
    if (path.contains('/legal/')) return true;
    const excluded = <String>{
      ApiConstants.signup,
      ApiConstants.verify,
      ApiConstants.resend,
      ApiConstants.login,
      ApiConstants.check,
      ApiConstants.logout,
      ApiConstants.forgotPassword,
      ApiConstants.resetPassword,
      ApiConstants.recoverFind,
      ApiConstants.recoverResend,
      ApiConstants.recoverVerify,
      ApiConstants.recoverReset,
      ApiConstants.legal,
    };

    return excluded.any((endpoint) => path.endsWith(endpoint));
  }
}
