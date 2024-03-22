import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_poll_result_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> pollOptionsStream =
        FirebaseFirestore.instance.collection('pollOptions').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Current Diners'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 238,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EA),
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Current Diners',
                        style: GoogleFonts.nunitoSans(
                            fontSize: 16.0, fontWeight: FontWeight.w400),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 17.0), // Add top padding here
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('scanCounter')
                              .doc('counterDoc')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              int counterValue = snapshot.data!['counter'];
                              return Text(
                                '$counterValue/120',
                                style: GoogleFonts.nunitoSans(
                                    fontSize: 25.0,
                                    fontWeight: FontWeight.bold),
                              );
                            } else {
                              return const Text('Counter data not available');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('scanCounter')
                    .doc('counterDoc')
                    .update({'counter': 0});
              },
              child: Text('Reset Counter'),
            ),
            const SizedBox(height: 10), // Add some space
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminPollResultScreen()),
                );
              },
              child: Text('View Poll Results'),
            ),
          ],
        ),
      ),
    );
  }
}
