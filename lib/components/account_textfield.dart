import 'package:flutter/material.dart';

class AccountTextField extends StatefulWidget {
  const AccountTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
  });
  
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;

  @override
  State<AccountTextField> createState() => _AccountTextFieldState();
}

class _AccountTextFieldState extends State<AccountTextField> {
  bool hide = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && hide,
        decoration: InputDecoration(
          prefixIcon: Icon(widget.icon),
          suffixIcon: widget.isPassword ?
            IconButton(
              icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => hide = !hide),
            )
            : null, 
          hintText: widget.hintText,
          filled: true,
          fillColor: const Color.fromARGB(255, 236, 236, 236),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          )
        ),
      )
    );
  }
}