import 'package:flutter/material.dart';

class EmptyContentPlaceholder extends StatelessWidget {
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final IconData icon;

  const EmptyContentPlaceholder({
    super.key,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onButtonPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}