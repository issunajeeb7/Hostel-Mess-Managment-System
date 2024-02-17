import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Signinup/Signin.dart'; // Update this import according to your file structure
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ClinicProfile extends StatefulWidget {
  const ClinicProfile({Key? key}) : super(key: key);

  @override
  State<ClinicProfile> createState() => _ClinicProfileState();
}

class _ClinicProfileState extends State<ClinicProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController timingController = TextEditingController();
  String _profilePicUrl = '';

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const Signin(userId: ''))); // Assuming Signin accepts a userId parameter
  }

  Future<void> _saveClinicInformation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      await FirebaseFirestore.instance.collection('CLINIC').doc(userId).set({
        'clinicName': nameController.text,
        'place': placeController.text,
        'openingHours': timingController.text,
        'profilePicUrl': _profilePicUrl, // Assuming you want to save the profile pic URL as well
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Upload to Firebase
      String? imageUrl = await _uploadImageToStorage(File(image.path));
      if (imageUrl != null) {
        setState(() {
          _profilePicUrl = imageUrl;
        });
      }
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref()
          .child('clinic_profile_pics/$userId')
          .putFile(imageFile);

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('CLINIC').doc(userId).update({'profilePicUrl': downloadUrl});
        return downloadUrl;
      }
    } catch (e) {
      print(e); // Ideally, handle the error more gracefully
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profilePicUrl.isNotEmpty)
                Center(
                  child: CachedNetworkImage(
                    imageUrl: _profilePicUrl,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickAndUploadImage,
                child: const Text('Upload Profile Picture'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Clinic Name'),
              ),
              TextField(
                controller: placeController,
                decoration: const InputDecoration(labelText: 'Place'),
              ),
              TextField(
                controller: timingController,
                decoration: const InputDecoration(labelText: 'Opening Hours'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveClinicInformation,
                child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 1, 101, 252),
                  minimumSize: const Size(double.infinity, 50), // double.infinity is the width and 50 is the height
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
