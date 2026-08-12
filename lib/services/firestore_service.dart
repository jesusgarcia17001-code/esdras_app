import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/miembro_model.dart';
import '../models/grupo_model.dart';
import '../models/academia_model.dart';
import '../models/red_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get iglesiaId => _auth.currentUser!.uid;

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