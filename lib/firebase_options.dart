import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    final options = currentPlatformOrNull;
    if (options == null) {
      throw UnsupportedError(
        'Firebase options have not been configured for this platform.',
      );
    }

    return options;
  }

  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) {
      return _isConfigured(web) ? web : null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _isConfigured(android) ? android : null;
      case TargetPlatform.iOS:
        return _isConfigured(ios) ? ios : null;
      case TargetPlatform.macOS:
        return _isConfigured(macos) ? macos : null;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static bool _isConfigured(FirebaseOptions options) {
    return options.apiKey.isNotEmpty &&
        options.appId.isNotEmpty &&
        options.messagingSenderId.isNotEmpty &&
        options.projectId.isNotEmpty;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: ''),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: '',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
    measurementId: String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
      defaultValue: '',
    ),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: ''),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: ''),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: '',
    ),
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_MACOS_APP_ID', defaultValue: ''),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    ),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_MACOS_BUNDLE_ID',
      defaultValue: '',
    ),
  );
}
