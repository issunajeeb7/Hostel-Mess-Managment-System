import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealPoll extends StatefulWidget {
  final String mealName;

  const MealPoll({Key? key, required this.mealName}) : super(key: key);

  @override
  _MealPollState createState() => _MealPollState();
}

class _MealPollState extends State<MealPoll> {
  late Stream<QuerySnapshot> _pollOptionsStream;
  Map<String, int> _votesCount = {};

  @override
  void initState() {
    super.initState();
    _pollOptionsStream =
        FirebaseFirestore.instance.collection('pollOptions').snapshots();
    // Initialize stream to listen to votes
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
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No poll options available');
        }

        // Calculate the total votes
        int totalVotes = _votesCount.values
            .fold(0, (previousValue, element) => previousValue + element);

        // Build the poll options, checking if we have any votes
        List<PollOption> pollOptions = [];
        snapshot.data!.docs.forEach((doc) {
          List<dynamic> options = doc[widget.mealName];
          options.forEach((option) {
            int voteCount = _votesCount[option] ?? 0;
            double percentage =
                totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;
            pollOptions.add(PollOption(
              id: option,
              title: Text(option.toString()),
              votes: voteCount,
            ));
          });
        });

        return Container(
          padding: EdgeInsets.all(20),
          child: FlutterPolls(
            pollId: '${widget.mealName.toLowerCase()}_poll',
            pollTitle: Text('${widget.mealName} Poll'),
            pollOptions: pollOptions,
            onVoted: (PollOption selectedOption, int newTotalVotes) async {
              // Get the current date and day of the week
              DateTime now = DateTime.now();
              String formattedDate =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              // Get the current user ID
              String userId = FirebaseAuth.instance.currentUser!.uid;

              // Update the votes for the selected option
              final votesRef = FirebaseFirestore.instance
                  .collection('votes')
                  .doc('mealVotes');
              await votesRef.set({
                widget.mealName: {
                  selectedOption.id!: FieldValue.increment(1),
                },
              }, SetOptions(merge: true));

              // Check if the user has voted for all four meal types
              // Check if the user has voted for all four meal types
              final userVotesRef = FirebaseFirestore.instance
                  .collection('userVotes')
                  .doc(userId);
              DocumentSnapshot userVotesSnapshot = await userVotesRef.get();
              Map<String, dynamic> userVotesData =
                  userVotesSnapshot.data() as Map<String, dynamic>;
              List<String> mealTypes = [
                'Breakfast',
                'Lunch',
                'Snack',
                'Dinner'
              ];
              bool hasVotedForAllMeals = mealTypes.every((mealType) =>
                  userVotesData.containsKey(mealType) &&
                  userVotesData[mealType] == true);

// If the user has voted for all four meal types, update the hasVoted flag
              if (hasVotedForAllMeals) {
                await userVotesRef.set({
                  'hasVoted': true,
                  'date': formattedDate,
                });
              }

              // The UI will update automatically due to the votes stream listener in initState
              return true;
            },

            votedPercentageTextStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            // Additional properties as per your design and functionality...
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
        title: Text('Meal Polls'),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MealPoll(mealName: 'Breakfast'),
            MealPoll(mealName: 'Lunch'),
            MealPoll(mealName: 'Snack'),
            MealPoll(mealName: 'Dinner'),
          ],
        ),
      ),
    );
  }
}
