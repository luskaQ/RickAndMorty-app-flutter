import 'package:flutter/material.dart';
import 'package:trabalho01_flutter/view/perfil_page.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/imgs/logo.png',
            fit: BoxFit.contain,
            height: 40,
          ),
          const PerfilAvatarButton(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
