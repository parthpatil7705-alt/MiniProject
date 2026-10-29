// File generated for RoomBuddy Firebase Configuration.
// Run `flutterfire configure` to generate project-specific keys from your Firebase Console,
// or replace the placeholders below with your project credentials.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your RoomBuddy Firebase apps.
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
  /// Indicates whether live Firebase credentials have been supplied.
  /// If false, RoomBuddy runs gracefully in local demo mode with seed data.
  static bool get isConfigured {
    return web.apiKey != 'YOUR_WEB_API_KEY' &&
        web.projectId != 'YOUR_PROJECT_ID' &&
        web.apiKey.isNotEmpty;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXbkR9LKxfLTmE7pIyJqzSH-AgWLxyeZs',
    appId: '1:621650023286:web:4a1911738e15b8816ae057',
    messagingSenderId: '621650023286',
    projectId: 'room-buddy-app',
    authDomain: 'room-buddy-app.firebaseapp.com',
    storageBucket: 'room-buddy-app.firebasestorage.app',
    measurementId: 'G-15013MG4P3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBU9p-uK_BMc42T1M52P2MnNrnBVUVYDgA',
    appId: '1:621650023286:android:8db3c7d329a33cbc6ae057',
    messagingSenderId: '621650023286',
    projectId: 'room-buddy-app',
    storageBucket: 'room-buddy-app.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCTKpLVTjrEnmixQO5vu__Qdk1VVwXVBDk',
    appId: '1:621650023286:ios:c871cf57db1f62a46ae057',
    messagingSenderId: '621650023286',
    projectId: 'room-buddy-app',
    storageBucket: 'room-buddy-app.firebasestorage.app',
    iosBundleId: 'com.roombuddy.roomBuddy',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:123456789012:ios:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.roombuddy.room_buddy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: '1:123456789012:web:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
