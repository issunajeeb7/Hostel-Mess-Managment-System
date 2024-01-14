import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminFeeStatusScreen extends StatefulWidget {
  const AdminFeeStatusScreen({super.key});

  @override
  _AdminFeeStatusScreenState createState() => _AdminFeeStatusScreenState();
}

class _AdminFeeStatusScreenState extends State<AdminFeeStatusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateTime currentDate = DateTime.now(); // Get the current date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .snapshots(), // Listen to 'users' collection
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data available."));
          }

          List<DocumentSnapshot> userDocs =
              snapshot.data!.docs; // Define userDocs here

          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Name',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'ID',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Payment Status',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 10), // Spacing between header and list
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var userData =
                        userDocs[index].data() as Map<String, dynamic>;
                    if (userData['role'] != 'Hosteller') {
                      return Container(); // Skip non-hostellers
                    }

                    String fullName =
                        "${userData['firstName']} ${userData['lastName']}";
                    String hostelID = userData['hostelID'];
                    String userId = userDocs[index].id;

                    // Get the current year and month
                    int currentYear = currentDate.year;
                    int currentMonth = currentDate.month;

                    String currentYearMonth =
                        '$currentYear-${currentMonth.toString().padLeft(2, '0')}';
                    print('Date: $currentYearMonth');
                    // print('Checking date range: $currentYearMonth-01 to $currentYearMonth-32');

                    print('Querying for userId: $userId');
                    return FutureBuilder<DocumentSnapshot?>(
                      future: _firestore
                          .collection('feePayment')
                          .where('userId', isEqualTo: userId)
                          .get()
                          .then((querySnapshot) {
                        if (querySnapshot.docs.isNotEmpty) {
                          // Iterate through the documents to find a matching date
                          for (var doc in querySnapshot.docs) {
                            var feePaymentData =
                                doc.data() as Map<String, dynamic>;
                            String feePaymentDate =
                                feePaymentData['date'] as String;

                            // Parse the date string to remove the day part
                            String yearMonthOnly = feePaymentDate.substring(
                                0, 7); // Extract 'yyyy-MM'

                            // Compare the extracted year and month with currentYearMonth
                            if (yearMonthOnly == currentYearMonth) {
                              // Payment for the current year and month found
                              return doc; // Return the matching document
                            }
                          }
                        }

                        // Return null when there is no matching payment
                        return null;
                      }),
                      builder: (context, paymentSnapshot) {
                        if (paymentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(); // Return an empty container while waiting
                        }

                        bool isPaid = paymentSnapshot.hasData;

                        // Handle the case when paymentSnapshot.data is null
                        if (paymentSnapshot.data == null) {
                          // No matching payment record, set isPaid to false
                          isPaid = false;
                        }

                        return Padding(
                          // Wrap the ListTile with Padding to add vertical space
                          padding: const EdgeInsets.symmetric(
                              vertical: 3), // Add vertical padding
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16), // Add margin
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        fullName,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        hostelID,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        isPaid ? "Paid" : "Pending",
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: isPaid
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: userDocs.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
