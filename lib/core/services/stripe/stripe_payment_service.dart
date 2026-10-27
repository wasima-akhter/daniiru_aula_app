import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../config/stripe_config.dart';

/// Represents the status of a Stripe payment process.
enum StripePaymentStatus {
  success,
  canceled,
  declined,
  alreadyPaid,
  notConfigured,
  unsupportedPlatform,
  networkError,
  failed,
}

/// Result envelope returned by [StripePaymentService].
class StripePaymentResult {
  final StripePaymentStatus status;
  final String? message;
  final String? errorCode;

  const StripePaymentResult({
    required this.status,
    this.message,
    this.errorCode,
  });

  bool get isSuccess => status == StripePaymentStatus.success;
  bool get isCanceled => status == StripePaymentStatus.canceled;
  bool get isDeclined => status == StripePaymentStatus.declined;
  bool get isAlreadyPaid => status == StripePaymentStatus.alreadyPaid;
  bool get isNotConfigured => status == StripePaymentStatus.notConfigured;
  bool get isUnsupportedPlatform =>
      status == StripePaymentStatus.unsupportedPlatform;
  bool get isNetworkError => status == StripePaymentStatus.networkError;
  bool get isFailed => status == StripePaymentStatus.failed;

  factory StripePaymentResult.success() =>
      const StripePaymentResult(status: StripePaymentStatus.success);

  factory StripePaymentResult.canceled() =>
      const StripePaymentResult(status: StripePaymentStatus.canceled);

  factory StripePaymentResult.declined({String? message}) =>
      StripePaymentResult(
        status: StripePaymentStatus.declined,
        message: message,
      );

  factory StripePaymentResult.alreadyPaid({String? message}) =>
      StripePaymentResult(
        status: StripePaymentStatus.alreadyPaid,
        message: message,
      );

  factory StripePaymentResult.notConfigured({String? message}) =>
      StripePaymentResult(
        status: StripePaymentStatus.notConfigured,
        message: message,
      );

  factory StripePaymentResult.unsupportedPlatform({String? message}) =>
      StripePaymentResult(
        status: StripePaymentStatus.unsupportedPlatform,
        message: message,
      );

  factory StripePaymentResult.networkError({String? message}) =>
      StripePaymentResult(
        status: StripePaymentStatus.networkError,
        message: message,
      );

  factory StripePaymentResult.failed({String? message, String? errorCode}) =>
      StripePaymentResult(
        status: StripePaymentStatus.failed,
        message: message,
        errorCode: errorCode,
      );
}

/// Abstract contract for Stripe payment operations.
abstract class StripePaymentService {
  Future<StripePaymentResult> presentPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
  });
}

/// Concrete implementation of [StripePaymentService] leveraging `flutter_stripe`.
class StripePaymentServiceImpl implements StripePaymentService {
  bool _isStripeInitialized = false;

  Future<void> _ensureInitialized() async {
    if (StripeConfig.isConfigured) {
      final key = StripeConfig.publishableKey.trim();
      if (!_isStripeInitialized || Stripe.publishableKey != key) {
        Stripe.publishableKey = key;
        Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;
        await Stripe.instance.applySettings();
        _isStripeInitialized = true;
      }
    }
  }

  @override
  Future<StripePaymentResult> presentPaymentSheet({
    required String clientSecret,
    String? merchantDisplayName,
  }) async {
    // Edge case 1: Stripe public key not configured yet
    if (!StripeConfig.isConfigured) {
      debugPrint('[StripePaymentService] Stripe publishable key is not configured.');
      return StripePaymentResult.notConfigured();
    }

    // Edge case 2: Running on unsupported platform (e.g. desktop/web without native payment sheet)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint(
        '[StripePaymentService] PaymentSheet is only supported on Android and iOS devices.',
      );
      return StripePaymentResult.unsupportedPlatform();
    }

    // Edge case 3: Invalid or empty clientSecret
    if (clientSecret.trim().isEmpty) {
      debugPrint('[StripePaymentService] clientSecret received is empty.');
      return StripePaymentResult.failed(message: 'Empty client secret');
    }

    try {
      await _ensureInitialized();

      // Initialize Payment Sheet with client secret from backend
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret.trim(),
          merchantDisplayName:
              merchantDisplayName ?? StripeConfig.merchantDisplayName,
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: true,
        ),
      );

      // Present the native bottom sheet to user
      await Stripe.instance.presentPaymentSheet();

      return StripePaymentResult.success();
    } on StripeException catch (e) {
      debugPrint('[StripePaymentService] StripeException code: ${e.error.code}');
      debugPrint('[StripePaymentService] StripeException message: ${e.error.message}');
      debugPrint('[StripePaymentService] StripeException localizedMessage: ${e.error.localizedMessage}');
      debugPrint('[StripePaymentService] StripeException stripeErrorCode: ${e.error.stripeErrorCode}');
      debugPrint('[StripePaymentService] StripeException declineCode: ${e.error.declineCode}');

      if (e.error.code == FailureCode.Canceled) {
        return StripePaymentResult.canceled();
      }

      if (e.error.code == FailureCode.Failed) {
        return StripePaymentResult.declined(
          message: e.error.localizedMessage ?? e.error.message,
        );
      }

      if (e.error.code == FailureCode.Timeout) {
        return StripePaymentResult.networkError(
          message: e.error.localizedMessage ?? e.error.message,
        );
      }

      return StripePaymentResult.failed(
        message: e.error.localizedMessage ?? e.error.message,
        errorCode: e.error.code.name,
      );
    } catch (e, st) {
      debugPrint('[StripePaymentService] Unexpected exception: $e\n$st');
      return StripePaymentResult.failed(message: e.toString());
    }
  }
}

/// Riverpod provider for StripePaymentService.
final stripePaymentServiceProvider = Provider<StripePaymentService>((ref) {
  return StripePaymentServiceImpl();
});
