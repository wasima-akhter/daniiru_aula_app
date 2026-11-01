// File generated and configured for aula360.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpA6hH2oWX6481gJeW8BfRTy9GUXRR4As',
    appId: '1:108890914170:android:7c56bcd1a7cbf540402ac3',
    messagingSenderId: '108890914170',
    projectId: 'aula-360-ac586',
    storageBucket: 'aula-360-ac586.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB23glU8mISVEMP-58z0Q9arVf7VTVDZEs',
    appId: '1:108890914170:ios:5cc3e774316fe048402ac3',
    messagingSenderId: '108890914170',
    projectId: 'aula-360-ac586',
    storageBucket: 'aula-360-ac586.firebasestorage.app',
    iosBundleId: 'com.app.aula360',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB23glU8mISVEMP-58z0Q9arVf7VTVDZEs',
    appId: '1:108890914170:ios:5cc3e774316fe048402ac3',
    messagingSenderId: '108890914170',
    projectId: 'aula-360-ac586',
    storageBucket: 'aula-360-ac586.firebasestorage.app',
    iosBundleId: 'com.app.aula360',
  );
}

