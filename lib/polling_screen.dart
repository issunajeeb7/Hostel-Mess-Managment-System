import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polls/flutter_polls.dart';

class BreakfastPoll extends StatefulWidget {
  @override
  _BreakfastPollState createState() => _BreakfastPollState();
}

class _BreakfastPollState extends State<BreakfastPoll> {
  late Stream<QuerySnapshot> _pollOptionsStream;
  List<PollOption> _pollOptions = [];

  @override
  void initState() {
    super.initState();
    _pollOptionsStream =
        FirebaseFirestore.instance.collection('pollOptions').snapshots();
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

        // Clear existing poll options
        _pollOptions.clear();

        // Extract poll options from snapshot
        snapshot.data!.docs.forEach((document) {
          List<dynamic> breakfastOptions = document['Breakfast'];
          breakfastOptions.forEach((option) {
            _pollOptions.add(PollOption(
              id: option.toString(),
              title: Text(option.toString()),
              votes: 0, // Initialize votes to 0
            ));
          });
        });

        return Container(
          padding: EdgeInsets.all(20),
          child: FlutterPolls(
            pollId: 'breakfast_poll',
            pollTitle: Text('Breakfast Poll'),
            pollOptions: _pollOptions,
            onVoted: (PollOption selectedOption, int newTotalVotes) async {
              // Update Firestore with the selected option
              await FirebaseFirestore.instance.collection('votes').add({
                'option': selectedOption.title.toString(),
                'timestamp': DateTime.now(),
              });

              // Return true after successful update
              return true;
            },
            votedPercentageTextStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
