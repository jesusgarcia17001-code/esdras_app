class Grupo {
  final String? id;
  final String nombre;
  final String direccion;
  final String hora;
  final String estado;
  final List<String> lideresLineaIds;
  final List<String> lideresLineaNombres;
  final List<String> lideresCedulaIds;
  final List<String> lideresCedulaNombres;
  final List<String> miembrosIds;
  final List<String> miembrosNombres;
  final DateTime fechaCreacion;

  Grupo({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.hora,
    required this.estado,
    required this.lideresLineaIds,
    required this.lideresLineaNombres,
    required this.lideresCedulaIds,
    required this.lideresCedulaNombres,
    required this.miembrosIds,
    required this.miembrosNombres,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'direccion': direccion,
    'hora': hora,
    'estado': estado,
    'lideresLineaIds': lideresLineaIds,
    'lideresLineaNombres': lideresLineaNombres,
    'lideresCedulaIds': lideresCedulaIds,
    'lideresCedulaNombres': lideresCedulaNombres,
    'miembrosIds': miembrosIds,
    'miembrosNombres': miembrosNombres,
    'fechaCreacion': fechaCreacion,
  };

  factory Grupo.fromMap(String id, Map<String, dynamic> m) => Grupo(
    id: id,
    nombre: m['nombre'] ?? '',
    direccion: m['direccion'] ?? '',
    hora: m['hora'] ?? '',
    estado: m['estado'] ?? 'Activo',
    lideresLineaIds: List<String>.from(m['lideresLineaIds'] ?? []),
    lideresLineaNombres: List<String>.from(m['lideresLineaNombres'] ?? []),
    lideresCedulaIds: List<String>.from(m['lideresCedulaIds'] ?? []),
    lideresCedulaNombres: List<String>.from(m['lideresCedulaNombres'] ?? []),
    miembrosIds: List<String>.from(m['miembrosIds'] ?? []),
    miembrosNombres: List<String>.from(m['miembrosNombres'] ?? []),
    fechaCreacion: (m['fechaCreacion'] as dynamic).toDate(),
  );
}