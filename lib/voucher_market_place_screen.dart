import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'claimed_voucher_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class VoucherMarketplaceScreen extends StatefulWidget {
  @override
  _VoucherMarketplaceScreenState createState() =>
      _VoucherMarketplaceScreenState();
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
      'amount':
          1000, // Amount is in the smallest currency unit (like paise for INR)
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

        await _firestore
            .collection('mealvouchers')
            .doc(_selectedVoucherId)
            .update({
          'isClaimed': true,
        });

        // Reset _selectedVoucherId
        _selectedVoucherId = null;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClaimedVoucher()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SUCCESS: ${response.paymentId}")));
    } catch (e) {
      debugPrint('Error processing payment success: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("ERROR: ${response.code.toString()} - ${response.message}")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("EXTERNAL WALLET: ${response.walletName}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Marketplace'),
        actions: [
          // Button to log out
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Add your logout logic here
              // For example, sign out the user and navigate to the login screen
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('mealvouchers')
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
            return Center(
                child: Text('No available vouchers for $selectedDate'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var voucherData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String voucherId = snapshot.data!.docs[index].id;

              return GestureDetector(
                onTap: () {
                  _showPurchaseConfirmationDialog(voucherId);
                },
                child: VoucherListItem(
                  voucher: voucherData,
                  voucherId: voucherId,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPurchaseConfirmationDialog(String voucherId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Purchase',
          ),
          content: const Text('Do you want to buy this voucher?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Buy Now'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _launchRazorpay(voucherId);
              },
            ),
          ],
        );
      },
    );
  }
}

class VoucherListItem extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final String voucherId;

  VoucherListItem({
    Key? key,
    required this.voucher,
    required this.voucherId,
  }) : super(key: key);

  String getTimeForMealType(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return '7:00-9:00 AM';
      case 'Lunch':
        return '12:00-2:00 PM';
      case 'Snack':
        return '3:00-5:00 PM';
      case 'Dinner':
        return '7:00-9:00 PM';
      default:
        return '';
    }
  }

  Future<String?> getHostelID(String hostellerID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(hostellerID)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['hostelID'];
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getHostelID(voucher['hostellerId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(); // Handle the error or empty case
        }

        String hostelID = snapshot.data!;

        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.transparent, // Change the background color as needed
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Stack(
            children: <Widget>[
              Image.asset(
                  'assets/ticket.png'), // Replace with your local asset path
              Positioned(
                left: 120,
                top: 10,
                child: Text(
                  'Hostel ID: $hostelID',
                  style: GoogleFonts.nunitoSans(color: Colors.white),
                ),
              ),
              Positioned(
                left: 120,
                top: 30,
                child: Text(
                  'Meal Type: ${voucher['mealType']}',
                  style: GoogleFonts.nunitoSans(color: Colors.white),
                ),
              ),
              Positioned(
                left: 120,
                top: 50,
                child: Text(
                  'Time: ${getTimeForMealType(voucher['mealType'])}',
                  style: GoogleFonts.nunitoSans(color: Colors.white),
                ),
              ),
              Positioned(
                left: 120,
                top: 70,
                child: Text(
                  'Price: Rs 10',
                  style: GoogleFonts.nunitoSans(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
