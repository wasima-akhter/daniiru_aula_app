import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../../../utils/enum/app_enum.dart';

class AppStorage {
  AppStorage({required this.preferences, required this.secureStorage});

  final SharedPreferencesAsync preferences;
  final FlutterSecureStorage secureStorage;

  // ============================================================
  // Keys
  // ============================================================

  static const String seenOnboardingKey = 'seen_onboarding';
  static const String isLoggedInKey = 'is_logged_in';
  static const String rememberMeKey = 'remember_me';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  static const String authIdKey = 'auth_id';
  static const String userIdKey = 'user_id';
  static const String emailKey = 'email';

  static const String roleKey = 'role';

  static const String profileKey = 'profile';

  static const String languageKey = 'language';
  static const String languageCountryKey = 'language_country';

  static const String themeKey = 'theme';

  static const String rememberedEmailKey = 'remembered_email';

  static const String pendingEmailKey = 'pending_email';
  static const String pendingRoleKey = 'pending_role';

  static const String tokenExpiryKey = 'token_expiry';
  static const String refreshTokenExpiryKey = 'refresh_token_expiry';

  static const String profileCompletedKey = 'profile_completed';

  static const String selectedRoleKey = 'selected_role';

  // ============================================================
  // Onboarding
  // ============================================================

  Future<bool> get hasSeenOnboarding async {
    return await preferences.getBool(seenOnboardingKey) ?? false;
  }

  Future<void> setSeenOnboarding(bool value) async {
    await preferences.setBool(seenOnboardingKey, value);
  }

  // ============================================================
  // Login
  // ============================================================

