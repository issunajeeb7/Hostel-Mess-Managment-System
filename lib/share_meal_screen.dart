import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'generated_vouchers_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareMealScreen extends StatefulWidget {
  @override
  _ShareMealScreenState createState() => _ShareMealScreenState();
}

class _ShareMealScreenState extends State<ShareMealScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  String selectedMealType = 'Breakfast'; // Default value
  late List<String> generatedVouchers;

  @override
  void initState() {
    super.initState();
    generatedVouchers = []; // Initialize as an empty list
    loadGeneratedVouchers();
  }

  Future<void> loadGeneratedVouchers() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('generatedVouchers')) {
        setState(() {
          generatedVouchers = List<String>.from(userData['generatedVouchers']);
        });
      }
    }
  }

bool canGenerateVoucher(String mealType) {
  String selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);
  return !generatedVouchers.contains('$selectedDateString-$mealType');
}



Future<void> shareMeal() async {
  if (!canGenerateVoucher(selectedMealType)) {
    // Voucher already generated for the selected date and meal type
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voucher already generated for the selected date and meal type.'),
      ),
    );
    return;
  }

  bool confirmed = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
  title: Row(
    children: [
      Image.asset('assets/ticketicon.png', height: 24, width: 24), // Adjust height and width as needed
      const SizedBox(width: 8), // Add space between icon and text
      Text(
        'Voucher Generation',
        style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500),
      ),
    ],
  ),
  content: Text(
    'Are you sure you want to generate a meal voucher for ${DateFormat('dd-MM-yyyy').format(selectedDate)} for $selectedMealType?',
    style: GoogleFonts.nunitoSans(color: Colors.black),
  ),
  backgroundColor: Colors.white,
  actions: <Widget>[
    TextButton(
      onPressed: () {
        Navigator.of(context).pop(false); // User clicked No
      },
      child: const Text(
        'No',
        style: TextStyle(
          color: Colors.black,
        ),
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.of(context).pop(true); // User clicked Yes
      },
      child: const Text(
        'Yes',
        style: TextStyle(color: Colors.black),
      ),
    ),
  ],
);

    },
  );

  if (confirmed == true) {
    String selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Allow Firestore to automatically generate a unique ID
    await _firestore.collection('mealvouchers').add({
      'hostellerId': FirebaseAuth.instance.currentUser!.uid,
      'date': selectedDateString,
      'mealType': selectedMealType,
      'isClaimed': false,
      'isUsed': false,
    });

    // Update generated vouchers for the current user
    generatedVouchers.add('$selectedDateString-$selectedMealType');
    await _firestore.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
      'generatedVouchers': FieldValue.arrayUnion(generatedVouchers),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meal voucher generated for ${DateFormat('yyyy-MM-dd').format(selectedDate)} - $selectedMealType'),
      ),
    );

    // Reload the list of generated vouchers
    loadGeneratedVouchers();
  }
}


  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:  Text('Share a Meal',style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w500,fontSize: 25,),),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date:',
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EA),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: theme.primaryColor,
                  ),
                  onTap: () async {
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
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Meals:',
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8.0),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 1.0,
                children: <Widget>[
                  mealTypeCard('Breakfast', 'assets/breakfast.png'),
                  mealTypeCard('Snack', 'assets/snack.png'),
                  mealTypeCard('Lunch', 'assets/lunch.png'),
                  mealTypeCard('Dinner', 'assets/dinner.png'),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: shareMeal,
                style: ElevatedButton.styleFrom(
                  primary: canGenerateVoucher(selectedMealType) ? const Color(0xFFFBC32C) : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39.0),
                  ),
                  // shadowColor: Colors.black.withOpacity(1.0),
                  elevation: 0,
                  minimumSize: const Size(350, 55),
                ),
                child: Container(
                  height: 55,
                  width: 350,
                  child: Center(
                    child: Text(
                      'Share The Meal',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyVouchersScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFFBC32C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39.0),
                  ),
                  // shadowColor: Colors.black.withOpacity(1.0),
                  elevation: 0,
                  minimumSize: const Size(350, 55),
                ),
                child: Container(
                  height: 55,
                  width: 350,
                  child: Center(
                    child: Text(
                      'View My Vouchers',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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

Widget mealTypeCard(String mealType, String imagePath) {
  bool isSelected = selectedMealType == mealType;
  bool canGenerate = canGenerateVoucher(mealType);

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 251, 196, 44)
              : canGenerate ? const Color(0xFFFFF9EA) : Colors.grey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          onTap: canGenerate
              ? () {
                  setState(() {
                    selectedMealType = mealType;
                  });
                }
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(imagePath, height: 90),
              ),
              Text(
                mealType,
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? Colors.white : canGenerate ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


}
