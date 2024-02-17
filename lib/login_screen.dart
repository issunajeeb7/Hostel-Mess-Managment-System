import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart'; // Import MainScreen

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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (userCredential.user != null) {
          String userId = userCredential.user!.uid;
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

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
                initialIndex = 1; // Assuming the second index is for Non-Hosteller
                break;
              default:
                initialIndex = 2; // Assuming the third index is for Default user
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
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        var errorMessage = 'An error occurred. Please check your credentials and try again.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
      appBar: AppBar(title: const Text('Sign In'), automaticallyImplyLeading: false),
      body: Center(
        child: Container(
          width: 300, // Reduced width
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Email',
                style: GoogleFonts.nunitoSans(color: Colors.black,fontSize: 16,fontWeight:FontWeight.normal),
              ),
              const SizedBox(height: 5.0),
              _buildTextFormField(
                labelText: '',
                hintText: 'Enter your email',
                validator: (input) => !input!.contains('@') ? 'Please enter a valid email' : null,
                onSaved: (input) => _emailController.text = input!,
                controller: _emailController,
              ),
              const SizedBox(height: 10.0),
              Text(
                'Password',
                style: GoogleFonts.nunitoSans(color: Colors.black,fontSize: 16,fontWeight:FontWeight.normal),
              ),
              const SizedBox(height: 5.0),
              _buildTextFormField(
                labelText: '',
                hintText: 'Enter your password',
                validator: (input) => input!.length < 6 ? 'Must be at least 6 characters' : null,
                onSaved: (input) => _passwordController.text = input!,
                obscureText: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFFBC32C), // Use the specified color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _login,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
