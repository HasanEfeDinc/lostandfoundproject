// File generated by FlutterFire CLI.
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
    apiKey: 'AIzaSyAQquZGchCDdMNY258AvPlswAhcLc-1Hco',
    appId: '1:255972473806:web:5ce1732b287868e3f0499f',
    messagingSenderId: '255972473806',
    projectId: 'lostandfoundproject-7cd26',
    authDomain: 'lostandfoundproject-7cd26.firebaseapp.com',
    storageBucket: 'lostandfoundproject-7cd26.firebasestorage.app',
    measurementId: 'G-9VL6XN4CR6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvCRzHqGzXhfG3x4jw0sPGhQBscE7syk4',
    appId: '1:255972473806:android:a261367bbfcc0008f0499f',
    messagingSenderId: '255972473806',
    projectId: 'lostandfoundproject-7cd26',
    storageBucket: 'lostandfoundproject-7cd26.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAocLcQdQHYsSP5fG_Y0evwIhW2ZsK8eh0',
    appId: '1:255972473806:ios:be41cfc232a2323cf0499f',
    messagingSenderId: '255972473806',
    projectId: 'lostandfoundproject-7cd26',
    storageBucket: 'lostandfoundproject-7cd26.firebasestorage.app',
    iosBundleId: 'com.example.lostandfoundproject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAocLcQdQHYsSP5fG_Y0evwIhW2ZsK8eh0',
    appId: '1:255972473806:ios:be41cfc232a2323cf0499f',
    messagingSenderId: '255972473806',
    projectId: 'lostandfoundproject-7cd26',
    storageBucket: 'lostandfoundproject-7cd26.firebasestorage.app',
    iosBundleId: 'com.example.lostandfoundproject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAQquZGchCDdMNY258AvPlswAhcLc-1Hco',
    appId: '1:255972473806:web:05e35f3edf4f0e60f0499f',
    messagingSenderId: '255972473806',
    projectId: 'lostandfoundproject-7cd26',
    authDomain: 'lostandfoundproject-7cd26.firebaseapp.com',
    storageBucket: 'lostandfoundproject-7cd26.firebasestorage.app',
    measurementId: 'G-FW9PRHRM3K',
  );
}
