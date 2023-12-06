import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Container instead of Scaffold's default body to control the entire screen layout
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Stack to overlay the rounded container on top of the background image
        child: Stack(
          children: [
            // Top part with the background image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5, // Change the height ratio as needed
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.jpg'), // Your background image path
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Bottom part with the rounded container
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4, // Adjust the position as needed
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1), // Semi-transparent white
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 35),
                    const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      child:  const Text(
                        'Sign Up',
                        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      onPressed: () => Navigator.of(context).pushNamed('/register'),
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFFFBC32C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      child: const Text('Login',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFFFBC32C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                       
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
