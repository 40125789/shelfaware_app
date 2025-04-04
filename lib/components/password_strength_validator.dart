import 'package:flutter/material.dart';

class PasswordValidationWidget extends StatefulWidget {
  final TextEditingController passwordController;
  const PasswordValidationWidget({Key? key, required this.passwordController})
      : super(key: key);

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
      _hasValidLength = widget.passwordController.text.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface
            : theme.colorScheme.background,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementIndicator(
              _hasValidLength, "Must be at least 8 characters long"),
          const SizedBox(height: 8),
          _buildRequirementIndicator(
              _hasUppercase, "Must contain an uppercase letter"),
          const SizedBox(height: 8),
          _buildRequirementIndicator(_hasNumber, "Must contain a number"),
          const SizedBox(height: 8),
          _buildRequirementIndicator(
              _hasSpecialCharacter, "Must contain a special character"),
        ],
      ),
    );
  }

  Widget _buildRequirementIndicator(bool isValid, String text) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          color: isValid ? Colors.green : theme.disabledColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            color: isValid
                ? theme.textTheme.bodyLarge?.color
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }
}
