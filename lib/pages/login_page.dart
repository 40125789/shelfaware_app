import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/components/my_button.dart';
import 'package:shelfaware_app/components/my_textfield.dart';
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
  }

  void signUserIn() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Provider.of<BottomNavController>(context, listen: false).navigateTo(0);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.code == 'wrong-password' ? 'Incorrect password' : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade200, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       MediaQuery.of(context).padding.bottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLogo(),
                    _buildWelcomeText(),
                    _buildInputFields(),
                    _buildForgotPassword(),
                    _buildSignInButton(),
                    _buildRegisterLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.2),
        spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2),
      )],
    ),
    child: Image.asset('assets/login.png', width: 110, height: 110),
  );

  Widget _buildWelcomeText() => Column(
    children: [
      Text('Welcome Back!', style: TextStyle(
        color: Colors.green.shade800,
        fontWeight: FontWeight.bold, fontSize: 28,
      )),
      const SizedBox(height: 5),
      Text('Sign in to continue', style: TextStyle(
        color: Colors.grey[700], fontSize: 16,
      )),
    ],
  );

  Widget _buildInputFields() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1),
      )],
    ),
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 15,
        )),
        const SizedBox(height: 5),
        MyTextField(
          key: Key('email-field'),
          controller: emailController,
          hintText: 'Enter your email',
          obscureText: false,
          suffixIcon: IconButton(
            icon: Icon(Icons.email, color: Colors.green.shade400, size: 22),
            onPressed: () {},
          ),
          onChanged: (value) {},
        ),
        const SizedBox(height: 10),
        Text('Password', style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 15,
        )),
        const SizedBox(height: 5),
        MyTextField(
          key: Key('password-field'),
          controller: passwordController,
          hintText: 'Enter your password',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.green.shade400,
              size: 22,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (value) {},
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
      ],
    ),
  );

  Widget _buildForgotPassword() => Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onTap: () => Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      ),
      child: Text('Forgot password?', style: TextStyle(
        color: Colors.green.shade700,
        fontWeight: FontWeight.bold, fontSize: 16,
      )),
    ),
  );

  Widget _buildSignInButton() => _isLoading
    ? CircularProgressIndicator(color: Colors.green.shade600)
    : SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          key: Key('login-button'),
          onPressed: signUserIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text("SIGN IN", style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
          )),
        ),
      );

  Widget _buildRegisterLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Not a member?', style: TextStyle(
        color: Colors.grey[700], fontSize: 16,
      )),
      const SizedBox(width: 4),
      GestureDetector(
        key: Key('register-now-link'),
        onTap: widget.onTap,
        child: Text('Register Now', style: TextStyle(
          color: Colors.green.shade700,
          fontWeight: FontWeight.bold, fontSize: 16,
        )),
      ),
    ],
  );
}
