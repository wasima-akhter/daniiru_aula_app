import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:aula360/core/storage/storage_service.dart';

enum BiometricCapability { available, notSupported, notEnrolled, unknown }

class BiometricService {
  final LocalAuthentication _localAuth;
  final StorageService storageService;

  BiometricService({
    LocalAuthentication? localAuth,
    required this.storageService,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  /// Checks whether biometric hardware is present and ready.
  Future<BiometricCapability> checkCapability() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported && !canCheck) return BiometricCapability.notSupported;

      final enrolled = await _localAuth.getAvailableBiometrics();
      if (Platform.isIOS) {
        // On iOS, getAvailableBiometrics() may be empty until user grants Face ID
        // permission through the first authenticate() challenge, but canCheckBiometrics
        // or isDeviceSupported indicates hardware readiness.
        if (canCheck || isSupported) return BiometricCapability.available;
      }

      if (enrolled.isEmpty && !canCheck) {
        return BiometricCapability.notEnrolled;
      }

      return BiometricCapability.available;
    } on LocalAuthException catch (e) {
      debugPrint(
        '[BiometricService] checkCapability LocalAuthException: ${e.code} - ${e.description}',
      );
      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        return BiometricCapability.notSupported;
      }
      if (e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        return BiometricCapability.notEnrolled;
      }
      return BiometricCapability.notSupported;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] checkCapability PlatformException: $e');
      return BiometricCapability.notSupported;
    } catch (e) {
      debugPrint('[BiometricService] checkCapability unexpected error: $e');
      return BiometricCapability.unknown;
    }
  }

  /// Returns whether device supports biometric hardware.
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Returns the available enrolled biometrics (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Returns a human-friendly name for the device's primary biometric sensor.
  Future<String> getBiometricTypeLabel({String languageCode = 'en'}) async {
    final isSpanish = languageCode.toLowerCase().startsWith('es');
    try {
      final types = await getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        return Platform.isIOS
            ? 'Face ID'
            : (isSpanish ? 'Reconocimiento Facial' : 'Face Recognition');
      }
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong)) {
        return Platform.isIOS
            ? 'Touch ID'
            : (isSpanish ? 'Huella Digital' : 'Fingerprint');
      }
      if (Platform.isIOS) {
        return 'Face ID';
      }
    } catch (_) {}
    return isSpanish ? 'Acceso Biométrico' : 'Biometric Access';
  }

  /// Checks if the user has opted-in to biometric login.
  bool get isBiometricEnabled => storageService.isBiometricEnabled;

  /// Authenticates using the native platform biometric prompt (BiometricPrompt / LAContext).
  /// Strictly communicates via the OS pass/fail signal. Raw biometric data never touches the app.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        debugPrint(
          '[BiometricService] Authentication skipped, device not supported',
        );
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );

      debugPrint('[BiometricService] OS biometric result: $didAuthenticate');
      return didAuthenticate;
    } on LocalAuthException catch (e) {
      debugPrint(
        '[BiometricService] LocalAuthException: ${e.code} - ${e.description}',
      );
      return false;
    } on PlatformException catch (e) {
      debugPrint(
        '[BiometricService] PlatformException: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return false;
    }
  }

  /// Toggles biometric quick-access ON inside settings:
  /// Forces a verification step once to prove ownership, then links the session token into secure storage.
  Future<bool> enableBiometrics({
    required String sessionToken,
    required String verificationReason,
  }) async {
    final supported = await isDeviceSupported();
    if (!supported) {
      return false;
    }

    final success = await authenticate(
      localizedReason: verificationReason,
      biometricOnly: true,
    );

    if (success) {
      await storageService.saveBiometricToken(sessionToken);
      await storageService.setBiometricEnabled(true);
      return true;
    }
    return false;
  }

  /// Toggles biometric quick-access OFF:
  /// Immediately deletes/invalidates the stored cryptographic token in secure storage (Keychain/Keystore).
  Future<void> disableBiometrics() async {
    await storageService.clearBiometricToken();
    await storageService.setBiometricEnabled(false);
  }

  /// On subsequent app launch: verifies biometrics and retrieves the secured session token.
  Future<String?> authenticateAndRetrieveToken({required String reason}) async {
    if (!isBiometricEnabled) return null;

    final token = await storageService.getBiometricToken();
    if (token == null || token.trim().isEmpty) {
      // Fallback: check if main access token is in secure storage
      final fallbackToken = await storageService.getAccessToken();
      if (fallbackToken == null || fallbackToken.trim().isEmpty) {
        await disableBiometrics();
        return null;
      }
    }

    final success = await authenticate(localizedReason: reason);
    if (success) {
      final validToken = token ?? await storageService.getAccessToken();
      return validToken;
    }
    return null;
  }
}
