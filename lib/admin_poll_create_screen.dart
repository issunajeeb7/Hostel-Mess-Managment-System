import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dropdown/flutter_dropdown.dart';

class CreatePollScreen extends StatefulWidget {
  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables to store selected food items
  String selectedBreakfast = "";
  String selectedLunch = "";
  String selectedSnack = "";
  String selectedDinner = "";

  // Function to send poll options to Firestore
  Future<void> createPoll() async {
    try {
      // Get the current date in yyyy-mm-dd format
      String currentDate =
          DateTime.now().toLocal().toIso8601String().split('T')[0];

      // Firestore collection reference
      CollectionReference pollOptions = _firestore.collection('pollOptions');

      // Add poll options to Firestore
      await pollOptions.add({
        'Date': currentDate,
        'Breakfast': selectedBreakfast,
        'Lunch': selectedLunch,
        'Snack': selectedSnack,
        'Dinner': selectedDinner,
      });

      // Display a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poll created successfully!'),
        ),
      );
    } catch (e) {
      // Handle errors
      print('Error creating poll: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error creating poll. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dropdown for Breakfast
            DropDown(
              items: ['Food 1', 'Food 2', 'Food 3'], // Add your food items
              hint: const Text('Select Breakfast'),
              onChanged: (value) {
                setState(() {
                  selectedBreakfast = value ?? "";
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Dropdown for Lunch
            DropDown(
              items: ['Food 1', 'Food 2', 'Food 3'], // Add your food items
              hint: const Text('Select Lunch'),
              onChanged: (value) {
                setState(() {
                  selectedLunch = value ?? "";
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Dropdown for Snack
            DropDown(
              items: ['Food 1', 'Food 2', 'Food 3'], // Add your food items
              hint: const Text('Select Snack'),
              onChanged: (value) {
                setState(() {
                  selectedSnack = value ?? "";
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Dropdown for Dinner
            DropDown(
              items: ['Food 1', 'Food 2', 'Food 3'], // Add your food items
              hint: const Text('Select Dinner'),
              onChanged: (value) {
                setState(() {
                  selectedDinner = value ?? "";
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Button to create poll
            ElevatedButton(
              onPressed: () {
                createPoll();
              },
              child: const Text('Create Poll'),
            ),
          ],
        ),
      ),
    );
  }
}
