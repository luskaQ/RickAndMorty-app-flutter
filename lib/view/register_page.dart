import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:trabalho01_flutter/components/account_button.dart';
import 'package:trabalho01_flutter/components/account_textfield.dart';

class RegisterPage extends StatefulWidget {
  const new({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(message)),
    );
  }

  bool emailValidator() {
    final email = emailController.text;
    final RegExp emailRegex = RegExp(
      r'^((?!\.)[\w\-_.]*[^.])(@\w+)(\.\w+)+$',
      multiLine: true,
    );
    if(!emailRegex.hasMatch(email)) {
      return false;
    }
    return true;
  }

  Future<void> register() async {
    if (passwordController.text != confirmController.text) {
      showAlert('Senhas não conferem!');
      return;
    }
    if(!emailValidator()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Digite um email válido!")),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context); // fecha o loading
      Navigator.pop(context); // fecha a RegisterPage
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showAlert(switch (e.code) {
        'email-already-in-use' => 'Já existe um usuário com esse email!',
        'weak-password' => 'Escolha uma senha mais forte.',
        _ => 'Não foi possível cadastrar. Tente novamente.',
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Lottie.asset(
                  'assets/animations/rick.json',
                  height: 150,
                  repeat: true,
                ),
                const SizedBox(height: 20,),
                const Text(
                  'Cadastre-se!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20,),
                AccountTextField(
                  controller: emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 15,),
                AccountTextField(
                  controller: passwordController,
                  hintText: 'Senha',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 15,),
                AccountTextField(
                  controller: confirmController,
                  hintText: 'Confirmar senha',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 15,),
                AccountButton(onTap: register, text: "Registrar", icon: Icons.person_add,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}