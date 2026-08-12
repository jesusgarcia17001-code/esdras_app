import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/miembro_model.dart';
import '../models/rol_model.dart';
import 'roles_service.dart';


class IglesiaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // Obtener usuario actual
 Future<UsuarioApp?> getUsuario() async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      
      // Si el documento no existe, lo creamos con datos básicos
      if (!doc.exists) {
        final user = _auth.currentUser;
        if (user == null) return null;
        
        await _db.collection('usuarios').doc(uid).set({
          'uid': uid,
          'nombreCompleto': user.displayName ?? '',
          'email': user.email ?? '',
          'fotoUrl': user.photoURL,
          'rol': 'liderCedula',
          'iglesiaId': null,
          'iglesiaNombre': null,
          'fechaRegistro': DateTime.now(),
        });
        
        // Retornar usuario sin iglesia para ir a SetupScreen
        return UsuarioApp(
          uid: uid,
          nombreCompleto: user.displayName ?? '',
          email: user.email ?? '',
          fotoUrl: user.photoURL,
          rol: RolUsuario.liderCedula,
          iglesiaId: null,
          iglesiaNombre: null,
          fechaRegistro: DateTime.now(),
        );
      }
      
      return UsuarioApp.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Crear nueva iglesia
Future<String?> crearIglesia({
    required String nombre,
    required String ciudad,
    required String pais,
  }) async {
    try {
      final codigo = _generarCodigo();
      final iglesiaRef = _db.collection('iglesias').doc();

      await iglesiaRef.set({
        'id': iglesiaRef.id,
        'nombre': nombre,
        'ciudad': ciudad,
        'pais': pais,
        'codigoInvitacion': codigo,
        'adminId': uid,
        'fechaCreacion': DateTime.now(),
        'totalMiembros': 0,
      });

      // Inicializar roles predeterminados
      final rolesService = RolesService();
      await rolesService.inicializarRoles(iglesiaRef.id);

      // Obtener el rol SuperAdmin recién creado
      final rolesSnap = await _db
          .collection('iglesias')
          .doc(iglesiaRef.id)
          .collection('roles')
          .where('nivel', isEqualTo: 1)
          .get();

      final rolSuperAdmin = rolesSnap.docs.first;

      // Agregar usuario como SuperAdmin en la iglesia
      await rolesService.agregarUsuarioIglesia(
        iglesiaId: iglesiaRef.id,
        usuarioId: uid,
        nombreCompleto: _auth.currentUser!.displayName ?? '',
        email: _auth.currentUser!.email ?? '',
        fotoUrl: _auth.currentUser!.photoURL,
        rol: RolPersonalizado.fromMap(
            rolSuperAdmin.id, rolSuperAdmin.data()),
      );

      // Actualizar usuario global
      await _db.collection('usuarios').doc(uid).update({
        'iglesiaId': iglesiaRef.id,
        'iglesiaNombre': nombre,
        'rol': 'superAdmin',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }
  // Unirse a iglesia con código
  Future<String?> unirseConCodigo(String codigo) async {
    try {
      final query = await _db
          .collection('iglesias')
          .where('codigoInvitacion',
              isEqualTo: codigo.toUpperCase())
          .get();

      if (query.docs.isEmpty) {
        return 'Código inválido. Verifica con tu pastor';
      }

      final iglesia = query.docs.first;

      // Agregar solicitud de ingreso
      await _db
          .collection('iglesias')
          .doc(iglesia.id)
          .collection('solicitudes')
          .doc(uid)
          .set({
        'uid': uid,
        'nombre': _auth.currentUser!.displayName ?? '',
        'email': _auth.currentUser!.email ?? '',
        'estado': 'pendiente',
        'fecha': DateTime.now(),
      });

      // Asignar iglesia al usuario (pendiente de aprobación)
      await _db.collection('usuarios').doc(uid).update({
        'iglesiaId': iglesia.id,
        'iglesiaNombre': iglesia['nombre'],
        'rol': RolUsuario.liderCedula.name,
      });

      return null;
    } catch (e) {
      return 'Error al unirse. Intenta de nuevo';
    }
  }

  // Obtener datos de la iglesia
  Future<Map<String, dynamic>?> getIglesia(String iglesiaId) async {
    final doc =
        await _db.collection('iglesias').doc(iglesiaId).get();
    return doc.data();
  }

  // Actualizar rol de un usuario
  Future<void> actualizarRol(
      String usuarioId, RolUsuario nuevoRol) async {
    await _db.collection('usuarios').doc(usuarioId).update({
      'rol': nuevoRol.name,
    });
  }

  // Obtener miembros de la iglesia (usuarios)
  Stream<List<UsuarioApp>> getMiembrosIglesia(
      String iglesiaId) {
    return _db
        .collection('usuarios')
        .where('iglesiaId', isEqualTo: iglesiaId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => UsuarioApp.fromMap(d.data()))
            .toList());
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
            6, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

// ---- CÓDIGOS DE INVITACIÓN ----

  // Generar código de invitación
  Future<Map<String, dynamic>?> generarCodigo({
    required String iglesiaId,
    required String rolId,
    required String rolNombre,
    required int diasExpiracion,
    required int limiteUsos,
  }) async {
    try {
      final codigo = _generarCodigo();
      final expiracion = DateTime.now()
          .add(Duration(days: diasExpiracion));

      final ref = await _db
          .collection('iglesias')
          .doc(iglesiaId)
          .collection('codigos')
          .add({
        'codigo': codigo,
        'rolId': rolId,
        'rolNombre': rolNombre,
        'creadoPor': uid,
        'creadoPorNombre':
            _auth.currentUser!.displayName ?? '',
        'fechaCreacion': DateTime.now(),
        'fechaExpiracion': expiracion,
        'limiteUsos': limiteUsos,
        'usosActuales': 0,
        'activo': true,
        'usuarios': [],
      });

      final doc = await ref.get();
      return {'id': ref.id, ...doc.data()!};
    } catch (e) {
      return null;
    }
  }

  // Obtener todos los códigos
  Stream<List<Map<String, dynamic>>> getCodigos(
      String iglesiaId) {
    return _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('codigos')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // Desactivar código
  Future<void> desactivarCodigo(
      String iglesiaId, String codigoId) async {
    await _db
        .collection('iglesias')
        .doc(iglesiaId)
        .collection('codigos')
        .doc(codigoId)
        .update({'activo': false});
  }

  // Usar código al registrarse
  Future<String?> usarCodigo(String codigo) async {
    try {
      // Buscar en todas las iglesias
      final iglesiasSnap =
          await _db.collection('iglesias').get();

      for (final iglesia in iglesiasSnap.docs) {
        final codigosSnap = await _db
            .collection('iglesias')
            .doc(iglesia.id)
            .collection('codigos')
            .where('codigo', isEqualTo: codigo.toUpperCase())
            .where('activo', isEqualTo: true)
            .get();

        if (codigosSnap.docs.isEmpty) continue;

        final codigoDoc = codigosSnap.docs.first;
        final data = codigoDoc.data();

        // Verificar expiración
        final expiracion =
            (data['fechaExpiracion'] as dynamic).toDate();
        if (DateTime.now().isAfter(expiracion)) {
          await codigoDoc.reference
              .update({'activo': false});
          return 'El código ha expirado';
        }

        // Verificar límite de usos
        final usosActuales = data['usosActuales'] as int;
        final limiteUsos = data['limiteUsos'] as int;
        if (usosActuales >= limiteUsos) {
          await codigoDoc.reference
              .update({'activo': false});
          return 'El código ha alcanzado su límite de usos';
        }

        // Obtener rol
        final rolSnap = await _db
            .collection('iglesias')
            .doc(iglesia.id)
            .collection('roles')
            .doc(data['rolId'])
            .get();

        if (!rolSnap.exists) {
          return 'Error al obtener el rol';
        }

        final rol = RolPersonalizado.fromMap(
            rolSnap.id, rolSnap.data()!);

        // Agregar usuario a la iglesia con el rol
        final rolesService = RolesService();
        await rolesService.agregarUsuarioIglesia(
          iglesiaId: iglesia.id,
          usuarioId: uid,
          nombreCompleto:
              _auth.currentUser!.displayName ?? '',
          email: _auth.currentUser!.email ?? '',
          fotoUrl: _auth.currentUser!.photoURL,
          rol: rol,
        );

        // Actualizar usuario global
        await _db.collection('usuarios').doc(uid).update({
          'iglesiaId': iglesia.id,
          'iglesiaNombre': iglesia['nombre'],
          'rol': rol.nombre,
        });

        // Actualizar código
        await codigoDoc.reference.update({
          'usosActuales': usosActuales + 1,
          'activo': (usosActuales + 1) < limiteUsos,
          'usuarios': FieldValue.arrayUnion([{
            'uid': uid,
            'nombre':
                _auth.currentUser!.displayName ?? '',
            'email': _auth.currentUser!.email ?? '',
            'fecha': DateTime.now().toIso8601String(),
          }]),
        });

        return null; // éxito
      }

      return 'Código inválido. Verifica con tu pastor';
    } catch (e) {
      return 'Error al usar el código: ${e.toString()}';
    }
  }  
}