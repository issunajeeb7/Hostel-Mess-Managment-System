import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoucherMarketplaceScreen extends StatefulWidget {
  @override
  _VoucherMarketplaceScreenState createState() => _VoucherMarketplaceScreenState();
}

class _VoucherMarketplaceScreenState extends State<VoucherMarketplaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late Razorpay _razorpay;
  String? _selectedVoucherId;

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

  void _launchRazorpay(String voucherId) {
    _selectedVoucherId = voucherId; // Store the selected voucher ID
    var options = {
      'key': 'rzp_test_7mJ2dRxRtudD36', // Replace with your API key
      'amount': 1000, // Amount is in the smallest currency unit (like paise for INR)
      'name': 'Mess Admin',
      'description': 'Payment for Meal Voucher',
      'prefill': {'contact': '1234567890', 'email': 'test@example.com'},
      // Add more options here
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser != null ? currentUser.uid : 'unknown';

      // Check if _selectedVoucherId is not null
      if (_selectedVoucherId != null) {
        // Update Firestore on successful payment
        await _firestore.collection('transactions').add({
          'isRedeemed': false,
          'nonHostellerID': userId,
          'purchaseDate': dateFormat.format(DateTime.now()),
          'voucherID': _selectedVoucherId, // Use the stored voucher ID
        });

        await _firestore.collection('mealvouchers').doc(_selectedVoucherId).update({
          'isClaimed': true,
        });

        // Reset _selectedVoucherId
        _selectedVoucherId = null;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClaimedVoucher()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SUCCESS: ${response.paymentId}")));
    } catch (e) {
      debugPrint('Error processing payment success: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ERROR: ${response.code.toString()} - ${response.message}")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EXTERNAL WALLET: ${response.walletName}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Marketplace'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('mealvouchers')
          .where('isClaimed', isEqualTo: false)
          .where('date', isEqualTo: selectedDate)
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No available vouchers for $selectedDate'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var voucherData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String voucherId = snapshot.data!.docs[index].id;

              return ListTile(
                title: Text('${voucherData['mealType']}'),
                subtitle: Text('Date: ${voucherData['date']}'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Purchase'),
                        content: const Text('Do you want to buy this voucher?'),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('Pay Now'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              _launchRazorpay(voucherId);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ClaimedVoucher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed Voucher'),
      ),
      body: const Center(
        child: Text('Voucher successfully claimed!'),
      ),
    );
  }
}
