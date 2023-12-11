import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'get_started_screen.dart';
import 'profile_screen.dart';
import 'admin_scan_screen.dart';
import 'voucher_market_place_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 // Import your VoucherMarketplaceScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandingPage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) =>  RegistrationScreen(),
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data != null) {
            // Check if the logged-in user is the admin
            if (snapshot.data!.email == 'admin@gmail.com') {
              // Admin user is logged in, go to AdminScanScreen
              return AdminScanScreen();
            } else {
              // Check the role of the user in Firestore
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    // Still waiting for data, show a loading indicator
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                    // Error or no data, go to default ProfileScreen
                    return ProfileScreen(userId: snapshot.data!.uid);
                  }

                  // Check the role field in the user document
                  String? userRole = roleSnapshot.data!['role'];
                  if (userRole == 'non-hosteller') {
                    // User is a non-hosteller, go to VoucherMarketplaceScreen
                    return VoucherMarketplaceScreen();
                  } else {
                    // User is not a non-hosteller, go to default ProfileScreen
                    return ProfileScreen(userId: snapshot.data!.uid);
                  }
                },
              );
            }
          }
          // User is not logged in, go to the 'Get Started' screen
          return const GetStartedScreen();
        }
        // Waiting for connection, show a loading indicator
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
