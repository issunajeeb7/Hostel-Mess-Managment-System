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
  TextEditingController searchController =
      TextEditingController(); // Controller for search input
  String filter = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        filter = searchController
            .text; // Update the filter whenever the input changes
      });
    });
  }

  @override
  void dispose() {
    searchController
        .dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        title:  Text('Payment Status' ,style: GoogleFonts.nunitoSans(
          fontSize: 20.0,
          fontWeight:FontWeight.w500
        ),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 365.0,
              height: 45.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                color: const Color.fromARGB(20, 251, 196, 44),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center, // Add this line
                children: [
                  const SizedBox(width: 20.0), // Padding left for the icon
                  Image.asset(
                    'assets/search.png',
                    width: 24.0, // Icon width
                    height: 24.0, // Icon height
                  ),
                  const SizedBox(
                      width: 10.0), // Space between the icon and the text field
                  Expanded(
                    child: TextFormField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.nunitoSans(
                          color: const Color.fromARGB(255, 177, 177, 177),
                          fontSize: 17.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical:
                                8.0), // Adjust vertical padding as needed
                      ),
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("No data available."));
                }

                List<DocumentSnapshot> userDocs = snapshot.data!.docs;
                if (filter.isNotEmpty) {
                  userDocs = userDocs.where((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    // Combine the first name and last name to create the full name.
                    String fullName =
                        "${userData['firstName']} ${userData['lastName']}";
                    // Get the hostel ID from the user data.
                    String hostelID = userData['hostelID'] ?? '';

                    // Check if the filter is contained in either the full name or the hostel ID.
                    // The search is case-insensitive.
                    return fullName
                            .toLowerCase()
                            .contains(filter.toLowerCase()) ||
                        hostelID.toLowerCase().contains(filter.toLowerCase());
                  }).toList();
                }

                return userDocs.isEmpty // Check if no results found

                    ? SingleChildScrollView(
                        // physics: const NeverScrollableScrollPhysics(),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 100,
                              ),
                              Image.asset(
                                'assets/noresults.jpg', // Change to your image path
                                width:
                                    300, // Set the width as per your requirement
                                height:
                                    300, // Set the height as per your requirement
                              ),
                              Text(
                                'OOPS!',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 40,
                                  color: const Color(0xFFFBC32C),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'No results found, try searching again.',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 16,
                                  color: const Color.fromARGB(255, 63, 63, 63),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            userDocs.length + 1, // Add one for the headings row
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // This is the headings row
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(45, 251, 196, 44),
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
                                          'Name',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunitoSans(
                                              fontWeight: FontWeight.w500,fontSize: 18),
                                              
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'ID',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunitoSans(
                                              fontWeight: FontWeight.w500,fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Payment Status',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunitoSans(
                                              fontWeight: FontWeight.w500,fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Now handle the user data
                          var userData = userDocs[index - 1].data()
                              as Map<String, dynamic>;
                          if (userData['role'] != 'Hosteller') {
                            return Container(); // Skip non-hostellers
                          }

                          String fullName =
                              "${userData['firstName']} ${userData['lastName']}";
                          String hostelID = userData['hostelID'];
                          String userId = userDocs[index - 1].id;

                          // Get the current year and month
                          int currentYear = currentDate.year;
                          int currentMonth = currentDate.month;

                          String currentYearMonth =
                              '$currentYear-${currentMonth.toString().padLeft(2, '0')}';
                          print('Date: $currentYearMonth');

                          return FutureBuilder<DocumentSnapshot?>(
                            future: _firestore
                                .collection('feePayment')
                                .where('userId', isEqualTo: userId)
                                .get()
                                .then((querySnapshot) {
                              if (querySnapshot.docs.isNotEmpty) {
                                for (var doc in querySnapshot.docs) {
                                  var feePaymentData =
                                      doc.data() as Map<String, dynamic>;
                                  String feePaymentDate =
                                      feePaymentData['date'] as String;

                                  String yearMonthOnly =
                                      feePaymentDate.substring(0, 7);

                                  if (yearMonthOnly == currentYearMonth) {
                                    return doc;
                                  }
                                }
                              }
                              return null;
                            }),
                            builder: (context, paymentSnapshot) {
                              if (paymentSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container();
                              }

                              bool isPaid = paymentSnapshot.hasData;

                              if (paymentSnapshot.data == null) {
                                isPaid = false;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
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
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
