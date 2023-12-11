import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ClaimedVoucher extends StatefulWidget {
  @override
  _ClaimedVoucherState createState() => _ClaimedVoucherState();
}

class _ClaimedVoucherState extends State<ClaimedVoucher> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed Vouchers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('transactions')
            .where('nonHostellerID', isEqualTo: currentUserId)
            .where('isRedeemed', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No claimed vouchers found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _buildVoucherCard(snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(DocumentSnapshot document) {
    var transactionData = document.data() as Map<String, dynamic>;
    String voucherId = transactionData['voucherID'] ?? 'Unknown Voucher';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            QrImageView(
              data:'VoucherId:$voucherId',
              version: QrVersions.auto,
              size: 200,
              gapless: false,
            ),
            SizedBox(height: 10),
            FutureBuilder(
              future: _getMealType(transactionData['voucherID']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Meal Type: Loading...'); // Loading indicator or placeholder
                }

                String mealType = snapshot.data as String? ?? 'Unknown Meal Type';

                return Text('Meal Type: $mealType');
              },
            ),
            FutureBuilder(
              future: _getMealTime(transactionData['voucherID']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Meal Time: Loading...'); // Loading indicator or placeholder
                }

                String mealTime = snapshot.data as String? ?? 'Unknown Meal Time';

                return Text('Meal Time: $mealTime');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getMealType(String? voucherID) async {
    if (voucherID != null) {
      var mealVoucherSnapshot = await _firestore.collection('mealvouchers').doc(voucherID).get();
      var mealVoucherData = mealVoucherSnapshot.data() as Map<String, dynamic>;
      return mealVoucherData['mealType'] as String?;
    }

    return null;
  }

  Future<String?> _getMealTime(String? voucherID) async {
    if (voucherID != null) {
      var mealVoucherSnapshot = await _firestore.collection('mealvouchers').doc(voucherID).get();
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
          return '3:00 - 5:00  PM';
        case 'Dinner':
          return '7:00 - 9:00 PM';
        default:
          return 'Unknown';
      }
    }

    return 'Unknown';
  }
}
