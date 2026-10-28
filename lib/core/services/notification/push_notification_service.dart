import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../utils/extension/base_extension.dart';
import '../../router/route_path.dart';
import '../../router/routes.dart';
import '../../storage/storage_provider.dart';
import '../../storage/storage_service.dart';
import 'widgets/in_app_notification_overlay.dart';

/// Top-level background message handler executed by the Flutter engine
/// in a separate isolate when the app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );
    debugPrint('📥 FCM NOTIFICATION RECEIVED [STATE: BACKGROUND / ISOLATE]');
    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );
    debugPrint('MESSAGE ID   : ${message.messageId}');
    debugPrint(
      'TITLE        : ${message.notification?.title ?? message.data['title'] ?? '(No title)'}',
    );
    debugPrint(
      'BODY         : ${message.notification?.body ?? message.data['body'] ?? '(No body)'}',
    );
    debugPrint('DATA PAYLOAD : ${message.data}');
    debugPrint(
      'SENT TIME    : ${message.sentTime?.toIso8601String() ?? 'N/A'}',
    );
    debugPrint('LIFECYCLE    : Top-level background handler executed');
    debugPrint('TIMESTAMP    : ${DateTime.now().toIso8601String()}');
    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );
  } catch (e) {
    debugPrint('PushNotificationService: Background handler error: $e');
  }
}

/// Centralized service managing Firebase Cloud Messaging (FCM) push notifications across
/// all lifecycle states (Foreground, Background, Terminated), OS permissions, token synchronization,
/// and contextual routing.
class PushNotificationService {
  PushNotificationService({required this.storageService});

  final StorageService storageService;
  bool _isInitialized = false;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of incoming foreground notifications
  Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessageController.stream;

  /// Cached initial message when the app was launched by tapping a notification from terminated state
  RemoteMessage? _pendingInitialMessage;

  /// Callback invoked when FCM rotates the device token while the app is running
  void Function(String newToken)? onTokenRefreshed;

