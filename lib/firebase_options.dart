// ignore_for_file: type=lint
// File generated normally by the FlutterFire CLI — this one is a manually
// written placeholder because that CLI needs an interactive Google login,
// which isn't available in this environment.
//
// TO FINISH THIS: run, in the project root, from a machine where you can
// log into your Google/Firebase account:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=gestentreprise-66a68 --platforms=android,windows
//
// That command registers an Android app and a Windows app under the
// gestentreprise-66a68 Firebase project (if they don't already exist) and
// OVERWRITES this file with the real apiKey/appId/messagingSenderId/
// storageBucket values, plus android/app/google-services.json. Until then,
// the placeholders below will make Firebase.initializeApp() throw.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('SupMag targets Windows and Android only — web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for $defaultTargetPlatform — '
            'SupMag targets Windows and Android only.');
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'gestentreprise-66a68',
    storageBucket: 'gestentreprise-66a68.firebasestorage.app',
  );

  static const windows = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'gestentreprise-66a68',
    storageBucket: 'gestentreprise-66a68.firebasestorage.app',
  );
}
