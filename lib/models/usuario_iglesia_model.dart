class UsuarioIglesia {
  final String uid;
  final String nombreCompleto;
  final String email;
  final String? fotoUrl;
  final String rolId;
  final String rolNombre;
  final List<String> permisos;
  final int nivelRol;
  final String iglesiaId;
  final DateTime fechaIngreso;

  UsuarioIglesia({
    required this.uid,
    required this.nombreCompleto,
    required this.email,
    this.fotoUrl,
    required this.rolId,
    required this.rolNombre,
    required this.permisos,
    required this.nivelRol,
    required this.iglesiaId,
    required this.fechaIngreso,
  });

  bool tienePermiso(String permiso) =>
      permisos.contains('control_total') ||
      permisos.contains(permiso);

  bool puedeGestionarA(UsuarioIglesia otro) =>
      nivelRol < otro.nivelRol;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nombreCompleto': nombreCompleto,
    'email': email,
    'fotoUrl': fotoUrl,
    'rolId': rolId,
    'rolNombre': rolNombre,
    'permisos': permisos,
    'nivelRol': nivelRol,
    'iglesiaId': iglesiaId,
    'fechaIngreso': fechaIngreso,
  };

  factory UsuarioIglesia.fromMap(Map<String, dynamic> m) =>
    UsuarioIglesia(
      uid: m['uid'] ?? '',
      nombreCompleto: m['nombreCompleto'] ?? '',
      email: m['email'] ?? '',
      fotoUrl: m['fotoUrl'],
      rolId: m['rolId'] ?? '',
      rolNombre: m['rolNombre'] ?? 'Sin rol',
      permisos: List<String>.from(m['permisos'] ?? []),
      nivelRol: m['nivelRol'] ?? 99,
      iglesiaId: m['iglesiaId'] ?? '',
      fechaIngreso: (m['fechaIngreso'] as dynamic).toDate(),
    );
}