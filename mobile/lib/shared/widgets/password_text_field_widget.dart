import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PasswordTextFieldWidget extends StatefulWidget {
  final TextEditingController controller;

  const PasswordTextFieldWidget({
    super.key,
    required this.controller,
  });

  @override
  State<PasswordTextFieldWidget> createState() =>
      _PasswordTextFieldWidgetState();
}

class _PasswordTextFieldWidgetState
    extends State<PasswordTextFieldWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: 'Senha',
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 15,
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(45),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        suffixIcon: IconButton(
          splashRadius: 20,
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}