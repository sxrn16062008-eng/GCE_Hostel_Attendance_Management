import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForGCEBoysHostelWeb000',
    appId: '1:1234567890:web:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'gce-boys-hostel',
    authDomain: 'gce-boys-hostel.firebaseapp.com',
    storageBucket: 'gce-boys-hostel.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwOqtWWTFa3Qju-fn7Q818t6UsHSOOVSw',
    appId: '1:890481708179:android:a9e1c1c5ebe5feeb821166',
    messagingSenderId: '890481708179',
    projectId: 'gce-attendance-d74ec',
    storageBucket: 'gce-attendance-d74ec.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForGCEBoysHostelIOS000',
    appId: '1:1234567890:ios:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'gce-boys-hostel',
    storageBucket: 'gce-boys-hostel.appspot.com',
    iosBundleId: 'com.gce.hostel.atten',
  );
}
