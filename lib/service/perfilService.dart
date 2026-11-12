import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trabalho01_flutter/model/perfil.dart';

class PerfilService {
  static final PerfilService _instance = PerfilService._internal();
  factory PerfilService() => _instance;
  PerfilService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static Database? _database;

  final ValueNotifier<Perfil?> perfilAtualNotifier = ValueNotifier<Perfil?>(null);

  static const String _tableName = 'perfis';
  static const String _collectionName = 'perfis';

  String? get uidUsuarioAtual => _auth.currentUser?.uid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_perfis.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            uid TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            descricao TEXT NOT NULL,
            foto TEXT,
            latitude REAL,
            longitude REAL,
            data_nascimento TEXT,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN longitude REAL');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN data_nascimento TEXT');
        }
      },
    );
  }

  /// Solicita permissão e obtém a geolocalização atual do dispositivo.
  Future<Position> obterLocalizacaoAtual() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw Exception('O serviço de localização (GPS) está desativado.');
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização negada permanentemente nas configurações.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Salva ou atualiza o perfil do usuário logado no modo Offline-First.
  Future<Perfil> salvarPerfilUsuarioLogado({
    required String nome,
    required String descricao,
    String? foto,
    double? latitude,
    double? longitude,
    DateTime? dataNascimento,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário autenticado no Firebase Auth.');
    }

    final perfil = Perfil(
      uid: user.uid,
      nome: nome,
      descricao: descricao,
      foto: foto,
      latitude: latitude,
      longitude: longitude,
      dataNascimento: dataNascimento,
      sincronizado: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await salvarPerfil(perfil);
  }

  Future<Perfil> salvarPerfil(Perfil perfil) async {
    final db = await database;
    final perfilParaSalvar = perfil.copyWith(
      sincronizado: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert(
      _tableName,
      perfilParaSalvar.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (perfilParaSalvar.uid == uidUsuarioAtual) {
      perfilAtualNotifier.value = perfilParaSalvar;
    }

    try {
      await _firestore
          .collection(_collectionName)
          .doc(perfilParaSalvar.uid)
          .set(perfilParaSalvar.toFirestore(), SetOptions(merge: true));

      final perfilSincronizado = perfilParaSalvar.copyWith(sincronizado: true);
      await db.update(
        _tableName,
        perfilSincronizado.toSqliteMap(),
        where: 'uid = ?',
        whereArgs: [perfilParaSalvar.uid],
      );
      if (perfilSincronizado.uid == uidUsuarioAtual) {
        perfilAtualNotifier.value = perfilSincronizado;
      }
      return perfilSincronizado;
    } catch (_) {
      // Sem internet ou falha no Firestore: mantém salvo localmente como não sincronizado (sincronizado = 0)
      return perfilParaSalvar;
    }
  }

  /// Busca o perfil do usuário autenticado atualmente.
  /// - Lê primeiro do SQLite local (resposta rápida e funciona offline).
  /// - Tenta sincronizar pendências e buscar atualizações mais recentes no Firestore.
  Future<Perfil?> obterPerfilUsuarioLogado() async {
    final uid = uidUsuarioAtual;
    if (uid == null) {
      perfilAtualNotifier.value = null;
      return null;
    }
    final perfil = await obterPerfilPorUid(uid);
    perfilAtualNotifier.value = perfil;
    return perfil;
  }

  /// Obtém o perfil pelo [uid] seguindo a estratégia Offline-First.
  Future<Perfil?> obterPerfilPorUid(String uid) async {
    final db = await database;

    // 1. Busca primeiro no banco local SQLite
    final List<Map<String, dynamic>> localMaps = await db.query(
      _tableName,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    Perfil? perfilLocal = localMaps.isNotEmpty
        ? Perfil.fromSqliteMap(localMaps.first)
        : null;

    // 2. Se existe alteração local pendente de envio, tenta sincronizar primeiro
    if (perfilLocal != null && !perfilLocal.sincronizado) {
      await sincronizarPerfisPendentes();
      final atualizados = await db.query(
        _tableName,
        where: 'uid = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (atualizados.isNotEmpty) {
        perfilLocal = Perfil.fromSqliteMap(atualizados.first);
      }
      return perfilLocal;
    }

    // 3. Tenta buscar do Firestore para manter o cache local atualizado
    try {
      final doc = await _firestore.collection(_collectionName).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final perfilRemoto = Perfil.fromFirestore(doc);

        if (perfilLocal == null ||
            perfilRemoto.updatedAt >= perfilLocal.updatedAt) {
          await db.insert(
            _tableName,
            perfilRemoto.toSqliteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          return perfilRemoto;
        }
      }
    } catch (_) {
      // Offline: retorna o perfil salvo no SQLite local
    }

    return perfilLocal;
  }

  /// Lista todos os perfis armazenados localmente no SQLite.
  Future<List<Perfil>> listarPerfisLocais() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'nome ASC');
    return maps.map((map) => Perfil.fromSqliteMap(map)).toList();
  }

  /// Sincroniza todos os perfis locais com `sincronizado = 0` para o Cloud Firestore
  /// e atualiza o banco local com os dados mais recentes do usuário logado.
  Future<void> sincronizarPerfisPendentes() async {
    final db = await database;

    // 1. Busca todos os perfis que ainda não foram sincronizados com o Firestore
    final pendentes = await db.query(
      _tableName,
      where: 'sincronizado = ?',
      whereArgs: [0],
    );

    for (final map in pendentes) {
      final perfil = Perfil.fromSqliteMap(map);
      try {
        await _firestore
            .collection(_collectionName)
            .doc(perfil.uid)
            .set(perfil.toFirestore(), SetOptions(merge: true));

        await db.update(
          _tableName,
          perfil.copyWith(sincronizado: true).toSqliteMap(),
          where: 'uid = ?',
          whereArgs: [perfil.uid],
        );
      } catch (_) {
        // Se continuar sem conexão, mantém na fila local para a próxima tentativa
      }
    }

    // 2. Se houver usuário logado, puxa a versão remota caso não haja pendência local
    final uid = uidUsuarioAtual;
    if (uid != null) {
      try {
        final doc = await _firestore.collection(_collectionName).doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final perfilRemoto = Perfil.fromFirestore(doc);
          final localQuery = await db.query(
            _tableName,
            where: 'uid = ?',
            whereArgs: [uid],
            limit: 1,
          );

          if (localQuery.isEmpty) {
            await db.insert(
              _tableName,
              perfilRemoto.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            final perfilLocal = Perfil.fromSqliteMap(localQuery.first);
            if (perfilLocal.sincronizado &&
                perfilRemoto.updatedAt >= perfilLocal.updatedAt) {
              await db.insert(
                _tableName,
                perfilRemoto.toSqliteMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      } catch (_) {
        // Ignora erro de rede ao tentar baixar atualização remota
      }
    }
  }

  Future<void> deletarPerfil(String uid) async {
    final db = await database;
    await db.delete(_tableName, where: 'uid = ?', whereArgs: [uid]);

    try {
      await _firestore.collection(_collectionName).doc(uid).delete();
    } catch (_) {}
  }
}
