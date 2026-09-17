import 'dart:convert';

import 'package:http/http.dart' as http;
class Rickandmortyservice {
  Future<Map> getPersonagens(String? busca) async {
    http.Response response;
    response = await http.get(Uri.parse("https://rickandmortyapi.com/api/character"));

    return json.decode(response.body);
  }
  Future<Map> getLocais(String? busca) async {
    http.Response response;
    response = await http.get(Uri.parse("https://rickandmortyapi.com/api/location"));

    return json.decode(response.body);
  }
  Future<Map> getEpisodios(String? busca) async {
    http.Response response;
    response = await http.get(Uri.parse("https://rickandmortyapi.com/api/episode"));

    return json.decode(response.body);
  }

  Future<Map> getPage(String url) async {
    http.Response response;
    response = await http.get(Uri.parse(url));

    return json.decode(response.body);
  }
}