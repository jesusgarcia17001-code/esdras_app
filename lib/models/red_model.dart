class Red {
  final String? id;
  final String nombre;
  final String tipo; // Hombres, Mujeres, Jóvenes, Niños, Adultos mayores, Personalizada
  final String icono;
  final List<String> lideresIds;
  final List<String> lideresNombres;
  final List<String> miembrosIds;
  final List<String> miembrosNombres;
  final DateTime fechaCreacion;

  Red({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.lideresIds,
    required this.lideresNombres,
    required this.miembrosIds,
    required this.miembrosNombres,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'tipo': tipo,
    'icono': icono,
    'lideresIds': lideresIds,
    'lideresNombres': lideresNombres,
    'miembrosIds': miembrosIds,
    'miembrosNombres': miembrosNombres,
    'fechaCreacion': fechaCreacion,
  };

  factory Red.fromMap(String id, Map<String, dynamic> m) => Red(
    id: id,
    nombre: m['nombre'] ?? '',
    tipo: m['tipo'] ?? 'Personalizada',
    icono: m['icono'] ?? '👥',
    lideresIds: List<String>.from(m['lideresIds'] ?? []),
    lideresNombres: List<String>.from(m['lideresNombres'] ?? []),
    miembrosIds: List<String>.from(m['miembrosIds'] ?? []),
    miembrosNombres: List<String>.from(m['miembrosNombres'] ?? []),
    fechaCreacion: (m['fechaCreacion'] as dynamic).toDate(),
  );
}