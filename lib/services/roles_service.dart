import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rol_model.dart';
import '../models/usuario_iglesia_model.dart';


class RolesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // Inicializar roles predeterminados al crear iglesia
Future<void> inicializarRoles(String iglesiaId) async {
    final roles = [
      RolPersonalizado.superAdmin(),
      RolPersonalizado.pastor(),
      RolPersonalizado.liderPrincipal(),
      RolPersonalizado.liderLinea(),
      RolPersonalizado.liderCedula(),
    ];

    for (final rol in roles) {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('roles')
          .add(rol.toMap());
    }
  }

  // Obtener todos los roles de la iglesia
  Stream<List<RolPersonalizado>> getRoles(String iglesiaId) {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('roles')
        .orderBy('nivel')
        .snapshots()
        .map((s) => s.docs
            .map((d) => RolPersonalizado.fromMap(d.id, d.data()))
            .toList());
  }

  // Crear rol personalizado
  Future<String?> crearRol(
      String iglesiaId, RolPersonalizado rol) async {
    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('roles')
          .add(rol.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Editar rol
  Future<void> editarRol(
      String iglesiaId, String rolId, RolPersonalizado rol) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('roles')
        .doc(rolId)
        .update(rol.toMap());
  }

  // Eliminar rol
  Future<void> eliminarRol(String iglesiaId, String rolId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('roles')
        .doc(rolId)
        .delete();
  }

  // Obtener usuarios de la iglesia
  Stream<List<UsuarioIglesia>> getUsuariosIglesia(
      String iglesiaId) {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('usuarios')
        .orderBy('nivelRol')
        .snapshots()
        .map((s) => s.docs
            .map((d) => UsuarioIglesia.fromMap(d.data()))
            .toList());
  }

  // Obtener usuario actual de la iglesia
  Future<UsuarioIglesia?> getUsuarioActual(
      String iglesiaId) async {
    final doc = await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('usuarios')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UsuarioIglesia.fromMap(doc.data()!);
  }

  // Stream del usuario actual
  Stream<UsuarioIglesia?> streamUsuarioActual(String iglesiaId) {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .map((d) =>
            d.exists ? UsuarioIglesia.fromMap(d.data()!) : null);
  }

  // Cambiar rol de un usuario
  Future<String?> cambiarRol({
    required String iglesiaId,
    required String usuarioId,
    required RolPersonalizado nuevoRol,
    required UsuarioIglesia quienCambia,
    required UsuarioIglesia aQuien,
  }) async {
    // Verificar jerarquía
    if (!quienCambia.tienePermiso('cambiar_roles')) {
      return 'No tienes permiso para cambiar roles';
    }
    if (!quienCambia.puedeGestionarA(aQuien) &&
        !quienCambia.tienePermiso('control_total')) {
      return 'No puedes cambiar el rol de alguien de igual o mayor nivel';
    }
    if (nuevoRol.nivel <= quienCambia.nivelRol &&
        !quienCambia.tienePermiso('control_total')) {
      return 'No puedes asignar un rol igual o superior al tuyo';
    }

    try {
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('usuarios')
          .doc(usuarioId)
          .update({
        'rolId': nuevoRol.id ?? '',
        'rolNombre': nuevoRol.nombre,
        'permisos': nuevoRol.permisos,
        'nivelRol': nuevoRol.nivel,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Eliminar (quitar acceso a) un usuario de la iglesia.
  // Solo quien tiene control_total (Super Admin / Pastor principal)
  // puede hacerlo.
  Future<String?> eliminarUsuarioDeIglesia({
    required String iglesiaId,
    required String usuarioId,
    required UsuarioIglesia quienElimina,
  }) async {
    // Solo Super Admin (nivel 1), Pastor (nivel 2) o Líder Principal
    // (nivel 3) pueden eliminar administradores del sistema de roles.
    if (quienElimina.nivelRol > 3) {
      return 'Solo el Super Admin, Pastor o Líder Principal pueden '
          'eliminar administradores del sistema de roles';
    }
    if (usuarioId == quienElimina.uid) {
      return 'No puedes eliminarte a ti mismo';
    }

    // Averigua el nivel del usuario a eliminar para no permitir que
    // alguien borre a una persona de igual o mayor jerarquía (ej. un
    // Líder Principal no puede eliminar a un Pastor o Super Admin).
    final docObjetivo = await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('usuarios')
        .doc(usuarioId)
        .get();
    if (!docObjetivo.exists) {
      return 'Esa persona ya no está en el sistema';
    }
    final nivelObjetivo = docObjetivo.data()?['nivelRol'] ?? 99;
    if (!quienElimina.tienePermiso(Permiso.controlTotal) &&
        nivelObjetivo <= quienElimina.nivelRol) {
      return 'No puedes eliminar a alguien de igual o mayor '
          'jerarquía que la tuya';
    }
    try {
      // Quita a la persona de la lista de usuarios de esta iglesia.
      await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('usuarios')
          .doc(usuarioId)
          .delete();
      // Le revoca el acceso también en su perfil raíz, para que
      // la próxima vez que abra la app vuelva a la pantalla de
      // configuración en vez de entrar a esta iglesia.
      await _db.collection('usuarios').doc(usuarioId).update({
        'iglesiaId': null,
        'iglesiaNombre': null,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Agregar usuario a la iglesia
  Future<void> agregarUsuarioIglesia({
    required String iglesiaId,
    required String usuarioId,
    required String nombreCompleto,
    required String email,
    String? fotoUrl,
    required RolPersonalizado rol,
  }) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('usuarios')
        .doc(usuarioId)
        .set({
      'uid': usuarioId,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'fotoUrl': fotoUrl,
      'rolId': rol.id ?? '',
      'rolNombre': rol.nombre,
      'permisos': rol.permisos,
      'nivelRol': rol.nivel,
      'iglesiaId': iglesiaId,
      'fechaIngreso': DateTime.now(),
    });
  }
}