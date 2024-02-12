import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      final lastPollTime = _prefs.getInt('lastPollTime') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime - lastPollTime <
          Duration.hoursPerDay * Duration.millisecondsPerHour) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can create a new poll only once in a week',
            ),
          ),
        );
        return;
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

      for (var controller in userFoodOptionControllers.values) {
        controller.clear();
      }

      selectedFoodOptions = {
        'Breakfast': [],
        'Lunch': [],
        'Snack': [],
        'Dinner': [],
      };

      isCreatePollButtonEnabled = false; // Disable button after creating poll
      setLastPollTime(); // Set timestamp for the last poll
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
                    hintText: 'Add Item...',
                    hintStyle: GoogleFonts.nunitoSans(
                      fontSize: 16.0,
                      color: Color(0xFFBFBDBD),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
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
        title: Text(
          'Create Poll',
          style: GoogleFonts.nunitoSans(
            fontSize: 20.0,
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
                    SizedBox(height: 8.0),
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
