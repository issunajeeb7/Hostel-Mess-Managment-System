import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';
import 'registration_screen.dart';
import 'package:mess_bytes/notificationservice.dart'; // Import MainScreen
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();

  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please enter both email and password.')),
          );
          return;
        }

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (userCredential.user != null) {
          await _notificationService.initToken();
          String userId = userCredential.user!.uid;
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
            final userData = userDoc.data() as Map<String, dynamic>;
            String role = userData['role'] ?? '';
            print('Role: $role');

            int initialIndex;
            switch (role) {
              case 'admin':
                initialIndex = 0; // Assuming the first index is for Admin
                break;
              case 'non-hosteller':
                initialIndex =
                    1; // Assuming the second index is for Non-Hosteller
                break;
              default:
                initialIndex =
                    2; // Assuming the third index is for Default user
                break;
            }

            // Navigate to the MainScreen with the appropriate initial index and user role
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  initialIndex: initialIndex,
                  userId: userId,
                  userRole: role,
                ),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        var errorMessage =
            'An error occurred. Please check your credentials and try again.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Widget _buildTextFormField({
    required String hintText,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    bool obscureText = false,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0, // Increase horizontal padding for wider text boxes
          vertical: 10.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFBC32C)),
          borderRadius: BorderRadius.circular(30.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFBC32C)),
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
      obscureText: obscureText,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size; // Get the screen size
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/loginbg.png',
              width: screenSize.width,
              height: screenSize
                  .height, // Replace with your actual background image path
              fit: BoxFit.cover,
            ),
          ),

          Center(
            // Center the content vertically
            child: SingleChildScrollView(
              // Allows the form to scroll when the keyboard appears
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the column content
                children: [
                  const SizedBox(height: 140),
                  // Container for the login fields
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 36.0),
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 248, 230),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset:
                              const Offset(0, 4), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 40),
                          // Email TextFormField
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email ID :',
                                  style: GoogleFonts.nunitoSans(
                                      color: Colors.black, fontSize: 17)),
                              _buildTextFormField(
                                hintText: 'Enter your email',
                                validator: (input) => !input!.contains('@')
                                    ? 'Please enter a valid email'
                                    : null,
                                onSaved: (input) =>
                                    _emailController.text = input!,
                                controller: _emailController,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          // Password TextFormField
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Password :',
                                  style: GoogleFonts.nunitoSans(
                                      color: Colors.black, fontSize: 17)),
                              _buildTextFormField(
                                hintText: 'Enter your password',
                                validator: (input) => input!.length < 6
                                    ? 'Must be at least 6 characters'
                                    : null,
                                onSaved: (input) =>
                                    _passwordController.text = input!,
                                obscureText: true,
                                controller: _passwordController,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                if (_emailController.text.isNotEmpty) {
                                  await _auth.sendPasswordResetEmail(
                                      email: _emailController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password reset email sent.',
                                        style: GoogleFonts.nunitoSans(
                                            color: Colors.black),
                                      ),
                                      backgroundColor:
                                          const Color.fromARGB(255, 251, 196, 44),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                          'Please enter your email first.',
                                          style: GoogleFonts.nunitoSans(
                                              color: Colors.black),
                                        ),
                                        backgroundColor:
                                            const Color.fromARGB(255, 251, 196, 44)),
                                  );
                                }
                              },
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.nunitoSans(
                                    color: const Color.fromARGB(255, 98, 98, 98)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xFFFBC32C),
                              onPrimary:
                                  const Color.fromARGB(255, 255, 255, 255),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            onPressed: () => _login(context),
                            child: _isLoading
                                ? const SpinKitThreeBounce(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    size: 30.0,
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                          ),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          color: const Color.fromARGB(255, 134, 134, 134),
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Don\'t have an account? ',
                          ),
                          TextSpan(
                            text: 'Sign up',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFBC32C),
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
                                      builder: (context) =>
                                          RegistrationScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
