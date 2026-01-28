// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no está configurado todavía.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS no está configurado todavía.');
      case TargetPlatform.macOS:
        throw UnsupportedError('MacOs no está configurado todavía.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows no está configurado todavía.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux no está configurado todavía.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDRIY-cXETscI0-hvdJ_Jt_pA39BWICWU', // ¡Tu clave correcta!
    appId: '1:608770874573:android:cf933c83d73c6cbfc8dd84',
    messagingSenderId: '608770874573',
    projectId: 'internshipapp-unimet',
    storageBucket: 'internshipapp-unimet.firebasestorage.app',
  );
}