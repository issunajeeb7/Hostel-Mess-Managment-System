import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_poll_result_screen.dart';

class CreatePollScreen extends StatefulWidget {
  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;

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

  @override
  void initState() {
    super.initState();
    initPreferences();
  }

  Future<void> initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    checkLastPollTime();
  }

  void checkLastPollTime() {
    final lastPollTime = _prefs.getInt('lastPollTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - lastPollTime <
        Duration.hoursPerDay * Duration.millisecondsPerHour) {
      disableCreatePollButton();
    }
  }

  void disableCreatePollButton() {
    setState(() {
      isCreatePollButtonEnabled = false;
    });
  }

  void enableCreatePollButton() {
    setState(() {
      isCreatePollButtonEnabled = true;
    });
  }

  Future<void> setLastPollTime() async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('lastPollTime', currentTime);
  }

  void toggleAdd(String meal, String foodOption) {
    setState(() {
      if (userFoodOptionControllers[meal]!.text.isNotEmpty) {
        selectedFoodOptions[meal]!.add(userFoodOptionControllers[meal]!.text);
        additionalFoodOptions[meal]!.add(userFoodOptionControllers[meal]!.text);
      } else {
        if (selectedFoodOptions[meal]!.contains(foodOption)) {
          selectedFoodOptions[meal]!.remove(foodOption);
        } else {
          selectedFoodOptions[meal]!.add(foodOption);
        }
      }

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
    // Check if all meals have at least one item selected
    for (String meal in selectedFoodOptions.keys) {
      if (selectedFoodOptions[meal]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item in each meal.'),
          ),
        );
        return;
      }
    }

    final lastPollTime = _prefs.getInt('lastPollTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Reference to the poll document in Firestore (using a fixed document ID)
    DocumentReference pollDocument = _firestore.collection('pollOptions').doc('W2ddDpWnDelnq8gnkKdb');

    // Set the data for the poll document
    await pollDocument.set({
      'Breakfast': selectedFoodOptions['Breakfast'],
      'Lunch': selectedFoodOptions['Lunch'],
      'Snack': selectedFoodOptions['Snack'],
      'Dinner': selectedFoodOptions['Dinner'],
    });

    // Clear the text controllers and reset selected food options
    for (var controller in userFoodOptionControllers.values) {
      controller.clear();
    }

    selectedFoodOptions = {
      'Breakfast': [],
      'Lunch': [],
      'Snack': [],
      'Dinner': [],
    };

    // Disable button after creating poll and set timestamp for the last poll
    isCreatePollButtonEnabled = false;
    await setLastPollTime();

    // Remove all entries inside the 'Breakfast', 'Lunch', 'Snack', 'Dinner' maps in the 'mealVotes' document
    await _firestore.collection('votes').doc('mealVotes').update({
      'Breakfast': FieldValue.delete(),
      'Lunch': FieldValue.delete(),
      'Snack': FieldValue.delete(),
      'Dinner': FieldValue.delete(),
    });

    // Create a batched write to update all documents in the 'userVotes' collection
    WriteBatch batch = FirebaseFirestore.instance.batch();

    QuerySnapshot userVotesSnapshot = await FirebaseFirestore.instance.collection('userVotes').get();

    userVotesSnapshot.docs.forEach((doc) {
      batch.set(doc.reference, {
        'Breakfast': false,
        'Lunch': false,
        'Snack': false,
        'Dinner': false,
      }, SetOptions(merge: true));
    });

    // Commit the batched write
    await batch.commit();
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Overwrite Existing Poll?',style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),),
          content:  Text('Creating a new poll will overwrite and reset the existing poll. Are you sure you want to continue?',style: GoogleFonts.nunitoSans(),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:  Text('Cancel',style: GoogleFonts.nunitoSans(color: Colors.black),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Continue with creating the poll
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Poll created successfully!'),
                  ),
                );
              },
              child:  Text('Continue',style: GoogleFonts.nunitoSans(color: Colors.black)),
            ),
          ],
        );
      },
    );


  } catch (e) {
    print('Error creating poll: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
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
                color: const Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                foodOption,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Container(
            height: 35.0,
            child: ElevatedButton(
              onPressed: () {
                toggleAdd(meal, foodOption);
              },
              style: ElevatedButton.styleFrom(
                primary: isAdded
                    ? const Color.fromARGB(20, 252, 195, 44)
                    : const Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(isAdded ? '-' : '+',style: GoogleFonts.nunitoSans(color: Colors.black,fontSize: 18,fontWeight: FontWeight.w500)),
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
                color: const Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                alignment: Alignment.centerLeft,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add Item...',
                    hintStyle: GoogleFonts.nunitoSans(
                      fontSize: 16.0,
                      color: const Color(0xFFBFBDBD),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16.0,
                  ),
                  onChanged: (value) {},
                ),
              ),
            ),
          ),
          Container(
            height: 35.0,
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  toggleAdd(meal, controller.text);
                  userFoodOptionControllers[meal] = TextEditingController();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a food item before adding.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                primary: selectedFoodOptions[meal]!.contains(controller.text)
                    ? const Color.fromARGB(20, 252, 195, 44)
                    : const Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                selectedFoodOptions[meal]!.contains(controller.text)
                    ? '-'
                    : '+',
                    style: GoogleFonts.nunitoSans(color: Colors.black,fontSize: 18,fontWeight: FontWeight.w500),
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
                color: const Color.fromARGB(20, 252, 195, 44),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                foodOption,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Container(
            height: 35.0,
            child: ElevatedButton(
              onPressed: () {
                toggleAdd(meal, foodOption);
              },
              style: ElevatedButton.styleFrom(
                primary: selectedFoodOptions[meal]!.contains(foodOption)
                    ? const Color.fromARGB(19, 250, 0, 0)
                    : const Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                selectedFoodOptions[meal]!.contains(foodOption) ? '-' : '+',
                style: GoogleFonts.nunitoSans(color: Colors.black,fontSize: 18,fontWeight: FontWeight.w500),
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
      automaticallyImplyLeading: false,
      forceMaterialTransparency: true,
      title: Text(
        'Create Poll',
        style: GoogleFonts.nunitoSans(
          fontSize: 20.0,
          fontWeight:FontWeight.w500
        ),
      ),
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
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Column(
                    children: [
                      for (String foodOption in getFoodOptions(meal))
                        buildFoodOption(meal, foodOption),
                    ],
                  ),
                  for (String additionalOption
                      in additionalFoodOptions[meal]!)
                    buildAdditionalFoodOption(meal, additionalOption),
                  buildUserFoodOption(meal),
                  const SizedBox(height: 16.0),
                ],
              ),
            Center(
              child: ElevatedButton(
                onPressed: isCreatePollButtonEnabled ? createPoll : null,
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFFBC32C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39.0),
                  ),
                  shadowColor: Colors.black.withOpacity(1.0),
                  elevation: 0,
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
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPollResultScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFFBC32C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39.0),
                  ),
                  shadowColor: Colors.black.withOpacity(1.0),
                  elevation: 0,
                  minimumSize: const Size(350, 55),
                ),
                child: Container(
                  height: 55,
                  width: 350,
                  child: Center(
                    child: Text(
                      'View Poll Results',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
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
        ];
      case 'Lunch':
        return [
          'Grilled Chicken Salad',
          'Pasta Carbonara',
          'Veggie Wrap',
        ];
      case 'Snack':
        return [
          'Fruit Salad',
          'Hummus with Veggie Sticks',
          'Trail Mix',
        ];
      case 'Dinner':
        return [
          'Salmon with Asparagus',
          'Vegetable Stir-Fry',
          'Baked Ziti',
        ];
      default:
        return [];
    }
  }
}
