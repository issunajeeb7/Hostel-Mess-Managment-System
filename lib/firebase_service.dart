import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'changenotifier.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToScanCounterChanges(BuildContext context) {
    print('Listening to scan counter changes...');
    _firestore
        .collection('scanCounter')
        .doc('counterDoc')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        int counterValue = snapshot.data()?['counter'] ?? 0;
        print('Counter value changed: $counterValue');
        Provider.of<ScanCounter>(context, listen: false).setCounter(counterValue);
        notifyHostellers(context);
      }
    });
  }

  Future<void> notifyHostellers(BuildContext context) async {
    int counterValue = Provider.of<ScanCounter>(context, listen: false).counter;
    String notificationMessage = getNotificationMessage(counterValue);

    if (notificationMessage.isNotEmpty) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Hosteller')
          .get();

      List<String> tokens = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? fcmToken = data['fcmToken'];
        if (fcmToken != null) {
          tokens.add(fcmToken);
          print("FCM token fetched: $fcmToken");
        } else {
          print("FCM token is null for document with ID: ${doc.id}");
        }
      }

      await sendNotificationToTokens(notificationMessage, tokens);
    }
  }

  String getNotificationMessage(int counterValue) {
    if (counterValue == 120) {
      return "The Mess is full";
    } else if (counterValue == 110) {
      return "Hurry up! There are some seats waiting for you";
    } else if (counterValue == 60) {
      return "Quick! Seats are filling up fast";
    } else if (counterValue == 45) {
      return "Spots Available! Come dine with us";
    } else {
      return ""; // No notification for other values
    }
  }

  Future<void> sendNotificationToTokens(String message, List<String> tokens) async {
    String serverKey =
        'AAAAmxnaihY:APA91bF-LxlJ9IYEO8bofjYXxzQpZyy8wAlp8FFf_gi0L_NOa05dHFkpb6w30KHCm5BC8K6WSe2je2NqaCkICGZREYPJWsXyVzkyWi_7gNPOJefBBFtOp7trJjsZdQHYvi53if_P7qJU'; // Remember to replace with your actual server key
    print('Sending notification to tokens: $tokens');
    await http
        .post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode(
            <String, dynamic>{
              'registration_ids': tokens,
              'notification': {
                'title': 'Mess Rush Update',
                'body': message,
              },
            },
          ),
        )
        .then((response) {
      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification. Status code: ${response.statusCode}');
      }
    }).catchError((error) {
      print('Error sending notification: $error');
    });
  }
}
