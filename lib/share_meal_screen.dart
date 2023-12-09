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

  Future<void> shareMeal() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Voucher Generation'),
          content: Text(
              'Are you sure you want to generate a meal voucher for ${DateFormat('yyyy-MM-dd').format(selectedDate)} - $selectedMealType?'),
              backgroundColor: const Color(0xFFFBC32C),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User clicked No
              },
              child: const Text(
                'No',
                style: TextStyle(
                  color: Color(0xFFFFF9EA )
                ),
                ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User clicked Yes
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Color(0xFFFFF9EA )),
                ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _firestore.collection('mealvouchers').add({
        'hostellerId': FirebaseAuth.instance.currentUser!.uid,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'mealType': selectedMealType,
        'isClaimed': false,
      });

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
    ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Share a Meal'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date:',
              style: GoogleFonts.nunitoSans(
                // fontFamily: 'Nunito Sans',
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.0),
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
                  style:  GoogleFonts.nunitoSans(
                    // fontFamily: 'Nunito Sans',
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
            SizedBox(height: 16.0),
            Text(
              'Meals:',
              style: GoogleFonts.nunitoSans(
                
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.0),
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
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: shareMeal,
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                shadowColor: Colors.black.withOpacity(1.0),
                elevation: 4,
                minimumSize: Size(350, 55),
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
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyVouchersScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFFBC32C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                shadowColor: Colors.black.withOpacity(1.0),
                elevation: 4,
                minimumSize: Size(350, 55),
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
    );
  }

  Widget mealTypeCard(String mealType, String imagePath) {
    bool isSelected = selectedMealType == mealType;
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
                ? Color.fromARGB(255, 251, 196, 44)
                : Color(0xFFFFF9EA),
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
            onTap: () {
              setState(() {
                selectedMealType = mealType;
              });
            },
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
                    color: isSelected ? Colors.white : Colors.black,
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
