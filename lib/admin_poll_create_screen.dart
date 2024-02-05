import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePollScreen extends StatefulWidget {
  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<String>> selectedFoodOptions = {
    'Breakfast': [],
    'Lunch': [],
    'Snack': [],
    'Dinner': [],
  };

  Map<String, TextEditingController> userFoodOptionControllers = {
    'Breakfast': TextEditingController(),
    'Lunch': TextEditingController(),
    'Snack': TextEditingController(),
    'Dinner': TextEditingController(),
  };

  Map<String, Set<String>> additionalFoodOptions = {
    'Breakfast': {},
    'Lunch': {},
    'Snack': {},
    'Dinner': {},
  };

  bool isCreatePollButtonEnabled = false;

  void toggleAdd(String meal, String foodOption) {
    setState(() {
      if (userFoodOptionControllers[meal]!.text.isNotEmpty) {
        // For user-provided options, add the new option without clearing existing ones
        selectedFoodOptions[meal]!.add(userFoodOptionControllers[meal]!.text);
        additionalFoodOptions[meal]!.add(userFoodOptionControllers[meal]!.text);
      } else {
        // For predefined options, toggle the selection
        if (selectedFoodOptions[meal]!.contains(foodOption)) {
          selectedFoodOptions[meal]!.remove(foodOption);
        } else {
          selectedFoodOptions[meal]!.add(foodOption);
        }
      }

      // Update the button status
      isCreatePollButtonEnabled = isButtonEnabled();
    });
  }

  bool isButtonEnabled() {
    for (String meal in selectedFoodOptions.keys) {
      if (selectedFoodOptions[meal]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> createPoll() async {
    try {
      // Check if at least one option is selected for each meal
      for (String meal in selectedFoodOptions.keys) {
        if (selectedFoodOptions[meal]!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please add at least one item in each meal.'),
            ),
          );
          return;
        }
      }

      String currentDate =
          DateTime.now().toLocal().toIso8601String().split('T')[0];

      CollectionReference pollOptions = _firestore.collection('pollOptions');

      await pollOptions.add({
        'Date': currentDate,
        'Breakfast': selectedFoodOptions['Breakfast'],
        'Lunch': selectedFoodOptions['Lunch'],
        'Snack': selectedFoodOptions['Snack'],
        'Dinner': selectedFoodOptions['Dinner'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poll created successfully!'),
        ),
      );

      // Clear user-provided food options after creating poll
      for (var controller in userFoodOptionControllers.values) {
        controller.clear();
      }

      // Reset selectedFoodOptions
      selectedFoodOptions = {
        'Breakfast': [],
        'Lunch': [],
        'Snack': [],
        'Dinner': [],
      };

      // Update the button status
      isCreatePollButtonEnabled = isButtonEnabled();
    } catch (e) {
      print('Error creating poll: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating poll. Please try again.'),
        ),
      );
    }
  }

  Widget buildFoodOption(String meal, String foodOption) {
    bool isAdded = selectedFoodOptions[meal]!.contains(foodOption);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 7.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                foodOption,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Container(
            height: 35.0, // Adjusted height
            child: ElevatedButton(
              onPressed: () {
                toggleAdd(meal, foodOption);
              },
              style: ElevatedButton.styleFrom(
                primary: isAdded
                    ? Color.fromARGB(20, 252, 195, 44)
                    : Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(isAdded ? '-' : '+'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserFoodOption(String meal) {
    TextEditingController controller = userFoodOptionControllers[meal]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 35.0,
              margin: const EdgeInsets.only(right: 8.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 7.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                alignment: Alignment.centerLeft,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add Item...', // Placeholder text
                    hintStyle: TextStyle(color: Color(0xFFBFBDBD)),
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    // // Set hint color
                  ),
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                  onChanged: (value) {
                    // No need to set the text here
                  },
                ),
              ),
            ),
          ),
          Container(
            height: 35.0, // Adjusted height
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  toggleAdd(meal, controller.text);
                  // Create a new TextEditingController for a new item
                  userFoodOptionControllers[meal] = TextEditingController();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a food item before adding.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                primary: selectedFoodOptions[meal]!.contains(controller.text)
                    ? Color.fromARGB(20, 252, 195, 44)
                    : Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                selectedFoodOptions[meal]!.contains(controller.text)
                    ? '-'
                    : '+',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAdditionalFoodOption(String meal, String foodOption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 7.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                foodOption,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Container(
            height: 35.0, // Adjusted height
            child: ElevatedButton(
              onPressed: () {
                toggleAdd(meal, foodOption);
              },
              style: ElevatedButton.styleFrom(
                primary: selectedFoodOptions[meal]!.contains(foodOption)
                    ? Color.fromARGB(19, 250, 0, 0)
                    : Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                selectedFoodOptions[meal]!.contains(foodOption) ? '-' : '+',
              ),
            ),
          ),
        ],
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
                        for (String foodOption in getFoodOptions(meal))
                          buildFoodOption(meal, foodOption),
                      ],
                    ),
                    // Additional food options
                    for (String additionalOption
                        in additionalFoodOptions[meal]!)
                      buildAdditionalFoodOption(meal, additionalOption),
                    // User-provided food option
                    buildUserFoodOption(meal),
                    SizedBox(height: 16.0),
                  ],
                ),
              Center(
                child: ElevatedButton(
                  onPressed: isCreatePollButtonEnabled ? createPoll : null,
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFFFBC32C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    shadowColor: Colors.black.withOpacity(1.0),
                    elevation: 4,
                    minimumSize: const Size(350, 55),
                  ),
                  child: Container(
                    height: 55,
                    width: 350,
                    child: Center(
                      child: Text(
                        'Create Poll',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> getFoodOptions(String meal) {
    switch (meal) {
      case 'Breakfast':
        return [
          'Omelette',
          'Pancakes',
          'Avocado Toast',
          //...additionalFoodOptions[meal]!,
        ];
      case 'Lunch':
        return [
          'Grilled Chicken Salad',
          'Pasta Carbonara',
          'Veggie Wrap',
          //...additionalFoodOptions[meal]!,
        ];
      case 'Snack':
        return [
          'Fruit Salad',
          'Hummus with Veggie Sticks',
          'Trail Mix',
          //...additionalFoodOptions[meal]!,
        ];
      case 'Dinner':
        return [
          'Salmon with Asparagus',
          'Vegetable Stir-Fry',
          'Baked Ziti',
          //...additionalFoodOptions[meal]!,
        ];
      default:
        return [];
    }
  }
}
