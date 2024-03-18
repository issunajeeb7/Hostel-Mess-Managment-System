import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package

import 'login_screen.dart'; // Make sure you have this screen in your project
import 'get_started_screen.dart'; // Make sure you have this screen in your project

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_image.png', // Update with your actual image asset
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 50, // Adjust the position as it looks in the image
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Unlock Flavorful\nMoments: Your Campus\nCulinary Connection',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 50), // Spacing between text and button
                ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFBC32C),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(39),
    ),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
  ),
  onPressed: () {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GetStartedScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  },
  child: Text(
    'Get Started',
    style: GoogleFonts.nunitoSans(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: const Color.fromARGB(255, 0, 0, 0),
    ),
  ),
),

                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: const Color.fromARGB(255, 134, 134, 134),
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Already have an account? ',
                      ),
                      TextSpan(
                        text: 'Sign in',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                           // Optional: to underline 'Sign in'
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to LoginScreen when 'Sign in' is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
