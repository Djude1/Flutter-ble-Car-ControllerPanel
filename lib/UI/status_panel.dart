import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final String text;

  const StatusPanel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        color: Colors.black,
      ),
    );
  }
}
