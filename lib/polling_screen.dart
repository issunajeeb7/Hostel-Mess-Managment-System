import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:google_fonts/google_fonts.dart';

class MealPoll extends StatefulWidget {
  final String mealName;

  const MealPoll({Key? key, required this.mealName}) : super(key: key);

  @override
  _MealPollState createState() => _MealPollState();
}

class _MealPollState extends State<MealPoll> {
  late Stream<QuerySnapshot> _pollOptionsStream;
  Map<String, int> _votesCount = {};
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _pollOptionsStream =
        FirebaseFirestore.instance.collection('pollOptions').snapshots();
    FirebaseFirestore.instance
        .collection('votes')
        .doc('mealVotes')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _votesCount = data[widget.mealName] != null
              ? Map<String, int>.from(data[widget.mealName])
              : {};
        });
      }
    });
    _checkUserVotes();
  }

  Future<void> _checkUserVotes() async {
    DateTime now = DateTime.now();
    DateTime lastWeek = now.subtract(const Duration(days: 7));
    DocumentSnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('userVotes')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (querySnapshot.exists) {
      Map<String, dynamic>? userData =
          querySnapshot.data() as Map<String, dynamic>?;
      if (userData != null) {
        bool allVoted = (userData['Breakfast'] == true &&
            userData['Lunch'] == true &&
            userData['Snack'] == true &&
            userData['Dinner'] == true);
        setState(() {
          _showResults = allVoted;
        });
      }
    }
  }

  Future<void> resetVotes() async {
  try {
    await FirebaseFirestore.instance
        .collection('votes')
        .doc('mealVotes')
        .set({
      'Breakfast': {},
      'Lunch': {},
      'Snack': {},
      'Dinner': {},
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance
        .collection('userVotes')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();
  } catch (e) {
    print('Error resetting votes: $e');
    // Handle the error as needed
  }
}

// Assuming that you have a method to get the current day of the week (e.g., getDayOfWeek())



 Widget _buildPollResults() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.all(8.0),
      ),
      Column(
        children: _votesCount.entries.map((entry) {
          double votePercentage = _votesCount[entry.key]! /
              _votesCount.values.fold(
                  0, (previousValue, element) => previousValue + element);
          if (votePercentage.isNaN) {
            votePercentage = 0.0; // Set votePercentage to 0 if it's NaN
          }
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
            child: Container(
              height: 30, // Set the desired height here
              decoration: BoxDecoration(
                color: const Color.fromARGB(60, 251, 195, 44),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * votePercentage,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 251, 196, 44),
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              entry.key,
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '${(votePercentage * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pollOptionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No poll options available');
        }

        // Build the poll options, checking if we have any votes
        List<PollOption> pollOptions = [];
        snapshot.data!.docs.forEach((doc) {
          List<dynamic> options = doc[widget.mealName];
          options.forEach((option) {
            pollOptions.add(PollOption(
              id: option,
              title: Text(option.toString()),
              votes: _votesCount[option] ?? 0,
            ));
          });
        });
        

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              10, 10, 10, 0), // Add padding to the top
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                  40, 251, 195, 44), // Change to the desired background color
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 251, 196,
                        44), // Change to the desired color for the image and title area
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        child: Image.asset(
                          'assets/${widget.mealName.toLowerCase()}.png', // Use your image path here
                          fit: BoxFit.cover, // Adjust the fit as needed
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.mealName,
                        style: GoogleFonts.nunitoSans(
                          color: const Color.fromARGB(
                              255, 0, 0, 0), // Change to the desired text color
                          fontWeight: FontWeight.normal,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _showResults
                    ? _buildPollResults()
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10), // Add left and right padding
                        child: FlutterPolls(
                          pollId: '${widget.mealName.toLowerCase()}_poll',
                          pollTitle: const Text(''),
                          pollOptions: pollOptions,
                          onVoted: (PollOption selectedOption,
                              int newTotalVotes) async {
                            try {
                              DateTime now = DateTime.now();
                              int currentDayOfWeek = now.weekday;
                              if (currentDayOfWeek >= 1 &&
                                  currentDayOfWeek <= 4) {
                                if (selectedOption.id == null) {
                                  throw ArgumentError(
                                      "selectedOption.id is null");
                                }
                                final votesRef = FirebaseFirestore.instance
                                    .collection('votes')
                                    .doc('mealVotes');
                                await votesRef.set({
                                  widget.mealName: {
                                    selectedOption.id!: FieldValue.increment(1),
                                  },
                                }, SetOptions(merge: true));
                                await FirebaseFirestore.instance
                                    .collection('userVotes')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .set({
                                  widget.mealName: true,
                                }, SetOptions(merge: true));
                                await _checkUserVotes();
                                return true;
                              } else {
                                return false;
                              }
                            } catch (e) {
                              print('Error during Firestore write: $e');
                              // Handle the error as needed
                              return false;
                            }
                            
                          },
                          votedPercentageTextStyle: GoogleFonts.nunitoSans(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          pollOptionsBorderRadius: BorderRadius.circular(23),
                          pollOptionsBorder:
                              Border.all(style: BorderStyle.none),
                          pollOptionsFillColor:
                              const Color.fromARGB(255, 254, 231, 196),
                          leadingVotedProgessColor:
                              const Color.fromARGB(255, 251, 196, 44),
                          votedBackgroundColor:
                              const Color.fromARGB(255, 254, 231, 196),
                          votedPollOptionsRadius: const Radius.circular(23),
                          votedProgressColor:
                              const Color.fromARGB(255, 251, 196, 44),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PollsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Polls'),
        forceMaterialTransparency: true,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20), // Add space at the top
            MealPoll(mealName: 'Breakfast'),
            SizedBox(height: 20), // Add space between Breakfast and Lunch
            MealPoll(mealName: 'Lunch'),
            SizedBox(height: 20), // Add space between Lunch and Snack
            MealPoll(mealName: 'Snack'),
            SizedBox(height: 20), // Add space between Snack and Dinner
            MealPoll(mealName: 'Dinner'),
            SizedBox(height: 20), // Add space at the bottom
          ],
        ),
      ),
    );
  }
}
