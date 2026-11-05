import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/utils/app_strings/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider and Localization Flow Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Initial language defaults to English and resolves English strings',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = await container.read(languageProvider.future);

        expect(state.language, equals(AppLanguage.english));
        expect(state.languageCode, equals('en'));
        expect(state.tr(AppStrings.settingsTitle), equals('Settings'));
        expect(state.tr(AppStrings.goodMorning), equals('Good morning'));
      },
    );

    test('tr() respects active language for fallbacks', () {
      final englishState = const LanguageState(
        language: AppLanguage.english,
        strings: {},
      );

      final spanishState = const LanguageState(
        language: AppLanguage.spanish,
        strings: {},
      );

      // Verify that English fallback returns English, NOT Spanish
      expect(englishState.tr(AppStrings.settingsTitle), equals('Settings'));
      expect(englishState.tr(AppStrings.today), equals('Today'));
      expect(
        englishState.tr(AppStrings.settingsBiometricEnabled),
        equals('Biometric access enabled'),
      );
      expect(
        englishState.tr(AppStrings.settingsBiometricNotSupported),
        equals('Biometrics is not supported on this device'),
      );
      expect(
        englishState.tr(AppStrings.settingsBiometricExpired),
        equals('Biometric session expired. Please log in with password.'),
      );

      // Verify that Spanish fallback returns Spanish
      expect(
        spanishState.tr(AppStrings.settingsTitle),
        equals('Configuración'),
      );
      expect(spanishState.tr(AppStrings.today), equals('Hoy'));
      expect(
        spanishState.tr(AppStrings.settingsBiometricEnabled),
        equals('Acceso biométrico habilitado'),
      );
      expect(
        spanishState.tr(AppStrings.settingsBiometricNotSupported),
        equals('La biometría no es compatible con este dispositivo'),
      );
      expect(
        spanishState.tr(AppStrings.settingsBiometricExpired),
        equals('Sesión biométrica expirada. Inicie sesión con su contraseña.'),
      );
    });

    test(
      'changeLanguage switches to Spanish and updates tr() output',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(languageProvider.future);
        await container
            .read(languageProvider.notifier)
            .changeLanguage(AppLanguage.spanish);

        final updatedState = container.read(languageProvider).value!;
        expect(updatedState.language, equals(AppLanguage.spanish));
        expect(updatedState.languageCode, equals('es'));
        expect(updatedState.tr(AppStrings.today), equals('Hoy'));

        // Verify persistence in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_language'), equals('es'));
      },
    );

    test('Restores persisted language code on initialization', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'es'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(languageProvider.future);
      expect(state.language, equals(AppLanguage.spanish));
      expect(state.languageCode, equals('es'));
      expect(state.tr(AppStrings.navReports), equals('Informes'));
    });
  });
}
