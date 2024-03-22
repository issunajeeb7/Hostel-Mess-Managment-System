import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

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
  String _fullName = '';
  String _hostelID = '';
  bool _userDataLoaded = false;

  void initState() {
    super.initState();

    // Fetch user data, including profile picture URL
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user document
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      // Update _fullName and _hostelID
      _fullName =
          "${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}".trim();
      print("Full name: $_fullName");
      _hostelID = userDoc['hostelID'] ?? 'Hostel ID not found';
      print('Hostel ID: $_hostelID');

      // Check if profilePicUrl field exists before setting _profilePicUrl
      if (userDoc.data()!.containsKey('profilePicUrl')) {
        setState(() {
          _profilePicUrl = userDoc['profilePicUrl'];
        });
      }

      // Set _userDataLoaded to true after fetching data
      setState(() {
        _userDataLoaded = true;
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   forceMaterialTransparency: true,
      //   leading: TextButton(
      //     onPressed: () async {
      //       await _auth.signOut();
      //       Navigator.of(context).pushReplacementNamed('/login');
      //     },
      //     child: const Text(
      //       'Logout',
      //       style: TextStyle(color: Color(0xFFFBC32C)),
            
      //       overflow: TextOverflow.visible,
      //     ),
      //   ),
      //   // Other app bar properties as needed
      // ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 10.0),
               Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: TextButton(
                    onPressed: () async {
                      await _auth.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Logout',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFBC32C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
              // Text(
              //   'My Profile',
              //   style: GoogleFonts.nunitoSans(
              //     fontSize: 28.0,
              //     fontWeight: FontWeight.w800,
              //   ),
              // ),
              const SizedBox(height: 70.0),
              GestureDetector(
                onTap: () async {
                  await _pickAndCropImage();
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.4),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(
                                0, 5), // changes position of shadow
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: _profilePicUrl.isNotEmpty
                            ? CachedNetworkImageProvider(_profilePicUrl)
                            : const AssetImage('assets/default_profile_pic.png')
                                as ImageProvider,
                      ),
                    ),
                    if (_profilePicUrl.isEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          child: const Icon(
                            Icons.create_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center the badge and text
                    children: <Widget>[
                      Container(
                        width: 10, // Adjust the size of the badge as needed
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFBC32C),
                        ),
                      ),
                      const SizedBox(
                          width:
                              5), // Add some spacing between the badge and the text
                      Text(
                        "Hostel ID: $_hostelID",
                        style: GoogleFonts.nunitoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 144, 144, 147)),
                      ),
                    ],
                  ),
                  Text(
                    _fullName.isNotEmpty ? _fullName : 'Name not found',
                    style: GoogleFonts.nunitoSans(
                        fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              QrImageView(
                data: 'Userid:${widget.userId}',
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 30),
              Container(
                width: 238,
                height: 50, // Adjusted height to match the provided design
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 254, 231, 196), // Adjusted color to a lighter shade
                  borderRadius:
                      BorderRadius.circular(30.0), // More rounded corners
                ),
                child: Center(
                  // Centered the text vertically and horizontally
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('scanCounter')
                        .doc('counterDoc')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        int counterValue = snapshot.data!['counter'];
                        return Text(
                          'Current Diners: $counterValue', // Updated text format
                          style: GoogleFonts.nunitoSans(
                            fontSize: 20.0, // Increased font size
                            fontWeight: FontWeight.w500,
                            color: Colors.black, // Font color set to black
                          ),
                        );
                      } else {
                        return const Text('Counter data not available');
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const SizedBox(height: 20),
            ],
          ),
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
