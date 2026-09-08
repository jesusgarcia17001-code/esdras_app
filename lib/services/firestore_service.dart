import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/miembro_model.dart';
import '../models/grupo_model.dart';
import '../models/academia_model.dart';
import '../models/red_model.dart';

class FirestoreService {
  /// Sincroniza a una o varias personas con una red: se agregan a la
  /// lista de miembros de esa red, y la red se agrega a la lista de
  /// redes de cada persona. Es ADITIVO (solo agrega, nunca quita a
  /// nadie de una lista anterior), para no borrar datos por accidente.
  /// Sirve tanto para creyentes como para líderes D72/D12, ya que
  /// todos son en el fondo un Miembro.
  Future<void> sincronizarPersonasConRed({
    required List<MapEntry<String, String>> personas, // id -> nombre
    required String redId,
    required String redNombre,
  }) async {
    if (personas.isEmpty || redId.isEmpty) return;
    final batch = _db.batch();
    final coleccionMiembros = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros');
    final redRef = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .doc(redId);

    for (final p in personas) {
      batch.update(coleccionMiembros.doc(p.key), {
        'redesIds': FieldValue.arrayUnion([redId]),
        'redesNombres': FieldValue.arrayUnion([redNombre]),
      });
    }
    batch.update(redRef, {
      'miembrosIds':
          FieldValue.arrayUnion(personas.map((p) => p.key).toList()),
      'miembrosNombres':
          FieldValue.arrayUnion(personas.map((p) => p.value).toList()),
    });
    await batch.commit();
  }


  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ID real de la iglesia del usuario actual. Se establece una sola vez,
  /// justo después del login/registro (por CUALQUIER camino que lleve a
  /// HomeScreen), con el iglesiaId guardado en su perfil
  /// (usuarios/{uid}.iglesiaId) — NO es lo mismo que su uid.
  static String? iglesiaIdActual;

  String get iglesiaId =>
      iglesiaIdActual ?? _auth.currentUser!.uid;

  Future<Map<String, dynamic>?> getUsuarioActual() async {
    final doc = await _db
        .collection('usuarios')
        .doc(_auth.currentUser!.uid)
        .get();
    return doc.data();
  }

  Stream<int> contarMiembros() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> contarGrupos() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('grupos')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> contarLideres() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .where('esLider', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ---- MIEMBROS ----
  Future<String?> agregarMiembro(Miembro miembro) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('miembros')
          .add(miembro.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<List<Miembro>> getMiembros() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Miembro.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> eliminarMiembro(String miembroId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .doc(miembroId)
        .delete();
  }

  Future<void> actualizarMiembro(
      String miembroId, Miembro miembro) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .doc(miembroId)
        .update(miembro.toMap());
  }

  // ---- IMPORTACIÓN MASIVA DE MIEMBROS ----
  /// Lee assets/data/base_sinai_perfiles.json y sube cada persona como
  /// Miembro, usando el id original (sinai-0001, etc.) como id del
  /// documento en Firestore. Si se corre más de una vez, sobreescribe
  /// en vez de duplicar. Devuelve la cantidad de miembros importados.
  Future<int> importarMiembrosDesdeJson() async {
    final texto = await rootBundle
        .loadString('assets/data/base_sinai_perfiles.json');
    final data = jsonDecode(texto) as Map<String, dynamic>;
    final lista = (data['miembros'] as List).cast<Map<String, dynamic>>();

    String cap(String? s) {
      if (s == null || s.trim().isEmpty) return '';
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }

    final coleccion = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros');

    const tamanoLote = 400; // límite de Firestore es 500 por batch
    var importados = 0;

    for (var i = 0; i < lista.length; i += tamanoLote) {
      final batch = _db.batch();
      final trozo = lista.skip(i).take(tamanoLote);

      for (final m in trozo) {
        final idOriginal = m['id'] as String? ?? '';
        if (idOriginal.isEmpty) continue;

        final miembro = Miembro(
          nombreCompleto: m['nombre_completo'] ?? '',
          cedula: m['cedula']?.toString() ?? '',
          email: m['correo_electronico']?.toString() ?? '',
          telefono: m['telefono']?.toString() ?? '',
          direccion: m['direccion']?.toString() ?? '',
          genero: cap(m['genero']).isEmpty
              ? 'Masculino'
              : cap(m['genero']),
          estadoCivil: cap(m['estado_civil']).isEmpty
              ? 'Soltero'
              : cap(m['estado_civil']),
          bautizado: m['bautizado'] == true,
          ministerios: (m['ministerios'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          trabaja: m['trabaja_actualmente'] == true,
          profesion: m['profesion']?.toString() ?? '',
          lugarTrabajo: m['lugar_de_trabajo']?.toString() ?? '',
          estado: (m['estado_iglesia']?.toString().toLowerCase() ==
                  'inactivo')
              ? 'Inactivo'
              : 'Activo',
          fechaIngreso: DateTime.now(),
          notas: m['observacion']?.toString() ?? '',
          esLider: m['es_lider'] == true,
          rolLider: m['tipo_lider']?.toString() ?? '',
          fechaRegistro: DateTime.now(),
        );

        batch.set(coleccion.doc(idOriginal), miembro.toMap());
        importados++;
      }

      await batch.commit();
    }

    return importados;
  }

  /// Asigna una red a varios miembros a la vez (se agrega a las que
  /// ya tenían, no las reemplaza), usando un batch para que sea rápido.
  Future<void> asignarRedAMiembros({
    required List<String> miembrosIds,
    required String redId,
    required String redNombre,
  }) async {
    final coleccion = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros');
    final batch = _db.batch();
    for (final id in miembrosIds) {
      batch.update(coleccion.doc(id), {
        'redesIds': FieldValue.arrayUnion([redId]),
        'redesNombres': FieldValue.arrayUnion([redNombre]),
      });
    }
    await batch.commit();
  }

  // ---- GRUPOS ----
  Stream<List<Grupo>> getGrupos() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('grupos')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Grupo.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> agregarGrupo(Grupo grupo) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('grupos')
          .add(grupo.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> eliminarGrupo(String grupoId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('grupos')
        .doc(grupoId)
        .delete();
  }

  Future<void> actualizarGrupo(String grupoId, Grupo grupo) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('grupos')
        .doc(grupoId)
        .update(grupo.toMap());
  }

  // ---- ACADEMIA ----
  Stream<List<NivelAcademia>> getNiveles() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('academia')
        .orderBy('fechaCreacion')
        .snapshots()
        .map((s) => s.docs
            .map((d) => NivelAcademia.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> agregarNivel(NivelAcademia nivel) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('academia')
          .add(nivel.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> actualizarNivel(
      String nivelId, NivelAcademia nivel) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('academia')
        .doc(nivelId)
        .update(nivel.toMap());
  }

  Future<void> eliminarNivel(String nivelId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('academia')
        .doc(nivelId)
        .delete();
  }

  Stream<List<Sesion>> getSesiones(String nivelId) {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('academia')
        .doc(nivelId)
        .collection('sesiones')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Sesion.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> agregarSesion(
      String nivelId, Sesion sesion) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('academia')
          .doc(nivelId)
          .collection('sesiones')
          .add(sesion.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ---- REDES ----
  Stream<List<Red>> getRedes() {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .orderBy('fechaCreacion')
        .snapshots()
        .map((s) => s.docs
            .map((d) => Red.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> agregarRed(Red red) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('redes')
          .add(red.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> actualizarRed(String redId, Red red) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .doc(redId)
        .update(red.toMap());
  }

  Future<void> eliminarRed(String redId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .doc(redId)
        .delete();
  }
}