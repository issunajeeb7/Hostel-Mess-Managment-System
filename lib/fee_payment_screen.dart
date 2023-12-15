import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class FeePaymentScreen extends StatefulWidget {
  @override
  _FeePaymentScreenState createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Razorpay _razorpay;
  bool feeStatus = false; // Declare feeStatus at the class level
  int remainingFee = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _launchRazorpay() {
    var options = {
      'key': 'rzp_test_7mJ2dRxRtudD36', // Replace with your API key
      'amount': remainingFee *
          100, // Amount is in the smallest currency unit (like paise for INR)
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
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                feeStatus = userData['feeStatus'] ?? false;
                int totalFee = 2400;

                List<dynamic> generatedVouchersData =
                    userData['generatedVouchers'] ?? [];
                int usedVouchers = 0;

// Assuming 'generatedVouchers' is an array of strings with the format "yyyy-MM-dd-MealType"
                DateTime now = DateTime.now();
                String currentMonthYear = '${now.year}-${now.month}';
                // print("Date: $currentMonthYear");
                for (var voucherString in generatedVouchersData) {
                  // Split the voucher string into components
                  List<String> voucherComponents = voucherString.split('-');
                  print('Voucher String: $voucherString');
                  print('Voucher Components: $voucherComponents');

                  // Check if the voucher is from the current month and year
                  if (voucherComponents.length == 4 &&
                      voucherComponents[0] == now.year.toString() &&
                      voucherComponents[1] == now.month.toString()) {
                    usedVouchers++;
                    print('Added voucher: $voucherString');
                  } else {
                    print('Skipped voucher: $voucherString');
                  }
                }
                // print("Number of vouchers: $usedVouchers");
                remainingFee = totalFee - (usedVouchers * 30);

                return Column(
                  children: [
                    Text('Remaining Fee: Rs $remainingFee'),
                    SizedBox(height: 20),
                    Text('Total Vouchers generated this Month: $usedVouchers'),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Check if fee is not already paid
                if (!feeStatus) {
                  _launchRazorpay();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Fee already paid for this month.")));
                }
              },
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
