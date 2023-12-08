import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'generated_vouchers_screen.dart';

class ShareMealScreen extends StatefulWidget {
  @override
  _ShareMealScreenState createState() => _ShareMealScreenState();
}

class _ShareMealScreenState extends State<ShareMealScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  String selectedMealType = 'Breakfast'; // Default value

  Future<void> shareMeal() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Voucher Generation'),
          content: Text(
              'Are you sure you want to generate a meal voucher for ${DateFormat('yyyy-MM-dd').format(selectedDate)} - $selectedMealType?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User clicked No
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User clicked Yes
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // User confirmed, proceed with meal voucher generation
      await _firestore.collection('mealvouchers').add({
        'hostellerId': FirebaseAuth.instance.currentUser!.uid,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'mealType': selectedMealType,
        'isClaimed': false,
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Meal voucher generated for ${DateFormat('yyyy-MM-dd').format(selectedDate)} - $selectedMealType'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share a Meal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // DatePicker to select the date
            ElevatedButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null && pickedDate != selectedDate) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(
                  'Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
            ),
            const SizedBox(height: 16.0),

            // Scrollable Row with Meal Selection
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  mealTypeButton('Breakfast', Icons.free_breakfast),
                  mealTypeButton('Lunch', Icons.restaurant),
                  mealTypeButton('Snack', Icons.local_dining),
                  mealTypeButton('Dinner', Icons.restaurant_menu),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Button to share the meal
            ElevatedButton(
              onPressed: shareMeal,
              child: const Text('Share Meal'),
            ),

            // Button to view shared meals
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyVouchersScreen()),
                ); // Navigate to a screen that shows the hosteller's shared meals
              },
              child: const Text('View My Shared Meals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget mealTypeButton(String mealType, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          selectedMealType = mealType;
        });
      },
      style: ElevatedButton.styleFrom(
        primary: mealType == selectedMealType ? Colors.blue : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      icon: Icon(icon),
      label: Text(mealType),
    );
  }
}
