// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ClinicProfile extends StatefulWidget {
//   const ClinicProfile({Key? key});

//   @override
//   State<ClinicProfile> createState() => _ClinicProfileState();
// }

// class _ClinicProfileState extends State<ClinicProfile> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController placeController = TextEditingController();
//   final TextEditingController timingController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   String _profilePicUrl = '';
//   late Key _circleAvatarKey = UniqueKey();

//   Future<void> _signOut() async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Signin(userId: '',)));
//   }

//   Future<void> _saveClinicInformation() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;

//     if (userId != null) {
//       await FirebaseFirestore.instance.collection('CLINIC').doc(userId).set({
//         'clinicName': nameController.text,
//         'place': placeController.text,
//         'openingHours': timingController.text,
//       });
//     }
//   }

//  Future<void> _pickAndCropImage() async {
//   final picker = ImagePicker();
//   try {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       final croppedFile = await _cropImage(File(pickedFile.path));
//       if (croppedFile != null) {
//         final imageUrl = await _uploadImageToStorage(File(croppedFile.path));
//         if (imageUrl != null) {
//           setState(() {
//             _circleAvatarKey = UniqueKey();
//             _profilePicUrl = imageUrl;
//           });
//         }
//       }
//     }
//   } catch (e) {
//     print('Error in _pickAndCropImage: $e');
//     // Optionally, show an error message to the user
//   }
// }



//  Future<CroppedFile?> _cropImage(File imageFile) async {
//   final ImageCropper imageCropper = ImageCropper();
//   final CroppedFile? croppedFile = await imageCropper.cropImage(
//     sourcePath: imageFile.path,
//     compressFormat: ImageCompressFormat.jpg,
//     compressQuality: 70,
//   );

//   return croppedFile;
// }


//   Future<String?> _uploadImageToStorage(File imageFile) async {
//     try {
//       final storageRef = _storage.ref().child('profile_pics/${_auth.currentUser!.uid}.jpg');
//       await storageRef.putFile(imageFile);

//       final downloadUrl = await storageRef.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Clinic Details'),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(labelText: 'Clinic name'),
//               ),
//               const SizedBox(height: 16.0),
//               TextField(
//                 controller: placeController,
//                 decoration: InputDecoration(labelText: 'Place'),
//               ),
//               const SizedBox(height: 16.0),
//               TextField(
//                 controller: timingController,
//                 decoration: InputDecoration(labelText: 'Opening hours'),
//                 maxLines: 4,
//               ),
//               const SizedBox(height: 16.0),
//               Center(
//                 child: GestureDetector(
//                   onTap: () async {
//                     await _pickAndCropImage();
//                   },
//                   child: Stack(
//                     children: [
//                       Container(
//                         width: 100.0,
//                         height: 100.0,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.rectangle,
//                           borderRadius: BorderRadius.circular(8.0),
//                           image: DecorationImage(
//                             fit: BoxFit.cover,
//                             alignment: Alignment.center,
//                             image: _profilePicUrl.isNotEmpty
//                                 ? CachedNetworkImageProvider(_profilePicUrl)
//                                 : const AssetImage('images/profile.png') as ImageProvider,
//                           ),
//                         ),
//                       ),
//                       if (_profilePicUrl.isEmpty)
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Color.fromARGB(255, 255, 255, 255),
//                             ),
//                             child: const Icon(
//                               Icons.create_rounded,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16.0),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _saveClinicInformation();
//                 },
//                 child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.all(15),
//                   backgroundColor: const Color.fromARGB(255, 1, 101, 252),
//                   textStyle: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.normal,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(40.0),
//                   ),
//                   minimumSize: const Size(380, 0),
//                 ),
//               ),
//               const SizedBox(height: 10.0),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _signOut();
//                 },
//                 child: Text('Sign Out', style: GoogleFonts.inter(color: Colors.white)),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.all(15),
//                   backgroundColor: const Color.fromARGB(255, 1, 101, 252),
//                   textStyle: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.normal,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(40.0),
//                   ),
//                   minimumSize: const Size(380, 0),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
