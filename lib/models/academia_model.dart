class NivelAcademia {
  final String? id;
  final String nombre; // Nivel 1, Nivel 2, etc.
  final String descripcion;
  final List<String> profesoresIds;
  final List<String> profesoresNombres;
  final List<String> alumnosIds;
  final List<String> alumnosNombres;
  final DateTime fechaCreacion;

  NivelAcademia({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.profesoresIds,
    required this.profesoresNombres,
    required this.alumnosIds,
    required this.alumnosNombres,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'profesoresIds': profesoresIds,
    'profesoresNombres': profesoresNombres,
    'alumnosIds': alumnosIds,
    'alumnosNombres': alumnosNombres,
    'fechaCreacion': fechaCreacion,
  };

  factory NivelAcademia.fromMap(String id, Map<String, dynamic> m) =>
    NivelAcademia(
      id: id,
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      profesoresIds: List<String>.from(m['profesoresIds'] ?? []),
      profesoresNombres: List<String>.from(m['profesoresNombres'] ?? []),
      alumnosIds: List<String>.from(m['alumnosIds'] ?? []),
      alumnosNombres: List<String>.from(m['alumnosNombres'] ?? []),
      fechaCreacion: (m['fechaCreacion'] as dynamic).toDate(),
    );
}

class Sesion {
  final String? id;
  final String nivelId;
  final String nivelNombre;
  final DateTime fecha;
  final String tema;
  final List<String> presentesIds;
  final List<String> presentesNombres;
  final List<String> ausentesIds;
  final List<String> ausentesNombres;

  Sesion({
    this.id,
    required this.nivelId,
    required this.nivelNombre,
    required this.fecha,
    required this.tema,
    required this.presentesIds,
    required this.presentesNombres,
    required this.ausentesIds,
    required this.ausentesNombres,
  });

  Map<String, dynamic> toMap() => {
    'nivelId': nivelId,
    'nivelNombre': nivelNombre,
    'fecha': fecha,
    'tema': tema,
    'presentesIds': presentesIds,
    'presentesNombres': presentesNombres,
    'ausentesIds': ausentesIds,
    'ausentesNombres': ausentesNombres,
  };

  factory Sesion.fromMap(String id, Map<String, dynamic> m) => Sesion(
    id: id,
    nivelId: m['nivelId'] ?? '',
    nivelNombre: m['nivelNombre'] ?? '',
    fecha: (m['fecha'] as dynamic).toDate(),
    tema: m['tema'] ?? '',
    presentesIds: List<String>.from(m['presentesIds'] ?? []),
    presentesNombres: List<String>.from(m['presentesNombres'] ?? []),
    ausentesIds: List<String>.from(m['ausentesIds'] ?? []),
    ausentesNombres: List<String>.from(m['ausentesNombres'] ?? []),
  );
}