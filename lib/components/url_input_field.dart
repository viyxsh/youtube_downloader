import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function() onChanged;
  final Function() onPastePressed;

  const UrlInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onPastePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'YouTube URL',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: onPastePressed,
          ),
        ],
      ),
    );
  }
}