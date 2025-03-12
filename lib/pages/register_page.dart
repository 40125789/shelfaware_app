import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/my_button.dart';
import 'package:shelfaware_app/components/my_textfield.dart';
import 'package:shelfaware_app/components/password_strength_validator.dart';
import 'package:shelfaware_app/pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _firstNameError;
  String? _lastNameError;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  void signUserUp() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _firstNameError = null;
      _lastNameError = null;
    });

    // Validate inputs
    if (firstNameController.text.isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
      });
      return;
    }

    if (lastNameController.text.isEmpty) {
      setState(() {
        _lastNameError = 'Last name is required';
      });
      return;
    }

    if (emailController.text.isEmpty ||
        !RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true; // Set loading to true when starting the signup process
    });

    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Add user details to Firestore
        await addUserDetails(
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          emailController.text.trim(),
        );

        // Navigate to the Home Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(), // Replace this with your actual HomePage widget
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.message ?? 'An error occurred');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false after the process finishes
      });
    }
  }

  Future<void> addUserDetails(
      String firstName, String lastName, String email) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final Timestamp joinDate = Timestamp.now();

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'joinDate': joinDate,
    });
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _checkPasswordMatch() {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey, // Connect the Form with the key
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20, //just size as needed
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      SizedBox(
                          width: 10), // Add spacing between the icon and text
                      Text(
                        'Register Now!',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  MyTextField(
                    key: Key('firstNameField'),
                    controller: firstNameController,
                    hintText: 'First Name',
                    errorText: _firstNameError,
                    onChanged: (value) {},
                  ),
                  MyTextField(
                    key: Key('lastNameField'),
                    controller: lastNameController,
                    hintText: 'Last Name',
                    errorText: _lastNameError,
                    onChanged: (value) {},
                  ),
                  MyTextField(
                    key: Key('emailField'),
                    controller: emailController,
                    hintText: 'Email',
                    errorText: _emailError,
                    onChanged: (value) {},
                  ),
                  MyTextField(
                    key: Key('passwordField'),
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: !_isPasswordVisible,
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    onChanged: (value) {},
                  ),
                  MyTextField(
                    key: Key('confirmPasswordField'),
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: !_isConfirmPasswordVisible,
                    errorText: _confirmPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    onChanged: (value) {
                      _checkPasswordMatch(); // Check password match immediately
                    },
                  ),
                  PasswordValidationWidget(
                      passwordController: passwordController),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : MyButton(
                            key: Key('signupButton'),
                            text: "Sign up",
                            onTap: signUserUp,
                          ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          ' Login Now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
