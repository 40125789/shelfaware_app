import 'package:flutter/material.dart';


class PasswordValidationWidget extends StatefulWidget {
  final TextEditingController passwordController;
  const PasswordValidationWidget({Key? key, required this.passwordController}) : super(key: key);

  @override
  _PasswordValidationWidgetState createState() =>
      _PasswordValidationWidgetState();
}
class _PasswordValidationWidgetState extends State<PasswordValidationWidget> {
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialCharacter = false;
  bool _hasValidLength = false;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(widget.passwordController.text);
      _hasNumber = RegExp(r'[0-9]').hasMatch(widget.passwordController.text);
      _hasSpecialCharacter =
          RegExp(r'[^A-Za-z0-9]').hasMatch(widget.passwordController.text);
      
      // Check if the password length is at least 8 characters
      _hasValidLength = widget.passwordController.text.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              _hasValidLength ? Icons.check : Icons.close,
              color: _hasValidLength ? Colors.green : Colors.red,
            ),
            SizedBox(width: 10),
            Text("At least 8 characters")
          ],
        ),
        Row(
          children: [
            Icon(
              _hasUppercase ? Icons.check : Icons.close,
              color: _hasUppercase ? Colors.green : Colors.red,
            ),
            SizedBox(width: 10),
            Text("Contains Uppercase")
          ],
        ),
        Row(
          children: [
            Icon(
              _hasNumber ? Icons.check : Icons.close,
              color: _hasNumber ? Colors.green : Colors.red,
            ),
            SizedBox(width: 10),
            Text("Contains Number")
          ],
        ),
        Row(
          children: [
            Icon(
              _hasSpecialCharacter ? Icons.check : Icons.close,
              color: _hasSpecialCharacter ? Colors.green : Colors.red,
            ),
            SizedBox(width: 10),
            Text("Contains Special Character")
          ],
        ),
      ],
    );
  }
}
