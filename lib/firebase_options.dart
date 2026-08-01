import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

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
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRoKh-yI8UBFnuezbkbeyc6uec8_raP6Q',
    appId: '1:536516621931:android:951e4d21713dce2b2c232e',
    messagingSenderId: '536516621931',
    projectId: 'wow100-106c3',
    storageBucket: 'wow100-106c3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAT5GFAHL8HK0rD3w0_dbZDJw1tiuDFG5Y',
    appId: '1:536516621931:ios:65c8b480caf700dc2c232e',
    messagingSenderId: '536516621931',
    projectId: 'wow100-106c3',
    storageBucket: 'wow100-106c3.firebasestorage.app',
    iosBundleId: 'fr.cosmoslty.wow100',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2_BYcKi4jM5D5tEqeCxTO6ek6snL_mcg',
    appId: '1:536516621931:web:658d4afd061997572c232e',
    messagingSenderId: '536516621931',
    projectId: 'wow100-106c3',
    authDomain: 'wow100-106c3.firebaseapp.com',
    storageBucket: 'wow100-106c3.firebasestorage.app',
    measurementId: 'G-LJ1BX29K70',
  );
}
