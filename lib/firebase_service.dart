import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
void listenToScanCounterChanges() {
  _firestore.collection('scanCounter').doc('counterDoc').snapshots().listen((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      int counterValue = snapshot.data()?['counter'] ?? 0; // Default to 0 if 'counter' is not found
      print('Counter value changed: $counterValue'); // Add this debug print statement
      notifyHostellers(counterValue);
    }
  });
}

Future<void> notifyHostellers(int counterValue) async {
  // Determine the notification message based on counterValue
  String notificationMessage = getNotificationMessage(counterValue);

  if (notificationMessage.isNotEmpty) {
    // Query for hosteller tokens
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Hosteller')
        .get();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>; // Cast data to Map<String, dynamic>
      String? fcmToken = data['fcmToken'];
      if (fcmToken != null) {
        // Debug print for fetched FCM token
        print("FCM token fetched: $fcmToken");

        await sendNotificationToToken(notificationMessage, fcmToken); // fcmToken is guaranteed to be non-null here.
      } else {
        // Handle or log the null case, e.g., fcmToken is missing.
        print("FCM token is null for document with ID: ${doc.id}");
      }
    }
  }
}


  String getNotificationMessage(int counterValue) {
    if (counterValue >= 120) {
      return "The Mess is full";
    } else if (counterValue > 60 && counterValue < 120) {
      return "Hurry up! The mess is about to fill up";
    } else if (counterValue >= 40 && counterValue <= 50) {
      return "I'm feeling vacant";
    } else {
      return ""; // No notification for other values
    }
  }

  Future<void> sendNotificationToToken(String message, String token) async {
    String serverKey =
        'AAAAmxnaihY:APA91bF-LxlJ9IYEO8bofjYXxzQpZyy8wAlp8FFf_gi0L_NOa05dHFkpb6w30KHCm5BC8K6WSe2je2NqaCkICGZREYPJWsXyVzkyWi_7gNPOJefBBFtOp7trJjsZdQHYvi53if_P7qJU'; // Remember to replace with your actual server key
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(
        <String, dynamic>{
          'to': token,
          'notification': {
            'title': 'Mess Status Update',
            'body': message,
          },
        },
      ),
    );
  }
}
