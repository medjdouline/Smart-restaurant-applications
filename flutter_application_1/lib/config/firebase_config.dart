import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  static FirebaseOptions get webOptions => const FirebaseOptions(
    apiKey: "AIzaSyAYqym7Dcr1k_VhyP54L8mxpzT7QctiCQ8",
    authDomain: "pferestau25.firebaseapp.com",
    projectId: "pferestau25",
    storageBucket: "pferestau25.firebasestorage.app",
    messagingSenderId: "180090883215",
    appId: "1:180090883215:web:c1dabc61a8a3ab8a4e34fa"
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: webOptions,
    );
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}