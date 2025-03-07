import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/my_button.dart';
import 'package:shelfaware_app/components/my_textfield.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  final String email;
  final Function()? onTap;
  const LoginPage({super.key, required this.email, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false; // To track the loading state

  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
  }

  void signUserIn() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator after login
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator after error
          if (e.code == 'wrong-password') {
            _errorMessage = 'Incorrect password';
          } else {
            _errorMessage = e.message;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/login.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 5),

                // Welcome text
                Text(
                  'Welcome back!',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                const SizedBox(height: 15),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email text field
                    MyTextField(
                      key: Key('email-field'),
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                      suffixIcon: null, onChanged: (value) {  },
                    ),
                    const SizedBox(height: 0),

                    // Password text field with visibility toggle
                    MyTextField(
                      key: Key('password-field'),
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ), onChanged: (value) {  },
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage()),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ),
                  ),
                const SizedBox(height: 15),

                // Sign-in button
                _isLoading
                    ? CircularProgressIndicator() // Show loading indicator
                    : MyButton(
                       key: Key('login-button'),
                        text: "Sign in",
                        onTap: signUserIn,
                      ),

                const SizedBox(height: 20),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Text(
                    'Not a member?',
                    style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                    GestureDetector(
                       key: Key('register-now-link'), 
                      onTap: widget.onTap,
                      child: const Text(
                      'Register Now',
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
    );
  }
}
