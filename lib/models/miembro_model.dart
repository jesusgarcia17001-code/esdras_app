import 'package:cloud_firestore/cloud_firestore.dart';

enum RolUsuario {
  superAdmin,
  administrador,
  liderPrincipal,
  liderLinea,
  liderCedula,
}

extension RolUsuarioExtension on RolUsuario {
  String get nombre {
    switch (this) {
      case RolUsuario.superAdmin:
        return 'Pastor / Super Admin';
      case RolUsuario.administrador:
        return 'Administrador';
      case RolUsuario.liderPrincipal:
        return 'Líder principal';
      case RolUsuario.liderLinea:
        return 'Líder de línea';
      case RolUsuario.liderCedula:
        return 'Líder de cédula';
    }
  }

  bool get puedeEditarTodo =>
      this == RolUsuario.superAdmin ||
      this == RolUsuario.administrador;

  bool get puedeVerTodo =>
      this == RolUsuario.superAdmin ||
      this == RolUsuario.administrador ||
      this == RolUsuario.liderPrincipal;

  bool get soloSuGrupo =>
      this == RolUsuario.liderLinea ||
      this == RolUsuario.liderCedula;
}

class UsuarioApp {
  final String uid;
  final String nombreCompleto;
  final String email;
  final String? fotoUrl;
  final RolUsuario rol;
  final String? iglesiaId;
  final String? iglesiaNombre;
  final DateTime fechaRegistro;

  UsuarioApp({
    required this.uid,
    required this.nombreCompleto,
    required this.email,
    this.fotoUrl,
    required this.rol,
    this.iglesiaId,
    this.iglesiaNombre,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nombreCompleto': nombreCompleto,
    'email': email,
    'fotoUrl': fotoUrl,
    'rol': rol.name,
    'iglesiaId': iglesiaId,
    'iglesiaNombre': iglesiaNombre,
    'fechaRegistro': fechaRegistro,
  };

  factory UsuarioApp.fromMap(Map<String, dynamic> m) =>
      UsuarioApp(
        uid: m['uid'] ?? '',
        nombreCompleto: m['nombreCompleto'] ?? '',
        email: m['email'] ?? '',
        fotoUrl: m['fotoUrl'],
        rol: RolUsuario.values.firstWhere(
          (r) => r.name == m['rol'],
          orElse: () => RolUsuario.liderCedula,
        ),
        iglesiaId: m['iglesiaId'],
        iglesiaNombre: m['iglesiaNombre'],
        fechaRegistro:
            (m['fechaRegistro'] as dynamic).toDate(),
      );
}

class Miembro {
  final String? id;

  // Datos básicos
  final String nombreCompleto;
  final String cedula; // V-12345678 o E-12345678
  final String email;
  final String telefono;
  final String direccion;
  final String? fotoUrl;

  // Datos personales
  final DateTime? fechaNacimiento;
  final String genero; // Masculino, Femenino
  final String estadoCivil; // Soltero, Casado, Viudo, Divorciado

  // Datos espirituales
  final bool bautizado;
  final List<String> redesIds;
  final List<String> redesNombres;
  final List<String> ministerios;
  final String rolIglesia;

  // Datos laborales
  final bool trabaja;
  final String profesion;
  final String lugarTrabajo;

  // Datos de membresía
  final String estado; // Activo, Inactivo
  final DateTime fechaIngreso;
  final String? grupoId;
  final String? grupoNombre;
  final String? liderAsignadoId;
  final String? liderAsignadoNombre;
  final String notas;

  // Metadata
  final bool esLider;
  final String rolLider;
  final DateTime fechaRegistro;

