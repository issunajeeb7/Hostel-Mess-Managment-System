import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'admin_scan_screen.dart';
import 'voucher_market_place_screen.dart'; // Import VoucherMarketplaceScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

            if (_emailController.text == 'admin@gmail.com' && _passwordController.text == 'password') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminScanScreen()),
              );
            } else if (role == 'non-hosteller') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => VoucherMarketplaceScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
              );
            }
          }
        }
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
        labelText: labelText,
        hintText: hintText,
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
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTextFormField(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  validator: (input) => !input!.contains('@') ? 'Please enter a valid email' : null,
                  onSaved: (input) => _emailController.text = input!,
                  controller: _emailController,
                ),
                const SizedBox(height: 10.0),
                _buildTextFormField(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  validator: (input) => input!.length < 6 ? 'Must be at least 6 characters' : null,
                  onSaved: (input) => _passwordController.text = input!,
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
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
      ),
    );
  }
}
