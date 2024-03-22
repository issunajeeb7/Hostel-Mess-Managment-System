import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    // Here, you can call a method to save this token to your Firestore database
    // Assume saveTokenToDatabase(token) is a method that saves the token to Firestore
    if (token != null) {
      saveTokenToDatabase(token);
    }
  }

  Future<void> saveTokenToDatabase(String token) async {
    // Assume you have a method to get the current user's ID
    String? userId = FirebaseAuth.instance.currentUser?.uid; // Replace with your method to get the user's ID

    // Save the token to the Firestore database
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}
