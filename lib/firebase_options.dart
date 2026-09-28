// File generated for Dr Fix platform configuration.
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
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHXNxcHLGxiGC6HhBTdizqTE8iAHoPFDw',
    appId: '1:87995924664:web:60220fa6b6df4b4b8f344d',
    messagingSenderId: '87995924664',
    projectId: 'dr-fix-38bd1',
    authDomain: 'dr-fix-38bd1.firebaseapp.com',
    storageBucket: 'dr-fix-38bd1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHXNxcHLGxiGC6HhBTdizqTE8iAHoPFDw',
    appId: '1:87995924664:android:60220fa6b6df4b4b8f344d',
    messagingSenderId: '87995924664',
    projectId: 'dr-fix-38bd1',
    storageBucket: 'dr-fix-38bd1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHXNxcHLGxiGC6HhBTdizqTE8iAHoPFDw',
    appId: '1:87995924664:ios:60220fa6b6df4b4b8f344d',
    messagingSenderId: '87995924664',
    projectId: 'dr-fix-38bd1',
    storageBucket: 'dr-fix-38bd1.firebasestorage.app',
    iosBundleId: 'com.drfix.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAHXNxcHLGxiGC6HhBTdizqTE8iAHoPFDw',
    appId: '1:87995924664:ios:60220fa6b6df4b4b8f344d',
    messagingSenderId: '87995924664',
    projectId: 'dr-fix-38bd1',
    storageBucket: 'dr-fix-38bd1.firebasestorage.app',
    iosBundleId: 'com.drfix.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAHXNxcHLGxiGC6HhBTdizqTE8iAHoPFDw',
    appId: '1:87995924664:web:60220fa6b6df4b4b8f344d',
    messagingSenderId: '87995924664',
    projectId: 'dr-fix-38bd1',
    authDomain: 'dr-fix-38bd1.firebaseapp.com',
    storageBucket: 'dr-fix-38bd1.firebasestorage.app',
  );
}
