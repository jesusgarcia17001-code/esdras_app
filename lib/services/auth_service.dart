import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/miembro_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get usuarioActual => _auth.currentUser;

  Future<String?> registrar({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(nombreCompleto);
      await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'nombreCompleto': nombreCompleto,
        'email': email,
        'fotoUrl': null,
        'rol': RolUsuario.liderCedula.name,
        'iglesiaId': null,
        'iglesiaNombre': null,
        'fechaRegistro': DateTime.now(),
      });
      return null;
    } catch (e) {
      return _mensajeError(e.toString());
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return 'Correo o contraseña incorrectos';
    }
  }

  Future<String?> loginConGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Cancelado';
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final doc = await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();
      if (!doc.exists) {
        await _db
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'nombreCompleto': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'fotoUrl': cred.user!.photoURL,
          'rol': RolUsuario.liderCedula.name,
          'iglesiaId': null,
          'iglesiaNombre': null,
          'fechaRegistro': DateTime.now(),
        });
      }
      return null;
    } catch (e) {
      return 'Error al iniciar con Google';
    }
  }

  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _mensajeError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('weak-password')) {
      return 'La contraseña es muy débil (mínimo 6 caracteres)';
    } else if (error.contains('invalid-email')) {
      return 'Correo electrónico inválido';
    }
    return 'Error al registrar. Intenta de nuevo';
  }
}