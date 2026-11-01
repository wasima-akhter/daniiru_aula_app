import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/core/storage/storage_provider.dart';
import 'package:aula360/utils/app_strings/app_strings.dart';
import 'biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return BiometricService(storageService: storageService);
});

class BiometricState {
  final bool isSupported;
  final bool isEnrolled;
  final bool isEnabled;
  final String sensorLabel;
  final bool isLoading;
  final String? error;

  const BiometricState({
    this.isSupported = false,
    this.isEnrolled = false,
    this.isEnabled = false,
    this.sensorLabel = 'Biometric Access',
    this.isLoading = false,
    this.error,
  });

  BiometricState copyWith({
    bool? isSupported,
    bool? isEnrolled,
    bool? isEnabled,
    String? sensorLabel,
    bool? isLoading,
    String? error,
  }) {
    return BiometricState(
      isSupported: isSupported ?? this.isSupported,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isEnabled: isEnabled ?? this.isEnabled,
      sensorLabel: sensorLabel ?? this.sensorLabel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final biometricControllerProvider =
    NotifierProvider<BiometricController, BiometricState>(
  BiometricController.new,
);

class BiometricController extends Notifier<BiometricState> {
  late final BiometricService _service;

  @override
  BiometricState build() {
    _service = ref.watch(biometricServiceProvider);
    Future.microtask(() => checkStatus());
    return BiometricState(isEnabled: _service.isBiometricEnabled);
  }

  Future<void> checkStatus() async {
    try {
      final langCode =
          ref.read(languageProvider).valueOrNull?.language.code ?? 'en';
      final capability = await _service.checkCapability();
      final isSupported = capability != BiometricCapability.notSupported &&
          capability != BiometricCapability.unknown;
      final isEnrolled = capability == BiometricCapability.available;
      final sensorLabel =
          await _service.getBiometricTypeLabel(languageCode: langCode);

      state = state.copyWith(
        isSupported: isSupported,
        isEnrolled: isEnrolled,
        isEnabled: _service.isBiometricEnabled,
        sensorLabel: sensorLabel,
      );
    } catch (e) {
      debugPrint('[BiometricController] checkStatus error: $e');
    }
  }

  Future<bool> toggleBiometric(
    bool enable, {
    required String verificationReason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!enable) {
      // Disabling: immediately delete stored token and set flag to false
      await _service.disableBiometrics();
      state = state.copyWith(isEnabled: false, isLoading: false);
      return true;
    }

    final langCode =
        ref.read(languageProvider).valueOrNull?.language.code ?? 'en';
    final isSpanish = langCode.toLowerCase().startsWith('es');
    final tr = ref.read(languageProvider).valueOrNull?.tr;

    String resolveMsg(String key, String fallbackEn, String fallbackEs) {
      final translated = tr?.call(key);
      if (translated != null && translated != key) return translated;
      return isSpanish ? fallbackEs : fallbackEn;
    }

    // Enabling: verify device capability
    final capability = await _service.checkCapability();
    if (capability == BiometricCapability.notSupported) {
      state = state.copyWith(
        isLoading: false,
        error: resolveMsg(
          AppStrings.settingsBiometricNotSupported,
          'Biometrics is not supported on this device',
          'La biometría no es compatible con este dispositivo',
        ),
      );
      return false;
    }
    if (capability == BiometricCapability.notEnrolled) {
      state = state.copyWith(
        isLoading: false,
        error: resolveMsg(
          AppStrings.settingsBiometricNotEnrolled,
          'No biometrics enrolled on this device',
          'No hay datos biométricos configurados en el dispositivo',
        ),
      );
      return false;
    }

    // Retrieve active access token to encrypt/link
    final storageService = ref.read(storageServiceProvider);
    final activeToken = await storageService.getAccessToken();
    if (activeToken == null || activeToken.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: resolveMsg(
          AppStrings.settingsBiometricNoSession,
          'No active session found to link biometrics',
          'Sesión no encontrada para vincular biometría',
        ),
      );
      return false;
    }

    final success = await _service.enableBiometrics(
      sessionToken: activeToken,
      verificationReason: verificationReason,
    );

    state = state.copyWith(
      isEnabled: success,
      isLoading: false,
      error: success
          ? null
          : resolveMsg(
              AppStrings.settingsBiometricAuthFailed,
              'Authentication was cancelled or failed',
              'Autenticación cancelada o fallida',
            ),
    );
    return success;
  }

  Future<bool> authenticate({required String reason}) async {
    return _service.authenticate(localizedReason: reason);
  }
}
