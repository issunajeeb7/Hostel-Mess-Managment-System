// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAkUWKpCE4bq-IisEgspdWN5i0f3OmWyg0',
    appId: '1:666153683478:web:9c247f932cec2da82c4337',
    messagingSenderId: '666153683478',
    projectId: 'hostel-mess-managment-system',
    authDomain: 'hostel-mess-managment-system.firebaseapp.com',
    storageBucket: 'hostel-mess-managment-system.appspot.com',
    measurementId: 'G-5HLRHB97R7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQgN-tNVmFcPleRf-Z0kc7UZnvHtLap9I',
    appId: '1:666153683478:android:f1461ba60ac4997e2c4337',
    messagingSenderId: '666153683478',
    projectId: 'hostel-mess-managment-system',
    storageBucket: 'hostel-mess-managment-system.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAU-RvI0orxUwZSgCW68zpENXC9Shf0w04',
    appId: '1:666153683478:ios:98beae28966f60cd2c4337',
    messagingSenderId: '666153683478',
    projectId: 'hostel-mess-managment-system',
    storageBucket: 'hostel-mess-managment-system.appspot.com',
    iosBundleId: 'com.messbytes',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAU-RvI0orxUwZSgCW68zpENXC9Shf0w04',
    appId: '1:666153683478:ios:4d80f977032a39e02c4337',
    messagingSenderId: '666153683478',
    projectId: 'hostel-mess-managment-system',
    storageBucket: 'hostel-mess-managment-system.appspot.com',
    iosBundleId: 'com.messbytes.RunnerTests',
  );
}
