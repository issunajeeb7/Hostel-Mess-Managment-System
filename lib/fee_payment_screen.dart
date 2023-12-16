import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class FeePaymentScreen extends StatefulWidget {
  @override
  _FeePaymentScreenState createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Razorpay _razorpay;
  bool feeStatus = false;
  int remainingFee = 0;
  int totalVouchers = 0;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  int usedVouchers = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _checkAndUpdateFeeStatus();
  }

  Future<void> _checkAndUpdateFeeStatus() async {
    try {
      // Get the current date
      DateTime currentDate = DateTime.now();
      String currentDateString = _dateFormat.format(currentDate);

      // Check if it's the beginning of the month (day 1)
      if (currentDate.day == 1) {
        // Set feeStatus to false for all users
        QuerySnapshot usersSnapshot =
            await _firestore.collection('users').get();
        for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
          await userDoc.reference.update({'feeStatus': false});
        }

        // Log that feeStatus has been updated
        print('FeeStatus updated to false for all users on $currentDateString');
      }

      // Fetch user data to calculate remainingFee and totalVouchers
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(currentUser.uid).get();

        // Calculate remainingFee based on your logic (replace this with your logic)
        int totalFee = 2400;
        List<dynamic> generatedVouchersData =
            userData['generatedVouchers'] ?? [];
        usedVouchers = 0;

        DateTime now = DateTime.now();
        String currentMonthYear = '${now.year}-${now.month}';
        for (var voucherString in generatedVouchersData) {
          List<String> voucherComponents = voucherString.split('-');
          if (voucherComponents.length == 4 &&
              voucherComponents[0] == now.year.toString() &&
              voucherComponents[1] == now.month.toString()) {
            usedVouchers++;
          }
        }
        setState(() {
          remainingFee = totalFee - (usedVouchers * 30);
        });

        // Update feeStatus based on the backend value
        feeStatus = userData['feeStatus'] ?? false;

        print('Number: $usedVouchers');
      }
    } catch (e) {
      print('Error checking and updating feeStatus: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _launchRazorpay() {
    var options = {
      'key': 'rzp_test_7mJ2dRxRtudD36',
      'amount': remainingFee * 100,
      'name': 'Hostel Fee Payment',
      'description': 'Monthly Hostel Fee',
      'prefill': {'contact': '1234567890', 'email': 'test@example.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      User? currentUser = _auth.currentUser;
      String userId = currentUser != null ? currentUser.uid : 'unknown';

      // Update Firestore on successful payment
      await _firestore.collection('users').doc(userId).update({
        'feeStatus': true,
      });

      // Update feeStatus in the local state
      setState(() {
        feeStatus = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Success: ${response.paymentId}")));
    } catch (e) {
      debugPrint('Error processing payment success: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Payment Error: ${response.code.toString()} - ${response.message}")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet: ${response.walletName}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pending Fees',
              style: GoogleFonts.nunitoSans(
                fontSize: 25.0,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 70),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFFFF9EA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '₹$remainingFee',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Vouchers: $usedVouchers',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 200),
            ElevatedButton(
              onPressed: _isButtonEnabled()
                  ? feeStatus
                      ? null
                      : _launchRazorpay
                  : null,
              style: ElevatedButton.styleFrom(
                primary: _isButtonEnabled()
                    ? feeStatus
                        ? Colors.grey
                        : const Color(0xFFFBC32C)
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                shadowColor: Colors.black.withOpacity(1.0),
                elevation: 4,
                minimumSize: const Size(325, 55),
              ),
              child: Text(
                feeStatus ? 'Already Paid' : 'Pay Now',
                style: GoogleFonts.nunitoSans(
                  fontSize: 28,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isButtonEnabled() {
    DateTime now = DateTime.now();
    return now.day >= 28 && now.day <= 30;
  }
}
