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
  Map<String, List<String>> selectedFoodOptions = {
    'Breakfast': [],
    'Lunch': [],
    'Snack': [],
    'Dinner': [],
  };

  // Function to toggle between "Add" and "Added"
  void toggleAdd(String meal, String foodOption) {
    setState(() {
      if (selectedFoodOptions[meal]!.contains(foodOption)) {
        // If the item is already added, remove it
        selectedFoodOptions[meal]!.remove(foodOption);
      } else {
        // If the item is not added, add it
        selectedFoodOptions[meal]!.add(foodOption);
      }
    });
  }

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
        'Breakfast': selectedFoodOptions['Breakfast'],
        'Lunch': selectedFoodOptions['Lunch'],
        'Snack': selectedFoodOptions['Snack'],
        'Dinner': selectedFoodOptions['Dinner'],
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

  // Function to build a food option widget
  Widget buildFoodOption(String meal, String foodOption) {
    bool isAdded = selectedFoodOptions[meal]!.contains(foodOption);

    return ListTile(
      title: Text(foodOption),
      trailing: ElevatedButton(
        onPressed: () {
          toggleAdd(meal, foodOption);
        },
        child: Text(isAdded ? 'Added' : 'Add'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (String meal in selectedFoodOptions.keys)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Column(
                      children: [
                        for (String foodOption in [
                          'Food 1',
                          'Food 2',
                          'Food 3'
                        ])
                          buildFoodOption(meal, foodOption),
                      ],
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ElevatedButton(
                onPressed: () {
                  createPoll();
                },
                child: const Text('Create Poll'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
