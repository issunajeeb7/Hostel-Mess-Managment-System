import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MyVouchersScreen extends StatefulWidget {
  @override
  _MyVouchersScreenState createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String currentUserId = "";
  late Future<Map<String, dynamic>> userData;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });

      print("Current User ID: $currentUserId");
      userData = getUserData();
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      print("Fetching data for user ID: $currentUserId");

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print("User data found: $userData");
        return userData;
      } else {
        print("No user document found for ID: $currentUserId");
        return {};
      }
    } catch (e) {
      print("Error fetching user data for user ID: $currentUserId, Error: $e");
      return {};
    }
  }

  Future<void> _deleteVoucher(String voucherId) async {
    try {
      await _firestore.collection('mealvouchers').doc(voucherId).delete();
      print("Voucher deleted successfully");
    } catch (e) {
      print("Error deleting voucher: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shared Vouchers'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final hostelID = snapshot.data?['hostelID'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('mealvouchers')
                    .where('hostellerId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No vouchers found'));
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var voucher = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        return VoucherListItem(
                          voucher: voucher,
                          hostelID: hostelID,
                          onDelete: () {
                            _deleteVoucher(snapshot.data!.docs[index].id);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class VoucherListItem extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final String hostelID;
  final VoidCallback onDelete;

  VoucherListItem({
    Key? key,
    required this.voucher,
    required this.hostelID,
    required this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.transparent, // Change the background color as needed
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Stack(
        children: <Widget>[
          Image.asset('assets/ticket.png'), // Replace with your local asset path
          Positioned(
            left: 120,
            top: 20,
            child: Text(
              'Hostel ID: $hostelID',
              style: GoogleFonts.nunitoSans(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          Positioned(
            left: 120,
            top: 40,
            child: Text(
              'Meal Type: ${voucher['mealType']}',
              style: GoogleFonts.nunitoSans(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          Positioned(
            left: 120,
            top: 60,
            child: Text(
              'Time: ${getTimeForMealType(voucher['mealType'])}',
              style: GoogleFonts.nunitoSans(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          Positioned(
            left: 120,
            top: 80,
            child: Text(
              'Price: ₹ 30.00',
              style: GoogleFonts.nunitoSans(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          Positioned(
            right: 145,
            bottom: 17,
            child: Text(
              voucher['isClaimed'] ? 'Claimed' : 'Listed',
              style: GoogleFonts.nunitoSans(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 255, 255, 255)), // Change the icon color
              onSelected: (String choice) {
                if (choice == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Color.fromARGB(255, 211, 10, 40)), // Change the icon color
                    title: Text('Delete', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))), // Change the text color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
