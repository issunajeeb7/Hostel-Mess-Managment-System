import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'get_started_screen.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'first_page.dart';
import 'firebase_service.dart';
// Make sure you have created this file
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  
  runApp(const MyApp());
   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, // Set the desired color here
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //  final firebaseService = FirebaseService();
    // firebaseService.listenToScanCounterChanges();
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandingPage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegistrationScreen(),
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
            // Check the role of the user in Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
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
                int initialIndex = 0; // Default index

                switch (userRole) {
                  case 'admin':
                    initialIndex = 0;
                    break;
                  case 'non-hosteller':
                    initialIndex = 1;
                    break;
                  default:
                    initialIndex = 2;
                    break;
                }

                // Return the MainScreen with the appropriate initial index and user role
                return MainScreen(
                  initialIndex: initialIndex,
                  userId: snapshot.data!.uid,
                  userRole: userRole ?? '',
                );
              },
            );
          }
          // User is not logged in, go to the 'Get Started' screen
          return const FirstPage();
        }
        // Waiting for connection, show a loading indicator
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
