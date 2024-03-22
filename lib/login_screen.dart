import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';
import 'registration_screen.dart'; // Import MainScreen

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

  void _login(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both email and password.')),
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
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
  required String labelText,
  required String hintText,
  required String? Function(String?) validator,
  required void Function(String?) onSaved,
  bool obscureText = false,
  TextEditingController? controller,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.nunitoSans(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12.0),
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
  return Scaffold(
    appBar: AppBar(
      title: const Text('Sign In'),
      automaticallyImplyLeading: false,
    ),
    body: Center(
      child: Container(
        width: 300, // Reduced width
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextFormField(
                labelText: 'Email',
                hintText: 'Enter your email',
                validator: (input) =>
                    !input!.contains('@') ? 'Please enter a valid email' : null,
                onSaved: (input) => _emailController.text = input!,
                controller: _emailController,
              ),
              const SizedBox(height: 10.0),
              _buildTextFormField(
                labelText: 'Password',
                hintText: 'Enter your password',
                validator: (input) =>
                    input!.length < 6 ? 'Must be at least 6 characters' : null,
                onSaved: (input) => _passwordController.text = input!,
                obscureText: true,
                controller: _passwordController,
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    // Implement the Firebase reset password method
                    if (_emailController.text.isNotEmpty) {
                      await _auth.sendPasswordResetEmail(email: _emailController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset email sent.'),backgroundColor: Color.fromARGB(255, 251, 196, 44),),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your email first.'),backgroundColor: Color.fromARGB(255, 251, 196, 44)),
                      );
                    }
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.nunitoSans(color: const Color(0xFFFBC32C)
                      
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFFBC32C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(39),
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _login(context), // Pass context to _login method
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Login',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Sign Up',
                        style: GoogleFonts.nunitoSans(color:const Color(0xFFFBC32C),decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to the RegistrationScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegistrationScreen()),
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
    ),
  );
}



}
