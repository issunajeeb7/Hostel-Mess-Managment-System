import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeeStatusScreen extends StatefulWidget {
  @override
  _AdminFeeStatusScreenState createState() => _AdminFeeStatusScreenState();
}

class _AdminFeeStatusScreenState extends State<AdminFeeStatusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('feePayment').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text("No data available."));
          }

          List<DocumentSnapshot> feePaymentDocs = snapshot.data!.docs;
          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF9EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(child: Text('Name')),
                            Expanded(child: Text('ID')),
                            Expanded(child: Text('Payment Status')),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Spacing between header and list
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var feePaymentData = feePaymentDocs[index].data() as Map<String, dynamic>;
                    if (feePaymentData['userId'] == null || feePaymentData['userId'].isEmpty) {
                      return Container(); // Return an empty container or some other placeholder
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(feePaymentData['userId']).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(); // Optionally, show a placeholder or a loader
                        }

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          String fullName = "${userData['firstName']} ${userData['lastName']}";
                          String hostelID = userData['hostelID'];
                          bool isPaid = feePaymentData['status'];
                          return Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF9EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(fullName, overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Text(hostelID, overflow: TextOverflow.ellipsis)),
                                  Expanded(
                                    child: Text(
                                      isPaid ? "Paid" : "Pending",
                                      style: TextStyle(
                                        color: isPaid ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Container(); // Optionally, handle the case when user data is not available
                        }
                      },
                    );
                  },
                  childCount: feePaymentDocs.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


