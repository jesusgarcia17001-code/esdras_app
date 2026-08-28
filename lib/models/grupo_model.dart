class Grupo {
  final String? id;
  final String nombre;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final String hora;
  final String estado;
  final String? redId;
  final String? redNombre;
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
    this.latitud,
    this.longitud,
    required this.hora,
    required this.estado,
    this.redId,
    this.redNombre,
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
    'latitud': latitud,
    'longitud': longitud,
    'hora': hora,
    'estado': estado,
    'redId': redId,
    'redNombre': redNombre,
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
    latitud: (m['latitud'] as num?)?.toDouble(),
    longitud: (m['longitud'] as num?)?.toDouble(),
    hora: m['hora'] ?? '',
    estado: m['estado'] ?? 'Activo',
    redId: m['redId'],
    redNombre: m['redNombre'],
    lideresLineaIds: List<String>.from(m['lideresLineaIds'] ?? []),
    lideresLineaNombres: List<String>.from(m['lideresLineaNombres'] ?? []),
    lideresCedulaIds: List<String>.from(m['lideresCedulaIds'] ?? []),
    lideresCedulaNombres: List<String>.from(m['lideresCedulaNombres'] ?? []),
    miembrosIds: List<String>.from(m['miembrosIds'] ?? []),
    miembrosNombres: List<String>.from(m['miembrosNombres'] ?? []),
    fechaCreacion: (m['fechaCreacion'] as dynamic).toDate(),
  );
}