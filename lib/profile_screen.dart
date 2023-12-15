import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'share_meal_screen.dart';
import 'fee_payment_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String _profilePicUrl = '';
  Key _circleAvatarKey = UniqueKey();
   
   void initState() {
    super.initState();
    // Fetch user data, including profile picture URL
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user document
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();

      // Update _profilePicUrl
      setState(() {
        _profilePicUrl = userDoc['profilePicUrl'] ?? ''; // Use the correct field name
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Create a UniqueKey for the Image.file widget

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('My Profile'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await _auth.signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 24.0),
          Text(
            'My Profile',
            style: GoogleFonts.nunitoSans(
              fontSize: 28.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: () async {
              await _pickAndCropImage();
            },
            child: CircleAvatar(
              key: _circleAvatarKey,
              radius: 50.0,
              backgroundImage: _profilePicUrl.isNotEmpty
                  ? NetworkImage(
                      '$_profilePicUrl?cache=${DateTime.now().millisecondsSinceEpoch}')
                  : const AssetImage('assets/default_profile_pic.png')
                      as ImageProvider<Object>?,
              // Added: Display default image if _profilePicUrl is empty
            ),
          ),
          const SizedBox(height: 16.0),
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(widget.userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data != null) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  String fullName =
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                          .trim();
                  return Column(
                    children: <Widget>[
                      Text(
                        fullName.isNotEmpty ? fullName : 'Name not found',
                        style: GoogleFonts.nunitoSans(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        data['hostelID'] ?? 'Hostel ID not found',
                        style: GoogleFonts.nunitoSans(fontSize: 18),
                      ),
                    ],
                  );
                } else {
                  return const Text('User data not available.');
                }
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 24.0),
          QrImageView(
            data: 'Userid:${widget.userId}',
            version: QrVersions.auto,
            size: 250.0,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShareMealScreen()),
              );
            },
            child: const Text('Share a Meal'),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeePaymentScreen()), // Import FeePaymentScreen.dart if not imported
    );
  },
  child: const Text('Fee Payment'),
),

          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('scanCounter')
                  .doc('counterDoc')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  int counterValue = snapshot.data!['counter'];
                  return Text(
                    'Real-time Counter: $counterValue',
                    style: TextStyle(fontSize: 18.0),
                  );
                } else {
                  return const Text('Counter data not available');
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}


  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await _cropImage(File(pickedFile.path));

        if (croppedFile != null) {
          final imageUrl = await _uploadImageToStorage(croppedFile);
          if (imageUrl != null) {
            await _updateProfilePicUrl(widget.userId, imageUrl);

            // Trigger a rebuild by changing the key
            setState(() {
              _circleAvatarKey = UniqueKey();
            });
          }
        }
      }
    } catch (e) {
      print('Error in _pickAndCropImage: $e');
      // Optionally, show an error message to the user
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final ImageCropper imageCropper = ImageCropper();
    final croppedFile = await imageCropper.cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
    );

    if (croppedFile != null && croppedFile.path != null) {
      return File(croppedFile.path!);
    } else {
      return null;
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final storageRef =
          _storage.ref().child('profile_pics/${widget.userId}.jpg');
      await storageRef.putFile(imageFile);

      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfilePicUrl(String userId, String? imageUrl) async {
    try {
      if (imageUrl != null) {
        await _firestore.collection('users').doc(userId).update({
          'profilePicUrl': imageUrl,
        });

        // Update the state to trigger a rebuild
        setState(() {
          _profilePicUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error updating profile picture URL: $e');
    }
  }
}
