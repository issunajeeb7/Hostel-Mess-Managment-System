import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hostelIdController = TextEditingController();

  bool _isLoading = false;
  bool _isHosteller = false;
  bool _isNonHosteller = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _hostelIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String role = _isHosteller ? 'Hosteller' : 'non-hosteller';

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': role,
        if (_isHosteller) 'hostelID': _hostelIdController.text.trim(),
      });

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      final String errorMessage =
          e.message ?? 'An error occurred. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Widget _buildCustomCheckbox({
    required bool value,
    required void Function(bool) onChanged,
    required String label,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            onChanged(!value);
          },
          child: Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: value ? const Color(0xFFFBC32C) : Colors.grey[200],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    color: Colors.black,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.normal,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String labelText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.normal,
              fontSize: 16.0,
            ),
          ),
          TextFormField(
            controller: controller,
            style: GoogleFonts.nunito(
              fontSize: 14.0,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
            obscureText: obscureText,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFormField(
                      labelText: 'First Name',
                      controller: _firstNameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your first name' : null,
                    ),
                    _buildTextFormField(
                      labelText: 'Last Name',
                      controller: _lastNameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your last name' : null,
                    ),
                    _buildTextFormField(
                      labelText: 'Phone Number',
                      controller: _phoneController,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your phone number' : null,
                    ),
                    _buildTextFormField(
                      labelText: 'E-Mail ID',
                      controller: _emailController,
                      validator: (value) =>
                          !value!.contains('@') ? 'Enter a valid email' : null,
                    ),
                    _buildTextFormField(
                      labelText: 'Password',
                      controller: _passwordController,
                      validator: (value) => value!.length < 6
                          ? 'Password must be 6+ characters'
                          : null,
                      obscureText: true,
                    ),
                    _buildCustomCheckbox(
                      value: _isHosteller,
                      onChanged: (value) {
                        setState(() {
                          _isHosteller = value;
                          _isNonHosteller = !_isHosteller;
                        });
                      },
                      label: 'Hosteller',
                    ),
                    if (_isHosteller)
                      Container(
                        margin: EdgeInsets.only(
                            top: 16.0), // Add margin to create space
                        child: _buildTextFormField(
                          labelText: 'Hostel ID',
                          controller: _hostelIdController,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter your hostel ID' : null,
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildCustomCheckbox(
                      value: _isNonHosteller,
                      onChanged: (value) {
                        setState(() {
                          _isNonHosteller = value;
                          _isHosteller = !_isNonHosteller;
                        });
                      },
                      label: 'Non-Hosteller',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFFFBC32C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _register,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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
