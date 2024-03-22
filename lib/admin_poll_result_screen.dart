import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPollResultScreen extends StatefulWidget {
  const AdminPollResultScreen({Key? key}) : super(key: key);

  @override
  State<AdminPollResultScreen> createState() => _AdminPollResultScreenState();
}

class _AdminPollResultScreenState extends State<AdminPollResultScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, Map<String, int>>> _pollResultsStream() {
    return _firestore.collection('votes').snapshots().map((snapshot) {
      Map<String, Map<String, int>> pollResults = {};
      for (var document in snapshot.docs) {
        Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            pollResults[key] = Map<String, int>.from(value);
          });
        }
      }
      return pollResults;
    });
  }

  Widget _buildPollResults(Map<String, int> votesCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: votesCount.entries.map((entry) {
        double votePercentage = votesCount[entry.key]! / votesCount.values.fold(0, (previousValue, element) => previousValue + element);
        if (votePercentage.isNaN) {
          votePercentage = 0.0; // Set votePercentage to 0 if it's NaN
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
          child: Container(
            height: 30, // Set the desired height here
            decoration: BoxDecoration(
              color: const Color.fromARGB(60, 251, 195, 44),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * votePercentage,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 251, 196, 44),
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            entry.key,
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${(votePercentage * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Poll Results',style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),),
        forceMaterialTransparency: true,
        
      ),
      body: StreamBuilder<Map<String, Map<String, int>>>(
        stream: _pollResultsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return SingleChildScrollView(
            child: Column(
              children: snapshot.data!.entries.map((meal) {
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(40, 251, 195, 44),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 251, 196, 44),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              child: Image.asset(
                                'assets/${meal.key.toLowerCase()}.png', // Use your image path here
                                fit: BoxFit.cover, // Adjust the fit as needed
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              meal.key,
                              style: GoogleFonts.nunitoSans(
                                color: const Color.fromARGB(255, 0, 0, 0), // Change to the desired text color
                                fontWeight: FontWeight.normal,
                                fontSize: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildPollResults(meal.value),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
