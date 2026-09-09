import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/miembro_model.dart';
import '../models/grupo_model.dart';
import '../models/academia_model.dart';
import '../models/red_model.dart';

class FirestoreService {
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
      final doc = await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('miembros')
          .add(miembro.toMap());
      await _sincronizarRedesDeMiembro(
        miembroId: doc.id,
        nombreCompleto: miembro.nombreCompleto,
        redesNuevasIds: miembro.redesIds,
        esLiderNuevo: miembro.esLider,
      );
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
    final ref = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .doc(miembroId);
    final anteriorSnap = await ref.get();
    final anterior = anteriorSnap.exists
        ? Miembro.fromMap(miembroId, anteriorSnap.data()!)
        : null;

    await ref.delete();

    // Si pertenecía a alguna red, hay que sacarlo de ahí también,
    // si no la red se queda mostrando un líder o miembro que ya no existe.
    if (anterior != null && anterior.redesIds.isNotEmpty) {
      await _sincronizarRedesDeMiembro(
        miembroId: miembroId,
        nombreCompleto: anterior.nombreCompleto,
        redesNuevasIds: const [],
        esLiderNuevo: false,
        redesAnterioresIds: anterior.redesIds,
      );
    }
  }

  Future<void> actualizarMiembro(
      String miembroId, Miembro miembro) async {
    final ref = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('miembros')
        .doc(miembroId);

    // Se lee el estado anterior ANTES de sobreescribir, para saber de qué
    // redes hay que quitarlo (si cambió de red) o si dejó de ser líder.
    final anteriorSnap = await ref.get();
    final redesAnterioresIds = anteriorSnap.exists
        ? List<String>.from(anteriorSnap.data()!['redesIds'] ?? [])
        : <String>[];

    await ref.update(miembro.toMap());

    await _sincronizarRedesDeMiembro(
      miembroId: miembroId,
      nombreCompleto: miembro.nombreCompleto,
      redesNuevasIds: miembro.redesIds,
      esLiderNuevo: miembro.esLider,
      redesAnterioresIds: redesAnterioresIds,
    );
  }

  /// Mantiene sincronizados los arreglos `lideresIds`/`miembrosIds` de cada
  /// Red con lo que el perfil del Miembro dice. Esta es la ÚNICA fuente de
  /// verdad para esos arreglos cuando el cambio viene desde la sección de
  /// Miembros: si el miembro es líder aparece en `lideresIds` de sus redes,
  /// si es creyente aparece en `miembrosIds`, y si se le quita una red (o
  /// se elimina el miembro) se le retira de los arreglos de esa red.
  Future<void> _sincronizarRedesDeMiembro({
    required String miembroId,
    required String nombreCompleto,
    required List<String> redesNuevasIds,
    required bool esLiderNuevo,
    List<String> redesAnterioresIds = const [],
  }) async {
    final coleccionRedes =
        _db.collection('iglesias').doc(iglesiaId).collection('redes');

    // Redes a las que pertenecía y ya no pertenece: se le retira por completo.
    final redesAQuitar =
        redesAnterioresIds.where((id) => !redesNuevasIds.contains(id));
    for (final redId in redesAQuitar) {
      try {
        await coleccionRedes.doc(redId).update({
          'lideresIds': FieldValue.arrayRemove([miembroId]),
          'lideresNombres': FieldValue.arrayRemove([nombreCompleto]),
          'miembrosIds': FieldValue.arrayRemove([miembroId]),
          'miembrosNombres': FieldValue.arrayRemove([nombreCompleto]),
        });
      } catch (_) {
        // La red pudo haber sido eliminada mientras tanto; se ignora.
      }
    }

    // Redes a las que sigue o queda asignado ahora: se asegura que esté en
    // el arreglo correcto (líder o creyente) y no en el otro.
    for (final redId in redesNuevasIds) {
      try {
        if (esLiderNuevo) {
          await coleccionRedes.doc(redId).update({
            'lideresIds': FieldValue.arrayUnion([miembroId]),
            'lideresNombres': FieldValue.arrayUnion([nombreCompleto]),
            'miembrosIds': FieldValue.arrayRemove([miembroId]),
            'miembrosNombres': FieldValue.arrayRemove([nombreCompleto]),
          });
        } else {
          await coleccionRedes.doc(redId).update({
            'miembrosIds': FieldValue.arrayUnion([miembroId]),
            'miembrosNombres': FieldValue.arrayUnion([nombreCompleto]),
            'lideresIds': FieldValue.arrayRemove([miembroId]),
            'lideresNombres': FieldValue.arrayRemove([nombreCompleto]),
          });
        }
      } catch (_) {
        // La red pudo haber sido eliminada mientras tanto; se ignora.
      }
    }
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
      final doc = await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('redes')
          .add(red.toMap());
      await _sincronizarMiembrosDeRed(
        redId: doc.id,
        redNombre: red.nombre,
        lideresIdsNuevos: red.lideresIds,
        miembrosIdsNuevos: red.miembrosIds,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> actualizarRed(String redId, Red red) async {
    final ref = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .doc(redId);

    final anteriorSnap = await ref.get();
    final anterior =
        anteriorSnap.exists ? Red.fromMap(redId, anteriorSnap.data()!) : null;

    await ref.update(red.toMap());

    await _sincronizarMiembrosDeRed(
      redId: redId,
      redNombre: red.nombre,
      lideresIdsNuevos: red.lideresIds,
      miembrosIdsNuevos: red.miembrosIds,
      lideresIdsAnteriores: anterior?.lideresIds ?? const [],
      miembrosIdsAnteriores: anterior?.miembrosIds ?? const [],
    );
  }

  Future<void> eliminarRed(String redId) async {
    final ref = _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('redes')
        .doc(redId);

    final anteriorSnap = await ref.get();
    final anterior =
        anteriorSnap.exists ? Red.fromMap(redId, anteriorSnap.data()!) : null;

    await ref.delete();

    // Si no se limpia, los miembros que pertenecían a esta red quedan con
    // una referencia a una red que ya no existe (redesIds/redesNombres
    // desactualizados).
    if (anterior != null) {
      await _sincronizarMiembrosDeRed(
        redId: redId,
        redNombre: anterior.nombre,
        lideresIdsNuevos: const [],
        miembrosIdsNuevos: const [],
        lideresIdsAnteriores: anterior.lideresIds,
        miembrosIdsAnteriores: anterior.miembrosIds,
      );
    }
  }

  /// Contraparte de [_sincronizarRedesDeMiembro]: cuando la Red se edita
  /// directamente desde la sección de Redes (por ejemplo, se le agrega o
  /// quita un líder desde ahí), se refleja el cambio en el perfil de cada
  /// Miembro afectado para que ambas pantallas queden consistentes.
  Future<void> _sincronizarMiembrosDeRed({
    required String redId,
    required String redNombre,
    required List<String> lideresIdsNuevos,
    required List<String> miembrosIdsNuevos,
    List<String> lideresIdsAnteriores = const [],
    List<String> miembrosIdsAnteriores = const [],
  }) async {
    final coleccionMiembros =
        _db.collection('iglesias').doc(iglesiaId).collection('miembros');

    final antes = {...lideresIdsAnteriores, ...miembrosIdsAnteriores};
    final ahora = {...lideresIdsNuevos, ...miembrosIdsNuevos};

    final aQuitar = antes.difference(ahora);
    for (final miembroId in aQuitar) {
      try {
        await coleccionMiembros.doc(miembroId).update({
          'redesIds': FieldValue.arrayRemove([redId]),
          'redesNombres': FieldValue.arrayRemove([redNombre]),
        });
      } catch (_) {
        // El miembro pudo haber sido eliminado mientras tanto; se ignora.
      }
    }

    for (final miembroId in ahora) {
      try {
        await coleccionMiembros.doc(miembroId).update({
          'redesIds': FieldValue.arrayUnion([redId]),
          'redesNombres': FieldValue.arrayUnion([redNombre]),
        });
      } catch (_) {
        // El miembro pudo haber sido eliminado mientras tanto; se ignora.
      }
    }
  }
}