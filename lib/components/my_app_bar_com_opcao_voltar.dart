import 'package:flutter/material.dart';
import 'package:trabalho01_flutter/view/perfil_page.dart';

class MyAppBarComOpcaoVoltar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBarComOpcaoVoltar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Image.asset(
        'assets/imgs/logo.png',
        fit: BoxFit.contain,
        height: 40,
      ),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12.0),
          child: PerfilAvatarButton(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