  Future<bool> get isLoggedIn async {
    return await preferences.getBool(isLoggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await preferences.setBool(isLoggedInKey, value);
  }

  // ============================================================
  // Remember Me
  // ============================================================

  Future<bool> get rememberMe async {
    return await preferences.getBool(rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    await preferences.setBool(rememberMeKey, value);
  }

  // ============================================================
  // Access Token
  // ============================================================

  Future<String> get accessToken async {
    return await secureStorage.read(key: accessTokenKey) ?? '';
  }

  Future<void> setAccessToken(String token) async {
    await secureStorage.write(key: accessTokenKey, value: token);
  }

  Future<void> removeAccessToken() async {
    await secureStorage.delete(key: accessTokenKey);
  }

  // ============================================================
  // Refresh Token
  // ============================================================

  Future<String> get refreshToken async {
    return await secureStorage.read(key: refreshTokenKey) ?? '';
  }

  Future<void> setRefreshToken(String token) async {
    await secureStorage.write(key: refreshTokenKey, value: token);
  }

  Future<void> removeRefreshToken() async {
    await secureStorage.delete(key: refreshTokenKey);
  }

  // ============================================================
  // Role
  // ============================================================

  Future<UserRole?> get role async {
    final value = await preferences.getString(roleKey);

    if (value == null) {
      return null;
    }

    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.values.first,
    );
  }

  Future<void> setRole(UserRole role) async {
    await preferences.setString(roleKey, role.name);
  }

  Future<void> clearRole() async {
    await preferences.remove(roleKey);
  }

  // ============================================================
  // Selected Role
  // ============================================================

  Future<UserRole?> get selectedRole async {
    final value = await preferences.getString(selectedRoleKey);

    if (value == null) {
      return null;
    }

    return UserRole.values.cast<UserRole?>().firstWhere(
      (e) => e?.name == value,
      orElse: () => null,
    );
  }

  Future<void> setSelectedRole(UserRole role) async {
    await preferences.setString(selectedRoleKey, role.name);
  }

  Future<void> clearSelectedRole() async {
    await preferences.remove(selectedRoleKey);
  }

  // ============================================================
  // Pending Registration
  // ============================================================

  Future<String> get pendingEmail async {
    return await preferences.getString(pendingEmailKey) ?? '';
  }

  Future<void> setPendingEmail(String email) async {
    await preferences.setString(pendingEmailKey, email);
  }

  Future<String> get pendingRole async {
    return await preferences.getString(pendingRoleKey) ?? '';
  }

  Future<void> setPendingRole(String role) async {
    await preferences.setString(pendingRoleKey, role);
  }

  Future<void> clearPendingRegister() async {
    await Future.wait([
      preferences.remove(pendingEmailKey),
      preferences.remove(pendingRoleKey),
    ]);
  }

  // ============================================================
  // Profile
  // ============================================================

  Future<Map<String, dynamic>?> get profile async {
    final value = await preferences.getString(profileKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setProfile(Map<String, dynamic> profile) async {
    await preferences.setString(profileKey, jsonEncode(profile));
  }

  Future<void> clearProfile() async {
    await preferences.remove(profileKey);
  }

  Future<bool> get hasCompletedProfile async {
    return await preferences.getBool(profileCompletedKey) ?? false;
  }

  Future<void> setProfileCompleted(bool value) async {
    await preferences.setBool(profileCompletedKey, value);
  }

  // ============================================================
  // Language
  // ============================================================

  Future<String> get languageCode async {
    return await preferences.getString(languageKey) ?? '';
  }

  Future<String> get languageCountry async {
    return await preferences.getString(languageCountryKey) ?? '';
  }

  Future<bool> get hasSelectedLanguage async {
    final code = await languageCode;
    return code.isNotEmpty;
  }

  Future<void> setLanguage({
    required String languageCode,
    String? countryCode,
  }) async {
    await preferences.setString(languageKey, languageCode);

    if (countryCode != null) {
      await preferences.setString(languageCountryKey, countryCode);
    } else {
      await preferences.remove(languageCountryKey);
    }
  }

  Future<void> clearLanguage() async {
    await Future.wait([
      preferences.remove(languageKey),
      preferences.remove(languageCountryKey),
    ]);
  }

  // ============================================================
  // Theme
  // ============================================================

  Future<String> get theme async {
    return await preferences.getString(themeKey) ?? 'system';
  }

  Future<void> setTheme(String value) async {
    await preferences.setString(themeKey, value);
  }

  // ============================================================
  // Remembered Email
  // ============================================================

  Future<String> get rememberedEmail async {
    return await preferences.getString(rememberedEmailKey) ?? '';
  }

  Future<void> setRememberedEmail(String value) async {
    await preferences.setString(rememberedEmailKey, value);
  }

  Future<void> clearRememberedEmail() async {
    await preferences.remove(rememberedEmailKey);
  }

  // ============================================================
  // Auth ID
  // ============================================================

  Future<String> get authId async {
    return await preferences.getString(authIdKey) ?? '';
  }

  Future<void> setAuthId(String value) async {
    await preferences.setString(authIdKey, value);
  }

  // ============================================================
  // User ID
  // ============================================================

  Future<String> get userId async {
    return await preferences.getString(userIdKey) ?? '';
  }

  Future<void> setUserId(String value) async {
    await preferences.setString(userIdKey, value);
  }

  // ============================================================
  // Email
  // ============================================================

  Future<String> get email async {
    return await preferences.getString(emailKey) ?? '';
  }

  Future<void> setEmail(String value) async {
    await preferences.setString(emailKey, value);
  }

  // ============================================================
  // Token Expiry
  // ============================================================

  Future<int> get tokenExpiry async {
    return await preferences.getInt(tokenExpiryKey) ?? 0;
  }

  Future<void> setTokenExpiry(int value) async {
    await preferences.setInt(tokenExpiryKey, value);
  }

  // ============================================================
  // Refresh Token Expiry
  // ============================================================

  Future<int> get refreshTokenExpiry async {
    return await preferences.getInt(refreshTokenExpiryKey) ?? 0;
  }

  Future<void> setRefreshTokenExpiry(int value) async {
    await preferences.setInt(refreshTokenExpiryKey, value);
  }

  // ============================================================
  // Save Session
  // ============================================================

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? authId,
    String? userId,
    String? email,
    UserRole? role,
    int? tokenExpiry,
    int? refreshTokenExpiry,
  }) async {
    await setLoggedIn(true);

    await setAccessToken(accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await setRefreshToken(refreshToken);
    }

    if (authId != null && authId.isNotEmpty) {
      await setAuthId(authId);
    }

    if (userId != null && userId.isNotEmpty) {
      await setUserId(userId);
    }

    if (email != null && email.isNotEmpty) {
      await setEmail(email);
    }

    if (role != null) {
      await setRole(role);
    }

    if (tokenExpiry != null) {
      await setTokenExpiry(tokenExpiry);
    }

    if (refreshTokenExpiry != null) {
      await setRefreshTokenExpiry(refreshTokenExpiry);
    }
  }

  // ============================================================
  // Logout
  // ============================================================

  Future<void> logout() async {
    // Secure data
    await secureStorage.delete(key: accessTokenKey);

    await secureStorage.delete(key: refreshTokenKey);

    // Authentication data
    await Future.wait([
      preferences.remove(tokenExpiryKey),
      preferences.remove(refreshTokenExpiryKey),
      preferences.remove(authIdKey),
      preferences.remove(userIdKey),
      preferences.remove(emailKey),
      preferences.remove(profileKey),
      preferences.remove(roleKey),
      preferences.remove(isLoggedInKey),
    ]);

    // Intentionally kept:
    //
    // seenOnboarding
    // rememberMe
    // language
    // theme
    // rememberedEmail
    // selectedRole
    // pending registration data
  }

  // ============================================================
  // Clear Authentication
  // ============================================================

  Future<void> clearAuth() async {
    await secureStorage.delete(key: accessTokenKey);

    await secureStorage.delete(key: refreshTokenKey);

    await Future.wait([
      preferences.remove(tokenExpiryKey),
      preferences.remove(refreshTokenExpiryKey),
      preferences.remove(authIdKey),
      preferences.remove(userIdKey),
      preferences.remove(emailKey),
      preferences.remove(profileKey),
      preferences.remove(roleKey),
      preferences.remove(isLoggedInKey),
    ]);
  }
}
