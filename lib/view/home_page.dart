import 'package:flutter/material.dart';
import 'package:trabalho01_flutter/components/home_page_button.dart';
import 'package:trabalho01_flutter/components/my_app_bar.dart';
import 'package:trabalho01_flutter/view/characters_page.dart';
import 'package:trabalho01_flutter/view/episodes_page.dart';
import 'package:trabalho01_flutter/view/locations_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            HomePageButton(destinationPage: CharactersPage(), text: "Personagens", icon: Icons.person),
            SizedBox(height: 30),
            HomePageButton(destinationPage: EpisodesPage(), text: "Episódios", icon: Icons.video_camera_back,),
            SizedBox(height: 30),
            HomePageButton(destinationPage: LocationsPage(), text: "Locais", icon: Icons.location_on,),
          ],
        ),
      ),
    );
  }
}
