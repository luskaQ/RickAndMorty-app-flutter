import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  const new({
    super.key,
    required this.controller,
    required this.hintText,
    required this.action,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> action;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Colors.cyan),
            onPressed: () => widget.action(widget.controller.text),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: widget.action,
      ),
    );
  }
}