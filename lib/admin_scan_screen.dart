import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});

  @override
  _AdminScanScreenState createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool scanned = false;
  String userId = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Scan'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          if (scanned)
            ElevatedButton(
              onPressed: _markAttendance,
              child: const Text('Mark Attendance'),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scanned = true;
        // Process the scanned QR code data
        userId = scanData.code ?? ''; // Use an empty string as a default if it's null
      });
    });
  }

  Future<void> _markAttendance() async {
    if (scanned) {
      // Determine the meal type based on the current time
      DateTime now = DateTime.now();
      String mealType = 'Breakfast';

      if (now.hour >= 12 && now.hour < 15) {
        mealType = 'Lunch';
      } else if (now.hour >= 15 && now.hour < 18) {
        mealType = 'Snack'; // Add "Snack" for the evening time
      } else if (now.hour >= 18) {
        mealType = 'Dinner';
      }

      // Create an attendance record
      Map<String, dynamic> attendanceData = {
        'userId': userId,
        'date': Timestamp.now(),
        'mealType': mealType,
        // Add other fields as needed
      };

      // Add the attendance record to Firestore
      await FirebaseFirestore.instance.collection('attendance').add(attendanceData);

      setState(() {
        scanned = false; // Reset scanned status
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked for $mealType'),
        ),
      );
    }
  }
}
