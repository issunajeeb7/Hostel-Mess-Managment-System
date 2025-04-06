import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ClaimedVoucher extends StatefulWidget {
  @override
  _ClaimedVoucherState createState() => _ClaimedVoucherState();
}

class _ClaimedVoucherState extends State<ClaimedVoucher> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isQRCodeDialogOpen = false;
  String selectedVoucherId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed Vouchers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('transactions')
            .where('nonHostellerID', isEqualTo: currentUserId)
            .where('isRedeemed', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBC32C)),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No claimed vouchers found'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                return _buildVoucherCard(snapshot.data!.docs[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getVoucherDate(String? voucherID) async {
    if (voucherID != null) {
      var mealVoucherSnapshot =
          await _firestore.collection('mealvouchers').doc(voucherID).get();
      var mealVoucherData = mealVoucherSnapshot.data() as Map<String, dynamic>;
      return mealVoucherData['date'] as String?;
    }

    return null;
  }

  Widget _buildVoucherCard(DocumentSnapshot document) {
    var transactionData = document.data() as Map<String, dynamic>;
    String voucherId = transactionData['voucherID'] ?? 'Unknown Voucher';
    String mealType = 'Loading...';

    return FutureBuilder(
      future: _getMealType(transactionData['voucherID']),
      builder: (context, mealTypeSnapshot) {
        if (mealTypeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBC32C)),
            ),
          );
        }

        mealType = mealTypeSnapshot.data as String? ?? 'Unknown Meal Type';

        String mealTypeImage = 'assets/breakfast.png';
        switch (mealType) {
          case 'Breakfast':
            mealTypeImage = 'assets/breakfast.png';
            break;
          case 'Lunch':
            mealTypeImage = 'assets/lunch.png';
            break;
          case 'Snacks':
            mealTypeImage = 'assets/snack.png';
            break;
          case 'Dinner':
            mealTypeImage = 'assets/dinner.png';
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 30.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFBC32C),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 6),
              ),
            ],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: InkWell(
            onTap: () {
              _showQRCodeDialog(voucherId);
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0, left: 10.0),
                    child: Image.asset(
                      mealTypeImage,
                      width: 60,
                      height: 60,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('$mealType',
                            style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.w800)),
                        FutureBuilder(
                          future: _getVoucherDate(transactionData['voucherID']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Date: Loading...',
                                  style: GoogleFonts.nunitoSans());
                            }
                            String voucherDate =
                                snapshot.data as String? ?? 'Unknown Date';
                            return Text('Date: $voucherDate',
                                style: GoogleFonts.nunitoSans());
                          },
                        ),
                        FutureBuilder(
                          future: _getMealTime(transactionData['voucherID']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Meal Time: Loading...',
                                  style: GoogleFonts.nunitoSans());
                            }
                            String mealTime =
                                snapshot.data as String? ?? 'Unknown Meal Time';
                            return Text('Meal Time: $mealTime',
                                style: GoogleFonts.nunitoSans());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getMealType(String? voucherID) async {
    if (voucherID != null) {
      var mealVoucherSnapshot =
          await _firestore.collection('mealvouchers').doc(voucherID).get();
      var mealVoucherData = mealVoucherSnapshot.data() as Map<String, dynamic>;
      return mealVoucherData['mealType'] as String?;
    }

    return null;
  }

  Future<String?> _getMealTime(String? voucherID) async {
    if (voucherID != null) {
      var mealVoucherSnapshot =
          await _firestore.collection('mealvouchers').doc(voucherID).get();
      var mealVoucherData = mealVoucherSnapshot.data() as Map<String, dynamic>;
      return getMealTime(mealVoucherData['mealType'] as String?);
    }

    return null;
  }

  String getMealTime(String? mealType) {
    if (mealType != null) {
      switch (mealType) {
        case 'Breakfast':
          return '7:00 - 9:00 AM';
        case 'Lunch':
          return '12:00 - 2:00 PM';
        case 'Snack':
          return '3:00 - 5:00 PM';
        case 'Dinner':
          return '7:00 - 9:00 PM';
        default:
          return 'Unknown';
      }
    }

    return 'Unknown';
  }

  void _showQRCodeDialog(String voucherId) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          width: 350,
          height: 450,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: 'VoucherId:$voucherId',
                version: QrVersions.auto,
                size: 250,
                gapless: false,
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan the above QR code at the mess',
                style: TextStyle(fontWeight: FontWeight.w200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