  /// Initializes Firebase, registers background handlers, notification listeners, and token lifecycle.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // 1. Register top-level background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Configure iOS foreground presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // 3. Listen for token rotations while the app is active
      _tokenRefreshSubscription?.cancel();
      // ignore: deprecated_member_use
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) async {
            debugPrint(
              '══════════════════════════════════════════════════════════════',
            );
            debugPrint('🔄 FCM DEVICE TOKEN REFRESHED / ROTATED');
            debugPrint(
              '══════════════════════════════════════════════════════════════',
            );
            debugPrint('NEW TOKEN : $newToken');
            debugPrint(
              'ACTION    : Cached in local storage and triggering sync callback',
            );
            debugPrint('TIMESTAMP : ${DateTime.now().toIso8601String()}');
            debugPrint(
              '══════════════════════════════════════════════════════════════',
            );
            await storageService.saveFcmToken(newToken);
            onTokenRefreshed?.call(newToken);
          });

      // 4. Foreground notification handling
      _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('📥 FCM NOTIFICATION RECEIVED [STATE: FOREGROUND]');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('MESSAGE ID   : ${message.messageId}');
        debugPrint(
          'TITLE        : ${message.notification?.title ?? message.data['title'] ?? '(No title)'}',
        );
        debugPrint(
          'BODY         : ${message.notification?.body ?? message.data['body'] ?? '(No body)'}',
        );
        debugPrint('DATA PAYLOAD : ${message.data}');
        debugPrint('ACTION       : Presenting InAppNotificationOverlay banner');
        debugPrint('TIMESTAMP    : ${DateTime.now().toIso8601String()}');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        _foregroundMessageController.add(message);
        showInAppNotification(message);
      });

      // 5. Background notification tapped handling (brought app from background to foreground)
      _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) {
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint(
          '👆 FCM NOTIFICATION TAPPED [STATE: RESUMED FROM BACKGROUND]',
        );
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('MESSAGE ID   : ${message.messageId}');
        debugPrint(
          'TITLE        : ${message.notification?.title ?? message.data['title'] ?? '(No title)'}',
        );
        debugPrint('DATA PAYLOAD : ${message.data}');
        debugPrint('ACTION       : Executing handleNotificationNavigation()');
        debugPrint('TIMESTAMP    : ${DateTime.now().toIso8601String()}');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        handleNotificationNavigation(message.data);
      });

      // 6. Terminated notification tapped handling (cold boot)
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint(
          '🚀 FCM APP COLD BOOT FROM NOTIFICATION [STATE: TERMINATED]',
        );
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('MESSAGE ID   : ${initialMessage.messageId}');
        debugPrint(
          'TITLE        : ${initialMessage.notification?.title ?? initialMessage.data['title'] ?? '(No title)'}',
        );
        debugPrint('DATA PAYLOAD : ${initialMessage.data}');
        debugPrint(
          'ACTION       : Stored pending initial message for navigation after boot',
        );
        debugPrint('TIMESTAMP    : ${DateTime.now().toIso8601String()}');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        _pendingInitialMessage = initialMessage;
      }

      _isInitialized = true;

      // Eagerly acquire and cache device FCM push token in background
      unawaited(getFcmToken(requestPermissionFirst: false));
    } catch (e) {
      debugPrint(
        'PushNotificationService: Firebase initialization skipped/failed: $e',
      );
    }
  }

  /// Requests notification permissions from the OS.
  /// - On iOS: Prompts native system dialog for alert, badge, and sound.
  /// - On Android 13+ (API 33+): Prompts system runtime POST_NOTIFICATIONS dialog.
  Future<NotificationSettings?> requestPermissions() async {
    try {
      await initialize();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
      return settings;
    } catch (e) {
      debugPrint(
        'PushNotificationService: Failed to request notification permissions: $e',
      );
      return null;
    }
  }

  /// Checks if notification permissions have been granted.
  Future<bool> isPermissionGranted() async {
    try {
      await initialize();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Gets the current authorization status from Firebase Messaging.
  Future<AuthorizationStatus> getAuthorizationStatus() async {
    try {
      await initialize();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus;
    } catch (_) {
      return AuthorizationStatus.notDetermined;
    }
  }

  /// Retrieves the current device FCM Push Token.
  /// Even if notification permissions are denied or not yet granted,
  /// FCM token retrieval on Android proceeds so the device can be registered
  /// on the backend.
  Future<String?> getFcmToken({bool requestPermissionFirst = false}) async {
    try {
      await initialize();

      if (requestPermissionFirst) {
        try {
          final settings = await requestPermissions();
          debugPrint(
            'PushNotificationService: Permission status: ${settings?.authorizationStatus}',
          );
        } catch (e) {
          debugPrint(
            'PushNotificationService: Error requesting permission before token: $e',
          );
        }
      }

      // On iOS, ensure APNs token is available before requesting FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int attempts = 0;
        while (apnsToken == null && attempts < 6) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
      }

      // Retrieve device FCM Push Token regardless of notification permission
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('🔑 FCM DEVICE TOKEN ACQUIRED');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        debugPrint('TOKEN     : $token');
        debugPrint('SAVED     : Local storage updated');
        debugPrint('CALLBACK  : onTokenRefreshed triggered for session sync');
        debugPrint('TIMESTAMP : ${DateTime.now().toIso8601String()}');
        debugPrint(
          '══════════════════════════════════════════════════════════════',
        );
        await storageService.saveFcmToken(token);
        onTokenRefreshed?.call(token);
        return token;
      }
      return null;
    } catch (e) {
      debugPrint('PushNotificationService: Could not retrieve FCM token: $e');
      return storageService.getFcmToken();
    }
  }

  /// Retrieves previously cached FCM token or fetches a fresh one without prompting.
  Future<String?> getCachedOrFetchToken() async {
    final cached = await storageService.getFcmToken();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return getFcmToken(requestPermissionFirst: false);
  }

  /// Determines whether the Soft In-App Primer should be shown to the user.
  Future<bool> shouldShowSoftPrimer({
    Duration cooldown = const Duration(days: 7),
  }) async {
    try {
      final isGranted = await isPermissionGranted();
      if (isGranted) return false;

      final isDismissedRecently = storageService
          .isNotificationPrimerDismissedRecently(cooldown: cooldown);
      if (isDismissedRecently) return false;

      final status = await getAuthorizationStatus();
      if (status == AuthorizationStatus.denied) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records that the user dismissed the soft primer ("Maybe Later").
  Future<void> dismissSoftPrimer() async {
    await storageService.setNotificationPrimerDismissed(dismissed: true);
  }

  /// Invoked when the user taps "Enable Notifications" on the Soft In-App Primer.
  Future<bool> promptPermissionsFromPrimer() async {
    try {
      final settings = await requestPermissions();
      final isGranted =
          settings?.authorizationStatus == AuthorizationStatus.authorized ||
          settings?.authorizationStatus == AuthorizationStatus.provisional;

      await storageService.setNotificationPrimerDismissed(dismissed: true);

      final token = await getFcmToken(requestPermissionFirst: false);
      if (isGranted) {
        debugPrint(
          'PushNotificationService: Permission granted via primer, FCM token: $token',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(
        'PushNotificationService: Error requesting permission from primer: $e',
      );
      return false;
    }
  }

  /// Processes any pending notification that launched the app from terminated state.
  void handlePendingInitialNotification() {
    final pending = _pendingInitialMessage;
    if (pending != null) {
      _pendingInitialMessage = null;
      debugPrint(
        '══════════════════════════════════════════════════════════════',
      );
      debugPrint('🚀 EXECUTING PENDING TERMINATED NOTIFICATION NAVIGATION');
      debugPrint(
        '══════════════════════════════════════════════════════════════',
      );
      debugPrint('MESSAGE ID : ${pending.messageId}');
      debugPrint('DATA       : ${pending.data}');
      debugPrint('TIMESTAMP  : ${DateTime.now().toIso8601String()}');
      debugPrint(
        '══════════════════════════════════════════════════════════════',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(pending.data);
      });
    }
  }

  /// Displays an interactive heads-up card when a notification arrives in foreground.
  void showInAppNotification(RemoteMessage message) {
    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      debugPrint('In-app notification skipped: overlay not available');
      return;
    }

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'New Notification';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    InAppNotificationOverlay.show(
      overlayState: overlayState,
      title: title,
      body: body,
      data: message.data,
      onTap: () {
        handleNotificationNavigation(message.data);
      },
    );
  }

  /// Routes the user to the destination screen based on notification payload [data].
  void handleNotificationNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) {
      AppRouter.router.push(RoutePath.notification.addBasePath);
      return;
    }

    final type = (data['type'] ?? data['click_action'] ?? data['screen'] ?? '')
        .toString()
        .toUpperCase();
    final entityId = data['entity_id'] ?? data['id'] ?? data['conversationId'];

    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );
    debugPrint('🧭 NOTIFICATION NAVIGATION DISPATCHER');
    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );
    debugPrint('TARGET TYPE : $type');
    debugPrint('ENTITY ID   : $entityId');
    debugPrint('RAW DATA    : $data');
    debugPrint('TIMESTAMP   : ${DateTime.now().toIso8601String()}');
    debugPrint(
      '══════════════════════════════════════════════════════════════',
    );

    switch (type) {
      case 'CHAT':
      case 'CONVERSATION':
      case 'MESSAGE':
      case 'PARENT_ADMIN':
      case 'TEACHER_PARENT':
        AppRouter.router.push(RoutePath.chatList);
        break;

      case 'ANNOUNCEMENT':
      case 'NOTICE':
      case 'BROADCAST':
        AppRouter.router.push(RoutePath.notification);
        break;

      case 'ATTENDANCE':
      case 'ATTENDANCE_CHECK_IN':
      case 'ABSENCE':
        AppRouter.router.push(RoutePath.attendance);
        break;

      case 'REPORT':
      case 'POST_CLASS_REPORT':
      case 'STUDENT_REPORT':
        if (entityId != null) {
          AppRouter.router.push(
            RoutePath.reportDetail,
            extra: entityId.toString(),
          );
        } else {
          AppRouter.router.push(RoutePath.teacherReports);
        }
        break;

      case 'HOMEWORK':
      case 'ASSIGNMENT':
        if (entityId != null) {
          AppRouter.router.push(
            RoutePath.homeworkDetail,
            extra: entityId.toString(),
          );
        } else {
          AppRouter.router.push(RoutePath.homework);
        }
        break;

      case 'PAYMENT':
      case 'INVOICE':
      case 'SUBSCRIPTION':
        AppRouter.router.push(RoutePath.payment);
        break;

      default:
        AppRouter.router.push(RoutePath.notification);
        break;
    }
  }

  /// Opens native application system settings using Geolocator.
  Future<bool> openDeviceSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('PushNotificationService: Failed to open app settings: $e');
      return false;
    }
  }

  /// Disposes background streams.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _foregroundMessageController.close();
  }
}

/// Riverpod provider for [PushNotificationService].
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  final service = PushNotificationService(storageService: storage);
  ref.onDispose(service.dispose);
  return service;
});
