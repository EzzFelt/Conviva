import 'package:flutter/material.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;

  const AuthHeaderWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFF212121),
        height: 1.25,
      ),
    );
  }
}