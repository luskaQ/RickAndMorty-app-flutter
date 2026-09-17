import 'dart:convert';

import 'package:http/http.dart' as http;
class Rickandmortyservice {
  Future<Map> getPersonagens(String? busca) async {
    http.Response response;
    if (busca == null ||busca.isEmpty) {
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/character"));
    } else{
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/character/?name=$busca"));
    }

    return json.decode(response.body);
  }
  Future<Map> getLocais(String? busca) async {
    http.Response response;
    if (busca == null ||busca.isEmpty) {
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/location"));
    } else{
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/location/?name=$busca"));
    }

    return json.decode(response.body);
  }
  Future<Map> getEpisodios(String? busca) async {
    http.Response response;
    if (busca == null ||busca.isEmpty) {
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/episode"));
    } else{
      response =
      await http.get(Uri.parse("https://rickandmortyapi.com/api/episode/?name=$busca"));
    }

    return json.decode(response.body);
  }

  Future<Map> getPage(String url) async {
    http.Response response;
    response = await http.get(Uri.parse(url));

    return json.decode(response.body);
  }
}