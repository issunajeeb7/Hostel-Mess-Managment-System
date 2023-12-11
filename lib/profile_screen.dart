import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'share_meal_screen.dart'; // Import the ShareMealScreen file

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              } catch (e) {
                print('Logout failed: $e');
                // Handle logout failure
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'), // Provide the correct path
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content Container
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.transparent, // Make the container transparent
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Frosted Glass Design Container with Rounded Corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Frosted glass blur
                    child: Container(
                      color: Colors.white.withOpacity(0.3), // Semi-transparent white
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: QrImageView(
                          data: 'Userid:$userId', // Use the provided user ID to generate a unique QR code
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Additional user information widgets can be added here
                // For example, you can fetch and display the user's name, email, etc.

                // Button to navigate to ShareMealScreen
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ShareMealScreen()),
                    );
                  },
                  child: Text('Share a Meal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
