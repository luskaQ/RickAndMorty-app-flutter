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

  static const Duration _firestoreTimeout = Duration(seconds: 3);

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
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

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
          .set(perfilParaSalvar.toFirestore(), SetOptions(merge: true))
          .timeout(_firestoreTimeout);

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
      return perfilParaSalvar;
    }
  }

  Future<Perfil?> obterPerfilLocalUsuarioLogado() async {
    final uid = uidUsuarioAtual;
    if (uid == null) return null;
    final db = await database;
    final localMaps = await db.query(
      _tableName,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (localMaps.isEmpty) return null;
    final perfil = Perfil.fromSqliteMap(localMaps.first);
    perfilAtualNotifier.value = perfil;
    return perfil;
  }
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

  Future<Perfil?> obterPerfilPorUid(String uid) async {
    final db = await database;

    final List<Map<String, dynamic>> localMaps = await db.query(
      _tableName,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    Perfil? perfilLocal = localMaps.isNotEmpty
        ? Perfil.fromSqliteMap(localMaps.first)
        : null;

    if (uid == uidUsuarioAtual && perfilLocal != null) {
      perfilAtualNotifier.value = perfilLocal;
    }

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

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(_firestoreTimeout);

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
    }

    return perfilLocal;
  }

  Future<List<Perfil>> listarPerfisLocais() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'nome ASC');
    return maps.map((map) => Perfil.fromSqliteMap(map)).toList();
  }

  Future<void> sincronizarPerfisPendentes() async {
    final db = await database;

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
            .set(perfil.toFirestore(), SetOptions(merge: true))
            .timeout(_firestoreTimeout);

        final sincronizado = perfil.copyWith(sincronizado: true);
        await db.update(
          _tableName,
          sincronizado.toSqliteMap(),
          where: 'uid = ?',
          whereArgs: [perfil.uid],
        );
        if (perfil.uid == uidUsuarioAtual) {
          perfilAtualNotifier.value = sincronizado;
        }
      } catch (_) {
        return;
      }
    }
  }

  Future<void> deletarPerfilUsuarioLogado() async {
    final uid = uidUsuarioAtual;
    if (uid == null) {
      throw Exception('Nenhum usuário autenticado no Firebase Auth.');
    }
    await deletarPerfil(uid);
  }

  Future<void> deletarPerfil(String uid) async {
    final db = await database;
    await db.delete(_tableName, where: 'uid = ?', whereArgs: [uid]);

    if (uid == uidUsuarioAtual) {
      perfilAtualNotifier.value = null;
    }

    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .delete()
          .timeout(_firestoreTimeout);
    } catch (_) {}
  }
}
