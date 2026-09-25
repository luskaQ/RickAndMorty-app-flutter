import 'package:flutter/material.dart';

import '../service/rickAndMortyService.dart';
// import 'rick_and_morty_service.dart'; // Certifique-se de importar o seu service

class EpisodesPage extends StatefulWidget {
  const EpisodesPage({super.key});
  @override
  State<EpisodesPage> createState() => _EpisodesPageState();
}

class _EpisodesPageState extends State<EpisodesPage> {
  final Rickandmortyservice _rickAndMortyService = Rickandmortyservice();

  late Future<Map> _episodiosFuture;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _episodiosFuture = _rickAndMortyService.getEpisodios(null);
  }

  void _buscarEpisodio(String query) {
    setState(() {
      _episodiosFuture = _rickAndMortyService.getEpisodios(query);
    });
  }

  void _mudarPagina(String url) {
    setState(() {
      _episodiosFuture = _rickAndMortyService.getPage(url);
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
                hintText: "Buscar episódio por nome...",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.cyan),
                  onPressed: () => _buscarEpisodio(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _buscarEpisodio,
            ),
          ),
          Expanded(
            child: FutureBuilder<Map>(
              future: _episodiosFuture,
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
                    child: Text("Nenhum episódio encontrado.",
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
                          final episodio = resultados[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                episodio['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(episodio['episode']),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.info_outline, color: Colors.cyan),
                                onPressed: () =>
                                    _abrirDetalhesEpisodio(episodio),
                              ),
                              onTap: () => _abrirDetalhesEpisodio(episodio),
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

  void _abrirDetalhesEpisodio(Map episodio) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(episodio['name'], textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Episódio: ${episodio['episode']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Lançamento: ${episodio['air_date']}"),
                const Divider(),
                const Text("Personagens:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Map>>(
                    future: _buscarPersonagens(episodio['characters']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("Erro ao carregar personagens."));
                      }

                      final personagens = snapshot.data ?? [];

                      if (personagens.isEmpty) {
                        return const Center(child: Text("Nenhum personagem registrado."));
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: personagens.length,
                        itemBuilder: (context, index) {
                          final personagem = personagens[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              personagem['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            ),
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

  Future<List<Map>> _buscarPersonagens(List dynamicUrls) async {
    List<Future<Map>> futures = dynamicUrls.map((url) => _rickAndMortyService.getPage(url.toString())).toList();
    return await Future.wait(futures);
  }
}