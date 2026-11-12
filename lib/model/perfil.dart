import 'package:cloud_firestore/cloud_firestore.dart';

class Perfil {
  final String uid;
  final String nome;
  final String descricao;
  final String? foto;
  final double? latitude;
  final double? longitude;
  final DateTime? dataNascimento;
  final bool sincronizado;
  final int updatedAt;

  Perfil({
    required this.uid,
    required this.nome,
    required this.descricao,
    this.foto,
    this.latitude,
    this.longitude,
    this.dataNascimento,
    this.sincronizado = false,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Perfil copyWith({
    String? uid,
    String? nome,
    String? descricao,
    String? foto,
    double? latitude,
    double? longitude,
    DateTime? dataNascimento,
    bool? sincronizado,
    int? updatedAt,
  }) {
    return Perfil(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      foto: foto ?? this.foto,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      sincronizado: sincronizado ?? this.sincronizado,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'uid': uid,
      'nome': nome,
      'descricao': descricao,
      'foto': foto,
      'latitude': latitude,
      'longitude': longitude,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  factory Perfil.fromSqliteMap(Map<String, dynamic> map) {
    final dataNascStr = map['data_nascimento'] as String?;
    return Perfil(
      uid: map['uid'] as String,
      nome: map['nome'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      foto: map['foto'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      dataNascimento:
          dataNascStr != null ? DateTime.tryParse(dataNascStr) : null,
      sincronizado: (map['sincronizado'] as int? ?? 0) == 1,
      updatedAt:
          map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'nome': nome,
      'descricao': descricao,
      'foto': foto,
      'latitude': latitude,
      'longitude': longitude,
      'dataNascimento': dataNascimento?.toIso8601String(),
      'updatedAt': updatedAt,
    };
  }

  factory Perfil.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? dataNasc;
    final rawDataNasc = data['dataNascimento'];
    if (rawDataNasc is Timestamp) {
      dataNasc = rawDataNasc.toDate();
    } else if (rawDataNasc is String) {
      dataNasc = DateTime.tryParse(rawDataNasc);
    }

    return Perfil(
      uid: data['uid'] as String? ?? doc.id,
      nome: data['nome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      foto: data['foto'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      dataNascimento: dataNasc,
      sincronizado: true,
      updatedAt:
          data['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
