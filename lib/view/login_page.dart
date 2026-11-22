import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:trabalho01_flutter/components/account_button.dart';
import 'package:trabalho01_flutter/components/account_textfield.dart';
import 'package:trabalho01_flutter/view/register_page.dart';

class LoginPage extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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

  Future<void> forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      showAlert('Digite seu email primeiro.');
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );
    if (!mounted) return;
    showAlert('Enviamos um link para seu email!');
  }

  Future<void> signIn() async {
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showAlert(switch (e.code) {
        'invalid-credential' => 'Email ou senha incorretos.',
        _ => 'Não foi possível entrar. Tente novamente.',
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
                  'Já tem uma conta? Faça o login!',
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
                TextButton(
                  onPressed: forgotPassword,
                  child: const Text('Esqueci a senha'),
                ),
                const SizedBox(height: 30,),
                AccountButton(onTap: signIn, text: "Entrar", icon: Icons.login,),
                const SizedBox(height: 10,),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Ainda não tem uma conta? Registre-se agora!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}