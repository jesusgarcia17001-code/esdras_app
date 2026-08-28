import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'firestore_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String get iglesiaId =>
      FirestoreService.iglesiaIdActual ?? _auth.currentUser!.uid;

  // Seleccionar foto de galería
  Future<File?> seleccionarFoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Subir foto de miembro
  Future<String?> subirFotoMiembro(
      File foto, String miembroId) async {
    try {
      final ref = _storage
          .ref()
          .child('iglesias')
          .child(iglesiaId)
          .child('miembros')
          .child('$miembroId.jpg');

      await ref.putFile(foto);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  // Eliminar foto
  Future<void> eliminarFoto(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}