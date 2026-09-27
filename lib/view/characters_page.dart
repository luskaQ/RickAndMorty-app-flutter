import 'package:flutter/material.dart';

import '../service/rickAndMortyService.dart';

class CharactersPage extends StatefulWidget {
  const CharactersPage({super.key});
  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
  final Rickandmortyservice _rickAndMortyService = Rickandmortyservice();

  late Future<Map> _charactersFuture;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charactersFuture = _rickAndMortyService.getPersonagens(null);
  }

  void _buscarPersonagem(String query) {
    setState(() {
      _charactersFuture = _rickAndMortyService.getPersonagens(query);
    });
  }

  void _mudarPagina(String url) {
    setState(() {
      _charactersFuture = _rickAndMortyService.getPage(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBarComOpcaoVoltar(),
      backgroundColor: Colors.cyan,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar personagem por nome...",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.cyan),
                  onPressed: () => _buscarPersonagem(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _buscarPersonagem,
            ),
          ),
          Expanded(
            child: FutureBuilder<Map>(
              future: _charactersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar dados.",
                      style: TextStyle(color: Colors.white)));
                }
                final dados = snapshot.data ?? {};
                if (dados.containsKey('error')) {
                  return const Center(
                    child: Text("Nenhum personagem encontrado.",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  );
                }

                final List resultados = dados['results'] ?? [];
                final Map info = dados['info'] ?? {};

                final String? prevUrl = info['prev'];
                final String? nextUrl = info['next'];
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: resultados.length,
                        itemBuilder: (context, index) {
                          final personagem = resultados[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                personagem['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(personagem['gender']),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.info_outline, color: Colors.cyan),
                                onPressed: () =>
                                    _abrirDetalhesPersonagem(personagem),
                              ),
                              onTap: () => _abrirDetalhesPersonagem(personagem),
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: prevUrl != null ? () =>
                                _mudarPagina(prevUrl) : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            label: const Text("Anterior"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: nextUrl != null ? () =>
                                _mudarPagina(nextUrl) : null,
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            label: const Text("Próxima"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget myAppBarComOpcaoVoltar() {
    return AppBar(
      backgroundColor: Colors.yellow,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/imgs/logo.png", fit: BoxFit.contain, height: 40),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
    );
  }

  void _abrirDetalhesPersonagem(Map personagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(personagem['name'], textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        personagem['image'],
                        width: 100.0,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Gênero: ', 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: "${personagem['gender']}"),
                                ]
                              )
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Espécie: ', 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: "${personagem['species']}"),
                                ]
                              )
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Origem: ', 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: "${personagem['origin']['name']}",
                                  ),
                                ]
                              )
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Localização: ', 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: "${personagem['location']['name']}",
                                  ),
                                ]
                              )
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Status: ', 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: "${personagem['status']}"),
                                ]
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const Text("Episódios:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,)),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Map>>(
                    future: _buscarEpisodios(personagem['episode']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("Erro ao carregar episódios."));
                      }

                      final episodios = snapshot.data ?? [];

                      if (episodios.isEmpty) {
                        return const Center(child: Text("Nenhum episódio registrado."));
                      }

                      return ListView.builder(
                        itemCount: episodios.length,
                        itemBuilder: (context, index) {
                          final episodio = episodios[index];
                          return ListTile(
                            title: Text(
                              episodio['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(episodio['episode']),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            )
          ],
        );
      },
    );
  }

  Future<List<Map>> _buscarEpisodios(List dynamicUrls) async {
    List<Future<Map>> futures = dynamicUrls.map((url) => _rickAndMortyService.getPage(url.toString())).toList();
    return await Future.wait(futures);
  }
}