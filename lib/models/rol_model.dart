class Permiso {
  static const String verMiembros = 'ver_miembros';
  static const String editarMiembros = 'editar_miembros';
  static const String eliminarMiembros = 'eliminar_miembros';
  static const String verGrupos = 'ver_grupos';
  static const String editarGrupos = 'editar_grupos';
  static const String eliminarGrupos = 'eliminar_grupos';
  static const String verAcademia = 'ver_academia';
  static const String editarAcademia = 'editar_academia';
  static const String verRedes = 'ver_redes';
  static const String editarRedes = 'editar_redes';
  static const String verReportes = 'ver_reportes';
  static const String invitarMiembros = 'invitar_miembros';
  static const String cambiarRoles = 'cambiar_roles';
  static const String controlTotal = 'control_total';

  static const List<String> todos = [
    verMiembros,
    editarMiembros,
    eliminarMiembros,
    verGrupos,
    editarGrupos,
    eliminarGrupos,
    verAcademia,
    editarAcademia,
    verRedes,
    editarRedes,
    verReportes,
    invitarMiembros,
    cambiarRoles,
    controlTotal,
  ];

  static String nombre(String permiso) {
    const nombres = {
      'ver_miembros': 'Ver miembros',
      'editar_miembros': 'Editar miembros',
      'eliminar_miembros': 'Eliminar miembros',
      'ver_grupos': 'Ver grupos',
      'editar_grupos': 'Editar grupos',
      'eliminar_grupos': 'Eliminar grupos',
      'ver_academia': 'Ver academia',
      'editar_academia': 'Editar academia',
      'ver_redes': 'Ver redes',
      'editar_redes': 'Editar redes',
      'ver_reportes': 'Ver reportes',
      'invitar_miembros': 'Invitar miembros',
      'cambiar_roles': 'Cambiar roles',
      'control_total': 'Control total',
    };
    return nombres[permiso] ?? permiso;
  }
}

class RolPersonalizado {
  final String? id;
  final String nombre;
  final String descripcion;
  final List<String> permisos;
  final int nivel; // 1=SuperAdmin, 2=Admin, 3=Lider...
  final bool esEditable;
  final DateTime fechaCreacion;

  RolPersonalizado({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.permisos,
    required this.nivel,
    required this.esEditable,
    required this.fechaCreacion,
  });

  bool tienePermiso(String permiso) =>
      permisos.contains(Permiso.controlTotal) ||
      permisos.contains(permiso);

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'permisos': permisos,
    'nivel': nivel,
    'esEditable': esEditable,
    'fechaCreacion': fechaCreacion,
  };

  factory RolPersonalizado.fromMap(
      String id, Map<String, dynamic> m) =>
    RolPersonalizado(
      id: id,
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      permisos: List<String>.from(m['permisos'] ?? []),
      nivel: m['nivel'] ?? 5,
      esEditable: m['esEditable'] ?? true,
      fechaCreacion: (m['fechaCreacion'] as dynamic).toDate(),
    );

  // Roles predeterminados
  static RolPersonalizado superAdmin() => RolPersonalizado(
    nombre: 'Super Admin',
    descripcion: 'Control total de la iglesia',
    permisos: [Permiso.controlTotal],
    nivel: 1,
    esEditable: false,
    fechaCreacion: DateTime.now(),
  );

  static RolPersonalizado pastor() => RolPersonalizado(
    nombre: 'Pastor',
    descripcion: 'Administrador principal',
    permisos: Permiso.todos
        .where((p) => p != Permiso.controlTotal)
        .toList(),
    nivel: 2,
    esEditable: true,
    fechaCreacion: DateTime.now(),
  );

  static RolPersonalizado liderPrincipal() => RolPersonalizado(
    nombre: 'Líder principal',
    descripcion: 'Gestiona líneas y grupos',
    permisos: [
      Permiso.verMiembros,
      Permiso.editarMiembros,
      Permiso.verGrupos,
      Permiso.editarGrupos,
      Permiso.verAcademia,
      Permiso.verRedes,
      Permiso.verReportes,
      Permiso.invitarMiembros,
    ],
    nivel: 3,
    esEditable: true,
    fechaCreacion: DateTime.now(),
  );

  static RolPersonalizado liderLinea() => RolPersonalizado(
    nombre: 'Líder de línea',
    descripcion: 'Supervisa grupos pequeños',
    permisos: [
      Permiso.verMiembros,
      Permiso.verGrupos,
      Permiso.editarGrupos,
      Permiso.verAcademia,
      Permiso.verRedes,
    ],
    nivel: 4,
    esEditable: true,
    fechaCreacion: DateTime.now(),
  );

  static RolPersonalizado liderCedula() => RolPersonalizado(
    nombre: 'Líder de cédula',
    descripcion: 'Lidera su grupo pequeño',
    permisos: [
      Permiso.verMiembros,
      Permiso.verGrupos,
      Permiso.editarGrupos,
    ],
    nivel: 5,
    esEditable: true,
    fechaCreacion: DateTime.now(),
  );
}