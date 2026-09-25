import 'package:flutter/material.dart';

import '../service/rickAndMortyService.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}




class _LocationsPageState extends State<LocationsPage> {
  final Rickandmortyservice _rickAndMortyService = Rickandmortyservice();

  late Future<Map> _localFuture;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localFuture = _rickAndMortyService.getLocais(null);
  }

  void _buscarLocal(String query) {
    setState(() {
      _localFuture = _rickAndMortyService.getLocais(query);
    });
  }

  void _mudarPagina(String url) {
    setState(() {
      _localFuture = _rickAndMortyService.getPage(url);
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
                hintText: "Buscar local por nome...",
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.cyan),
                  onPressed: () => _buscarLocal(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _buscarLocal,
            ),
          ),
          Expanded(
            child: FutureBuilder<Map>(
              future: _localFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar dados.", style: TextStyle(color: Colors.white)));
                }
                final dados = snapshot.data ?? {};
                if (dados.containsKey('error')) {
                  return const Center(
                    child: Text("Nenhum local encontrado.", style: TextStyle(color: Colors.white, fontSize: 18)),
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
                          final local = resultados[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                local['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(local['type'] + " - " + local["dimension"]),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.cyan),
                                onPressed: () => _abrirDetalhesLocal(local),
                              ),
                              onTap: () => _abrirDetalhesLocal(local),
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
                            onPressed: prevUrl != null ? () => _mudarPagina(prevUrl) : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            label: const Text("Anterior"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: nextUrl != null ? () => _mudarPagina(nextUrl) : null,
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
        children: [
          Image.asset("assets/imgs/logo.png", fit: BoxFit.contain, height: 40),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: Colors.black),
      ),
    );
  }


  void _abrirDetalhesLocal(Map local) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(local['name'], textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nome: ${local['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Tipo e dimensão: ${local['type']} - ${local['dimension']}"),
                const Divider(),
                const Text("Habitantes:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Map>>(
                    future: _buscarPersonagens(local['residents']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("Erro ao carregar habitantes."));
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


