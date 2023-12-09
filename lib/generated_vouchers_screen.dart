import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Print the userId being used to fetch the user document.
      print("Fetching data for user ID: $currentUserId");

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();

      // Check if the userDoc exists and print the data.
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print("User data found: $userData");
        return userData;
      } else {
        // If the userDoc doesn't exist, return an empty map.
        print("No user document found for ID: $currentUserId");
        return {};
      }
    } catch (e) {
      // If there's an error during the fetch, print it and return an empty map.
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
      // Handle error as needed
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
            // If we run into an error, display it on the screen
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

  const VoucherListItem({
    Key? key,
    required this.voucher,
    required this.hostelID,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${voucher['mealType']} on ${voucher['date']}'),
      subtitle: Text('Hostel ID: $hostelID'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          voucher['isClaimed']
              ? const Icon(Icons.check, color: Colors.green)
              : const Icon(Icons.close, color: Colors.red),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
