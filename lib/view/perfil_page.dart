import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trabalho01_flutter/model/perfil.dart';
import 'package:trabalho01_flutter/service/perfilService.dart';

class PerfilAvatarButton extends StatefulWidget {
  const PerfilAvatarButton({super.key});

  @override
  State<PerfilAvatarButton> createState() => _PerfilAvatarButtonState();
}

class _PerfilAvatarButtonState extends State<PerfilAvatarButton> {
  final PerfilService _perfilService = PerfilService();

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    await _perfilService.obterPerfilUsuarioLogado();
  }

  ImageProvider _obterImagemAvatar(Perfil? perfil) {
    final foto = perfil?.foto?.trim();
    if (foto != null && foto.isNotEmpty) {
      if (foto.startsWith('http://') || foto.startsWith('https://')) {
        return NetworkImage(foto);
      }
      final arquivo = File(foto);
      if (arquivo.existsSync()) {
        return FileImage(arquivo);
      }
    }
    return const AssetImage("assets/imgs/icon.png");
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Perfil?>(
      valueListenable: _perfilService.perfilAtualNotifier,
      builder: (context, perfil, _) {
        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PerfilPage(),
              ),
            );
            _carregarPerfil();
          },
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _obterImagemAvatar(perfil),
          ),
        );
      },
    );
  }
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final PerfilService _perfilService = PerfilService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _caminhoFoto;
  double? _latitude;
  double? _longitude;
  DateTime? _dataNascimento;
  DateTime _focusedDay = DateTime(2000, 1, 1);

  bool _carregando = true;
  bool _buscandoLocalizacao = false;
  bool _salvando = false;
  bool _deletando = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosPerfil();
  }

  void _preencherCampos(Perfil perfil) {
    _nomeController.text = perfil.nome;
    _descricaoController.text = perfil.descricao;
    _caminhoFoto = perfil.foto;
    _latitude = perfil.latitude;
    _longitude = perfil.longitude;
    _dataNascimento = perfil.dataNascimento;
    if (_dataNascimento != null) {
      _focusedDay = _dataNascimento!;
    }
  }

  Future<void> _carregarDadosPerfil() async {
    setState(() => _carregando = true);

    final perfilLocal = await _perfilService.obterPerfilLocalUsuarioLogado();
    if (perfilLocal != null && mounted) {
      setState(() {
        _preencherCampos(perfilLocal);
        _carregando = false;
      });
    }

    final perfilSincronizado = await _perfilService.obterPerfilUsuarioLogado();
    if (mounted) {
      setState(() {
        if (perfilSincronizado != null) {
          _preencherCampos(perfilSincronizado);
        }
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarFoto() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _caminhoFoto = imagem.path;
      });
    }
  }

  Future<void> _obterGeolocalizacao() async {
    setState(() => _buscandoLocalizacao = true);
    try {
      final posicao = await _perfilService.obterLocalizacaoAtual();
      if (mounted) {
        setState
          (() {
          _latitude = posicao.latitude;
          _longitude = posicao.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geolocalização obtida com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buscandoLocalizacao = false);
      }
    }
  }

  Future<void> _salvarPerfil() async {
    setState(() => _salvando = true);
    try {
      final perfilSalvo = await _perfilService.salvarPerfilUsuarioLogado(
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        foto: _caminhoFoto,
        latitude: _latitude,
        longitude: _longitude,
        dataNascimento: _dataNascimento,
      );
      if (mounted) {
        setState(() {});
        final msg = perfilSalvo.sincronizado
            ? 'Perfil salvo e sincronizado com sucesso!'
            : 'Perfil salvo localmente (modo offline). Será sincronizado quando houver conexão.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _confirmarEDeletarPerfil() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Perfil'),
        content: const Text(
          'Tem certeza que deseja deletar e limpar todos os dados do seu perfil?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _deletando = true);
    try {
      await _perfilService.deletarPerfilUsuarioLogado();
      if (mounted) {
        setState(() {
          _nomeController.clear();
          _descricaoController.clear();
          _caminhoFoto = null;
          _latitude = null;
          _longitude = null;
          _dataNascimento = null;
          _focusedDay = DateTime(2000, 1, 1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil deletado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletando = false);
      }
    }
  }

  Future<void> _logout() async {
    _perfilService.perfilAtualNotifier.value = null;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Nenhuma data selecionada';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  ImageProvider _obterImagemPreview() {
    final foto = _caminhoFoto?.trim();
    if (foto != null && foto.isNotEmpty) {
      if (foto.startsWith('http://') || foto.startsWith('https://')) {
        return NetworkImage(foto);
      }
      final arquivo = File(foto);
      if (arquivo.existsSync()) {
        return FileImage(arquivo);
      }
    }
    return const AssetImage("assets/imgs/icon.png");
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Image.asset(
          "assets/imgs/logo.png",
          fit: BoxFit.contain,
          height: 40,
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _selecionarFoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _obterImagemPreview(),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: "Nome",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Descrição",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Data de Nascimento:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatarData(_dataNascimento),
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        TableCalendar(
                          firstDay: DateTime(1900, 1, 1),
                          lastDay: DateTime.now(),
                          focusedDay: _focusedDay.isAfter(DateTime.now())
                              ? DateTime.now()
                              : _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_dataNascimento, day),
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Mês',
                          },
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarStyle: const CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Colors.cyan,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _dataNascimento = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Geolocalização",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _latitude != null && _longitude != null
                              ? "Latitude: ${_latitude!.toStringAsFixed(6)}\nLongitude: ${_longitude!.toStringAsFixed(6)}"
                              : "Localização ainda não capturada.",
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _buscandoLocalizacao
                                ? null
                                : _obterGeolocalizacao,
                            icon: _buscandoLocalizacao
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: const Text("Obter Localização Atual"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_salvando || _deletando) ? null : _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Salvar Perfil",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (_salvando || _deletando)
                          ? null
                          : _confirmarEDeletarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _deletando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text(
                        "Deletar / Limpar Perfil",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
