import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/jwt_helper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  AuthUser? _currentUser;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  }) {
    _loadCachedUser();
  }

  void _loadCachedUser() {
    final cached = storageService.getCurrentUserJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(map);
      } catch (_) {}
    }
  }

  @override
  AuthUser? getCurrentUser() => _currentUser;

  @override
  Future<String> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final request = SignupRequestDto(
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      password: password,
      isLegalTermAccepted: true,
    );

    final otpPageToken = await remoteDataSource.signup(request);
    await storageService.saveOtpPageToken(otpPageToken);
    await storageService.saveUserRole(role.isTeacher ? 'TEACHER' : 'PARENT');
    await storageService.saveUserEmail(email);
    return otpPageToken;
  }

  @override
  Future<AuthSession> verifyOtp({
    required String otp,
    required String deviceIdentifier,
    String? fcmToken,
    String? otpPageToken,
  }) async {
    final token = (otpPageToken != null && otpPageToken.isNotEmpty)
        ? otpPageToken
        : await storageService.getOtpPageToken();
    final request = VerifyOtpRequestDto(
      otp: otp,
      deviceIdentifier: deviceIdentifier,
      fcmToken: fcmToken,
    );

    var session = await remoteDataSource.verifyOtp(
      request: request,
      otpPageToken: token,
    );

    // Decode email from accessToken if user.email is empty
    final emailFromToken = JwtHelper.extractEmail(session.accessToken);
    final storedEmail = storageService.getUserEmail();
    final effectiveEmail = (emailFromToken != null && emailFromToken.isNotEmpty)
        ? emailFromToken
        : (session.user.email.isNotEmpty ? session.user.email : storedEmail);

    if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
      session = session.copyWith(
        user: session.user.copyWith(email: effectiveEmail),
      );
      await storageService.saveUserEmail(effectiveEmail);
    }

    await storageService.saveAccessToken(session.accessToken);
    await storageService.saveCurrentUserJson(jsonEncode(session.user.toJson()));
    await storageService.saveUserRole(
      session.user.role.isTeacher ? 'TEACHER' : 'PARENT',
    );
    await storageService.clearOtpPageToken();

    _currentUser = session.user;
    return session;
  }

  @override
  Future<void> resendOtp({String? email, String? otpPageToken}) async {
    final token = (otpPageToken != null && otpPageToken.isNotEmpty)
        ? otpPageToken
        : await storageService.getOtpPageToken();
    final newToken = await remoteDataSource.resendOtp(
      otpPageToken: token,
      email: email,
    );
    if (newToken != null && newToken.isNotEmpty) {
      await storageService.saveOtpPageToken(newToken);
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required UserRole role,
    required String deviceIdentifier,
    bool rememberMe = false,
    String? fcmToken,
  }) async {
    final request = LoginRequestDto(
      email: email,
      password: password,
      role: role,
      deviceIdentifier: deviceIdentifier,
      rememberMe: rememberMe,
      fcmToken: fcmToken,
    );

    var session = await remoteDataSource.login(request);

    // Decode email from accessToken if user.email is empty
    final emailFromToken = JwtHelper.extractEmail(session.accessToken);
    final effectiveEmail = (emailFromToken != null && emailFromToken.isNotEmpty)
        ? emailFromToken
        : (session.user.email.isNotEmpty ? session.user.email : email);

    session = session.copyWith(
      user: session.user.copyWith(email: effectiveEmail),
    );
    await storageService.saveUserEmail(effectiveEmail);

    await storageService.saveAccessToken(session.accessToken);
    await storageService.saveCurrentUserJson(jsonEncode(session.user.toJson()));
    await storageService.saveUserRole(
      session.user.role.isTeacher ? 'TEACHER' : 'PARENT',
    );
    await storageService.setRememberMe(rememberMe);

    if (session.user.isInactive && session.accessToken.isNotEmpty) {
      await storageService.saveOtpPageToken(session.accessToken);
    }

    if (rememberMe) {
      await storageService.setRememberedEmail(effectiveEmail);
    }

    _currentUser = session.user;
    return session;
  }

  @override
  Future<AuthUser?> checkSession({String? fcmToken}) async {
    final isValid = await storageService.hasValidAccessToken();
    if (!isValid) {
      final hasToken = await storageService.hasAccessToken();
      if (hasToken) {
        await storageService.clearAuthentication();
      }
      _currentUser = null;
      return null;
    }

    // Decode email from the existing access token
    final token = await storageService.getAccessToken();
    final emailFromToken = JwtHelper.extractEmail(token);
    if (emailFromToken != null && emailFromToken.isNotEmpty) {
      await storageService.saveUserEmail(emailFromToken);
    }

    try {
      var user = await remoteDataSource.checkSession(
        request: CheckSessionRequestDto(fcmToken: fcmToken),
      );

      // Populate email from token or local storage if check response omitted email
      final storedEmail = storageService.getUserEmail();
      final effectiveEmail = user.email.isNotEmpty
          ? user.email
          : ((emailFromToken != null && emailFromToken.isNotEmpty)
                ? emailFromToken
                : (storedEmail ?? ''));

      if (effectiveEmail.isNotEmpty) {
        user = user.copyWith(email: effectiveEmail);
        await storageService.saveUserEmail(effectiveEmail);
      }

      await storageService.saveCurrentUserJson(jsonEncode(user.toJson()));
      await storageService.saveUserRole(
        user.role.isTeacher ? 'TEACHER' : 'PARENT',
      );
      _currentUser = user;
      return user;
    } catch (e) {
      // If error indicates unauthorized / invalid session, clear it
      final isAuthError =
          (e is ApiException &&
              (e.statusCode == 401 ||
                  e.statusCode == 403 ||
                  e.errorType == 'TOKEN_EXPIRED' ||
                  e.errorType == 'TOKEN_BLACKLISTED' ||
                  e.errorType == 'UNAUTHORIZED' ||
                  e.errorType == 'NEW_LOGIN_SUPERSEDED')) ||
          (e is DioException &&
              (e.response?.statusCode == 401 || e.response?.statusCode == 403));

      final errStr = e.toString().toLowerCase();
      if (isAuthError ||
          errStr.contains('401') ||
          errStr.contains('403') ||
          errStr.contains('unauthorized') ||
          errStr.contains('jwt') ||
          errStr.contains('token_expired') ||
          errStr.contains('session_expired')) {
        await storageService.clearAuthentication();
        _currentUser = null;
        return null;
      }

      // Offline startup support: if network is down but we have a valid cached session, restore it
      if (_currentUser != null) {
        return _currentUser;
      }
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await storageService.logout();
    _currentUser = null;
  }

  @override
  Future<AuthUser> setupParentProfile(ParentProfileSetupDto dto) async {
    final updatedUser = await remoteDataSource.setupParentProfile(dto);
    await storageService.saveCurrentUserJson(jsonEncode(updatedUser.toJson()));
    _currentUser = updatedUser;
    return updatedUser;
  }

  @override
  Future<AuthUser> setupTeacherProfile(TeacherProfileSetupDto dto) async {
    final updatedUser = await remoteDataSource.setupTeacherProfile(dto);
    await storageService.saveCurrentUserJson(jsonEncode(updatedUser.toJson()));
    _currentUser = updatedUser;
    return updatedUser;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await findUserForRecovery(email: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await resetPasswordWithRecoveryToken(
      password: newPassword,
      confirmPassword: newPassword,
    );
  }

  @override
  Future<RecoverUserData> findUserForRecovery({required String email}) async {
    final userData = await remoteDataSource.findUserForRecovery(email);
    if (userData.token.isNotEmpty) {
      await storageService.savePasswordResetToken(userData.token);
    }
    return userData;
  }

  @override
  Future<String> resendRecoveryOtp({String? recoveryToken}) async {
    final token = recoveryToken ?? await storageService.getPasswordResetToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Recovery session expired, please request OTP again',
        statusCode: 401,
        errorType: 'TOKEN_EXPIRED',
      );
    }
    return remoteDataSource.resendRecoveryOtp(recoveryToken: token);
  }

  @override
  Future<bool> verifyRecoveryOtp({
    required String otp,
    String? recoveryToken,
  }) async {
    final token = recoveryToken ?? await storageService.getPasswordResetToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Recovery session expired, please request OTP again',
        statusCode: 401,
        errorType: 'TOKEN_EXPIRED',
      );
    }
    return remoteDataSource.verifyRecoveryOtp(otp: otp, recoveryToken: token);
  }

  @override
  Future<void> resetPasswordWithRecoveryToken({
    required String password,
    required String confirmPassword,
    String? recoveryToken,
  }) async {
    final token = recoveryToken ?? await storageService.getPasswordResetToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Recovery session expired, please request OTP again',
        statusCode: 401,
        errorType: 'TOKEN_EXPIRED',
      );
    }
    await remoteDataSource.resetPasswordWithRecoveryToken(
      password: password,
      confirmPassword: confirmPassword,
      recoveryToken: token,
    );
    await storageService.clearPasswordResetToken();
  }
}
