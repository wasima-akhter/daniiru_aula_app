import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/stripe_config.dart';
import '../services/notification/push_notification_service.dart';
import '../storage/storage_provider.dart';

Future<void> bootstrap({required Widget app}) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    if (kDebugMode) {
      debugPrint('Flutter error: ${details.exception}');
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Uncaught application error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return true;
  };

  // Initialize SharedPreferences BEFORE creating ProviderContainer.
  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
  );

  // Initialize PushNotificationService safely in background
  container.read(pushNotificationServiceProvider).initialize();

  // Initialize Stripe SDK if configured on mobile platform
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && StripeConfig.isConfigured) {
    try {
      Stripe.publishableKey = StripeConfig.publishableKey.trim();
      Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Stripe bootstrap initialization error: $e');
    }
  }

  try {
    runApp(UncontrolledProviderScope(container: container, child: app));
  } catch (error, stackTrace) {
    debugPrint('Bootstrap error: $error');
    debugPrintStack(stackTrace: stackTrace);

    container.dispose();

    rethrow;
  }
}