  Miembro({
    this.id,
    required this.nombreCompleto,
    this.cedula = '',
    this.email = '',
    this.telefono = '',
    this.direccion = '',
    this.fotoUrl,
    this.fechaNacimiento,
    this.genero = 'Masculino',
    this.estadoCivil = 'Soltero',
    this.bautizado = false,
    this.redesIds = const [],
    this.redesNombres = const [],
    this.ministerios = const [],
    this.rolIglesia = '',
    this.trabaja = false,
    this.profesion = '',
    this.lugarTrabajo = '',
    this.estado = 'Activo',
    required this.fechaIngreso,
    this.grupoId,
    this.grupoNombre,
    this.liderAsignadoId,
    this.liderAsignadoNombre,
    this.notas = '',
    this.esLider = false,
    this.rolLider = '',
    required this.fechaRegistro,
  });

  int get edad {
    if (fechaNacimiento == null) return 0;
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento!.year;
    if (hoy.month < fechaNacimiento!.month ||
        (hoy.month == fechaNacimiento!.month &&
            hoy.day < fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }

  bool get esMayorDeEdad => edad >= 18;

  String get redesTexto =>
      redesNombres.isEmpty ? 'Sin red' : redesNombres.join(', ');

  Map<String, dynamic> toMap() => {
    'nombreCompleto': nombreCompleto,
    'cedula': cedula,
    'email': email,
    'telefono': telefono,
    'direccion': direccion,
    'fotoUrl': fotoUrl,
    'fechaNacimiento': fechaNacimiento,
    'genero': genero,
    'estadoCivil': estadoCivil,
    'bautizado': bautizado,
    'redesIds': redesIds,
    'redesNombres': redesNombres,
    'ministerios': ministerios,
    'rolIglesia': rolIglesia,
    'trabaja': trabaja,
    'profesion': profesion,
    'lugarTrabajo': lugarTrabajo,
    'estado': estado,
    'fechaIngreso': fechaIngreso,
    'grupoId': grupoId,
    'grupoNombre': grupoNombre,
    'liderAsignadoId': liderAsignadoId,
    'liderAsignadoNombre': liderAsignadoNombre,
    'notas': notas,
    'esLider': esLider,
    'rolLider': rolLider,
    'fechaRegistro': fechaRegistro,
  };

  factory Miembro.fromMap(String id,
      Map<String, dynamic> m) =>
      Miembro(
        id: id,
        nombreCompleto: m['nombreCompleto'] ?? '',
        cedula: m['cedula'] ?? '',
        email: m['email'] ?? '',
        telefono: m['telefono'] ?? '',
        direccion: m['direccion'] ?? '',
        fotoUrl: m['fotoUrl'],
        fechaNacimiento: m['fechaNacimiento'] != null
            ? (m['fechaNacimiento'] as dynamic).toDate()
            : null,
        genero: m['genero'] ?? 'Masculino',
        estadoCivil: m['estadoCivil'] ?? 'Soltero',
        bautizado: m['bautizado'] ?? false,
        redesIds: List<String>.from(m['redesIds'] ?? []),
        redesNombres: m['redesNombres'] != null
            ? List<String>.from(m['redesNombres'])
            // Compatibilidad con registros antiguos que solo
            // tenían un campo 'red' de texto único.
            : (m['red'] != null && (m['red'] as String).isNotEmpty
                ? [m['red']]
                : []),
        ministerios:
            List<String>.from(m['ministerios'] ?? []),
        rolIglesia: m['rolIglesia'] ?? '',
        trabaja: m['trabaja'] ?? false,
        profesion: m['profesion'] ?? '',
        lugarTrabajo: m['lugarTrabajo'] ?? '',
        estado: m['estado'] ?? 'Activo',
        fechaIngreso: m['fechaIngreso'] != null
            ? (m['fechaIngreso'] as dynamic).toDate()
            : DateTime.now(),
        grupoId: m['grupoId'],
        grupoNombre: m['grupoNombre'],
        liderAsignadoId: m['liderAsignadoId'],
        liderAsignadoNombre: m['liderAsignadoNombre'],
        notas: m['notas'] ?? '',
        esLider: m['esLider'] ?? false,
        rolLider: m['rolLider'] ?? '',
        fechaRegistro: m['fechaRegistro'] != null
            ? (m['fechaRegistro'] as dynamic).toDate()
            : DateTime.now(),
      );
}