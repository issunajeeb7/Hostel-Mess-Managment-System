import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';


class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({Key? key}) : super(key: key);

  @override
  _AdminScanScreenState createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen>
    with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool scanned = false;
  String userId = '';
  Map<String, dynamic> inmates = {};
  int globalCounter = 0;
  bool autoMarkAttendance = false;
  AudioPlayer audioPlayer = AudioPlayer();
  StreamController<int> _counterStreamController =
      StreamController<int>.broadcast();

  Stream<int> get counterStream => _counterStreamController.stream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

@override
void dispose() {
  print("Dispose methid is called");
  WidgetsBinding.instance.removeObserver(this);
  // Ensure the camera is stopped and disposed of
  if (controller != null) {
    controller.dispose();
    print('Controller disposed');

    
  }
  else{
    print('Controller is null, cannot dispose');
  }
  audioPlayer.dispose();
  _counterStreamController.close();
  super.dispose();
}

// Removed deactivate() method as it's no longer needed


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    
    if (state == AppLifecycleState.resumed) {
      controller.resumeCamera();
    } else if (state == AppLifecycleState.paused) {
      controller.pauseCamera();
    }
  }

  Future<void> playBeepSound() async {
    await audioPlayer.play(AssetSource('beep.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
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
            Column(
              children: [
                Text('Scan Counter: $globalCounter'),
              ],
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!autoMarkAttendance) {
        playBeepSound(); // Add your beep sound file to the assets folder
        setState(() {
          scanned = true;
          userId = scanData.code ?? '';
          print('Scanned ID: $userId');

          // Check if the user ID is already in the "inmates" map
          if (inmates.containsKey(userId)) {
            // Decrement the global counter and remove data from the map
            print('Before decrement - inmates map: $inmates');
            print('Before decrement - globalCounter: $globalCounter');
            globalCounter--;
            inmates.remove(userId);
            print('After decrement - inmates map: $inmates');
            print('After Decrement Counter: $globalCounter');

            // Update the counter in Firestore
            _updateCounterInFirestore();
          } else {
            // Increment the global counter, add data to the map
            print('Before increment - inmates map: $inmates');
            globalCounter++;
            inmates[userId] = {'data': 'additionalData'};
            _updateCounterInFirestore(); // Modify this as per your data structure
            print('After increment - inmates map: $inmates');
            autoMarkAttendance = true;

            // Automatically mark attendance after 2 seconds (adjust as needed)
            Timer(Duration(seconds: 2), () {
              if (mounted) {
                _markAttendance();
                autoMarkAttendance = false;
              }
            });
          }

          if (controller != null) {
            controller.pauseCamera();
            Future.delayed(Duration(milliseconds: 500), () {
              controller.resumeCamera();
            });
          }
        });
      }
    });
  }

  void _updateCounterInFirestore() async {
    try {
      // Update the counter in Firestore
      await FirebaseFirestore.instance
          .collection('scanCounter')
          .doc('counterDoc')
          .update({'counter': globalCounter});
      print('Counter updated successfully: $globalCounter');
    } catch (e) {
      print('Error updating counter in Firestore: $e');
    }
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
              content: Text(
                  'You have already generated a voucher for $mealType on $currentDateFormatted'),
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

      // Increment the global counter
      // globalCounter++;
      // _updateCounterInFirestore();

      // Add the updated counter value to the stream
      // _counterStreamController.add(globalCounter);

      // // Update the counter in Firestore
      // await FirebaseFirestore.instance
      //     .collection('scanCounter')
      //     .doc('counterDoc')
      //     .update({'counter': globalCounter});
      //     print('Counter updated successfully: $globalCounter');

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
