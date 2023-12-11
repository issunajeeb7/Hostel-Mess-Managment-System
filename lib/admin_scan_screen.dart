import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({Key? key});

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
        userId = scanData.code ?? '';
        print('Scanned ID: $userId');
        controller.pauseCamera();
      });
    });
  }

Future<void> _markAttendance() async {
  if (scanned) {
    if (userId.startsWith('Userid:')) {
      String actualUserId = userId.substring('Userid:'.length);
      print('Actual user id: $actualUserId');

      DateTime now = DateTime.now();
      String mealType = determineMealType(now.hour);

      // Format the current date without the time
      String currentDateFormatted = DateFormat('yyyy-MM-dd').format(now);

      QuerySnapshot voucherQuery = await FirebaseFirestore.instance
          .collection('mealvouchers')
          .where('hostellerId', isEqualTo: actualUserId)
          .where('mealType', isEqualTo: mealType)
          .where('date', isEqualTo: currentDateFormatted)
          .get();

      print('Voucher Query: ${voucherQuery.docs}');

      if (voucherQuery.docs.isNotEmpty) {
        // Voucher exists, show a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already generated a voucher for $mealType on $currentDateFormatted'),
          ),
        );
      } else {
        // Voucher does not exist, mark attendance
        await addAttendanceRecord(actualUserId, mealType);
        showSnackBar('Attendance marked for $mealType ');
      }
    } else if (userId.startsWith('VoucherId:')) {
      String voucherId = userId.substring('VoucherId:'.length);
      print('Voucher ID: $voucherId');

      // Update isUsed field in mealvouchers to true
      await FirebaseFirestore.instance
          .collection('mealvouchers')
          .doc(voucherId)
          .update({'isUsed': true});

      // Update isRedeemed field in transactions to true
      await FirebaseFirestore.instance
          .collection('transactions')
          .where('voucherID', isEqualTo: voucherId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((transactionDoc) {
          transactionDoc.reference.update({'isRedeemed': true});
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher marked as used.'),
        ),
      );
    }

    setState(() {
      scanned = false;
      controller.resumeCamera();
    });
  }
}





  String determineMealType(int hour) {
    if (hour >= 12 && hour < 15) {
      return 'Lunch';
    } else if (hour >= 15 && hour < 18) {
      return 'Snack';
    } else if (hour >= 18) {
      return 'Dinner';
    }
    return 'Breakfast';
  }

  Future<void> addAttendanceRecord(String hostellerId, String mealType) async {
    Map<String, dynamic> attendanceData = {
      'userId': hostellerId,
      'date': Timestamp.now(),
      'mealType': mealType,
    };
    await FirebaseFirestore.instance
        .collection('attendance')
        .add(attendanceData);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
