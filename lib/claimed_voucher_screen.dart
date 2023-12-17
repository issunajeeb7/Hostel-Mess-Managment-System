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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No claimed vouchers found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final transactionData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return VoucherCard(
                voucherId: transactionData['voucherID'],
                firestore: _firestore,
              );
            },
          );
        },
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  final String? voucherId;
  final FirebaseFirestore firestore;

  const VoucherCard({
    Key? key,
    required this.voucherId,
    required this.firestore,
  }) : super(key: key);

  Future<void> _showVoucherDetails(BuildContext context) async {
    print('checking');
    final voucherDetails = await _getVoucherDetails(voucherId);
    if (voucherDetails != null) {
      _buildVoucherDetailsDialog(context, voucherDetails);
    }
  }

  void _buildVoucherDetailsDialog(
      BuildContext context, Map<String, dynamic> voucherDetails) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Text('Voucher Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Date: ${voucherDetails['date']}'),
              Text('Meal Type: ${voucherDetails['mealType']}'),
              Text('Time: ${getMealTime(voucherDetails['mealType'])}'),
              // Text('Price: ${voucherDetails['price']}'),
              QrImageView(
                data: voucherId ?? '', // Display the voucherID as QR code
                version: QrVersions.auto,
                size: 200,
                gapless: false,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showVoucherDetails(context),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.transparent, // Change the background color as needed
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            // BoxShadow(
            //   color: Colors.grey.withOpacity(0.5),
            //   spreadRadius: 2,
            //   blurRadius: 5,
            //   offset: const Offset(0, 3),
            // ),
          ],
        ),
        child: Stack(
          children: [
            Image.asset('assets/ticket.png',
                width: double.infinity, height: 150, fit: BoxFit.cover),
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('Voucher Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  FutureBuilder(
                    future: _getVoucherDetails(voucherId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasData) {
                        final voucherDetails =
                            snapshot.data as Map<String, dynamic>;
                        final date = voucherDetails['date'];
                        final mealType = voucherDetails['mealType'];
                        final time = getMealTime(mealType);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Positioned(
                                top: 10,
                                left: 120,
                                child: Text(
                                  'Date: $date',
                                  style: GoogleFonts.nunitoSans(
                                      color: Colors.white),
                                )),
                            Text(
                              'Meal Type: $mealType',
                              style: GoogleFonts.nunitoSans(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            Text(
                              'Time: $time',
                              style: GoogleFonts.nunitoSans(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            Text(
                              'Price: ${voucherDetails['price']}',
                              style: GoogleFonts.nunitoSans(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ],
                        );
                      }
                      return const Text('Error loading voucher details');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getVoucherDetails(String? voucherId) async {
    if (voucherId != null) {
      final voucherDetailsSnapshot =
          await firestore.collection('mealvouchers').doc(voucherId).get();
      return voucherDetailsSnapshot.data() as Map<String, dynamic>?;
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
}
