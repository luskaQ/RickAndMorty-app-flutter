import 'package:flutter/material.dart';

class HomePageButton extends StatelessWidget {
  const HomePageButton({
    super.key,
    required this.destinationPage,
    required this.text,
    required this.icon,
  });
  final Widget destinationPage;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destinationPage,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.black,
                size: 50,
              ),
              SizedBox(width: 30),
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}