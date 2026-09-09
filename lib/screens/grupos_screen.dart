import 'package:flutter/material.dart';
import '../models/grupo_model.dart';
import '../models/miembro_model.dart';
import '../models/red_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'mapa_grupos_screen.dart';
import 'redes_screen.dart' show FormularioRed;

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Grupos pequeños'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver mapa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MapaGruposScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirFormulario(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Grupo>>(
        stream: _service.getGrupos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.white));
          }
          final grupos = snapshot.data ?? [];
          if (grupos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: const Icon(
                        Icons.home_work_outlined,
                        color: AppColors.textoSecundario,
                        size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay grupos registrados',
                      style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        _abrirFormulario(context),
                    child: const Text('Crear primer grupo',
                        style: TextStyle(
                            color: AppColors.textoPrimario)),
                  ),
                ],
              ),
            );
          }

          // Se agrupan los grupos pequeños por la red a la que pertenecen,
          // en vez de mostrarlos todos sueltos en una sola lista larga.
          // La clave '__sin_red__' es solo para datos antiguos que se
          // hayan quedado sin red asignada; los grupos nuevos siempre
          // deben tener una red (se exige al guardar en FormularioGrupo).
          final Map<String, List<Grupo>> porRed = {};
          final Map<String, String> nombresPorRed = {};
          for (final g in grupos) {
            final clave = g.redId ?? '__sin_red__';
            porRed.putIfAbsent(clave, () => []).add(g);
            nombresPorRed[clave] =
                (g.redNombre != null && g.redNombre!.isNotEmpty)
                    ? g.redNombre!
                    : 'Sin red asignada';
          }
          final claves = porRed.keys.toList()
            ..sort((a, b) =>
                nombresPorRed[a]!.compareTo(nombresPorRed[b]!));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claves.length,
            itemBuilder: (_, i) {
              final clave = claves[i];
              return _tarjetaRed(
                redId: clave == '__sin_red__' ? null : clave,
                redNombre: nombresPorRed[clave]!,
                gruposDeRed: porRed[clave]!,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fondoTarjeta,
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add,
            color: AppColors.textoPrimario),
      ),
    );
  }

  Widget _tarjetaRed({
    required String? redId,
    required String redNombre,
    required List<Grupo> gruposDeRed,
  }) {
    final activos =
        gruposDeRed.where((g) => g.estado == 'Activo').length;
    final color = colorParaRed(redId ?? '');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GruposDeRedScreen(
            redId: redId,
            redNombre: redNombre,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.fondoTarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                ),
                child: Icon(Icons.hub_outlined,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(redNombre,
                        style: const TextStyle(
                            color: AppColors.textoPrimario,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                        '${gruposDeRed.length} grupo'
                        '${gruposDeRed.length == 1 ? '' : 's'} '
                        'pequeño${gruposDeRed.length == 1 ? '' : 's'}'
                        ' · $activos activo'
                        '${activos == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textoTerciario, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {Grupo? grupo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioGrupo(
        grupo: grupo,
        onGuardar: (g) async {
          if (grupo == null) {
            await _service.agregarGrupo(g);
          } else {
            await _service.actualizarGrupo(grupo.id!, g);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---- PANTALLA DE GRUPOS DE UNA RED ----
// Muestra solo los grupos pequeños que pertenecen a la red indicada.
// Se abre al tocar una tarjeta de red en GruposScreen.
class GruposDeRedScreen extends StatefulWidget {
  final String? redId;
  final String redNombre;

  const GruposDeRedScreen({
    super.key,
    required this.redId,
    required this.redNombre,
  });

  @override
  State<GruposDeRedScreen> createState() =>
      _GruposDeRedScreenState();
}

class _GruposDeRedScreenState extends State<GruposDeRedScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final color = colorParaRed(widget.redId ?? '');
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(widget.redNombre,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirFormulario(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Grupo>>(
        stream: _service.getGrupos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.white));
          }
          final grupos = (snapshot.data ?? [])
              .where((g) => g.redId == widget.redId)
              .toList();
          if (grupos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: const Icon(
                        Icons.home_work_outlined,
                        color: AppColors.textoSecundario,
                        size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Esta red todavía no tiene grupos '
                      'pequeños',
                      style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        _abrirFormulario(context),
                    child: const Text('Crear grupo en esta red',
                        style: TextStyle(
                            color: AppColors.textoPrimario)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grupos.length,
            itemBuilder: (_, i) => _tarjetaGrupo(grupos[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fondoTarjeta,
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add,
            color: AppColors.textoPrimario),
      ),
    );
  }

  Widget _tarjetaGrupo(Grupo g) {
    final colores = {
      'Activo': AppColors.exito,
      'En formación': AppColors.advertencia,
      'Inactivo': AppColors.error,
    };
    final color = colores[g.estado] ?? AppColors.exito;

    return GestureDetector(
      onTap: () => _verDetalle(g),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.fondoTarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.acentoSuave,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: const Icon(Icons.home_work,
                        color: AppColors.textoPrimario,
                        size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(g.nombre,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                            'Jueves · ${g.hora} · ${g.direccion}',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.3)),
                    ),
                    child: Text(g.estado,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: AppColors.borde,
                margin: const EdgeInsets.symmetric(
                    horizontal: 16)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _miniChip('${g.lideresLineaIds.length} Línea'),
                  const SizedBox(width: 8),
                  _miniChip('${g.lideresCedulaIds.length} Cédula'),
                  const SizedBox(width: 8),
                  _miniChip('${g.miembrosIds.length} Miembros'),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textoTerciario, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.acentoSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
      ),
      child: Text(texto,
          style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 10)),
    );
  }

  void _verDetalle(Grupo g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _fichaGrupo(g),
    );
  }

  Widget _fichaGrupo(Grupo g) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(g.nombre,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textoSecundario),
                  color: AppColors.fondoTarjeta,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar',
                            style: TextStyle(
                                color: AppColors.textoPrimario))),
                    const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar',
                            style: TextStyle(
                                color: AppColors.error))),
                  ],
                  onSelected: (v) {
                    Navigator.pop(context);
                    if (v == 'editar')
                      _abrirFormulario(context, grupo: g);
                    if (v == 'eliminar')
                      _confirmarEliminar(g);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Jueves · ${g.hora} · ${g.direccion}',
                style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 13)),
            const SizedBox(height: 24),

            _seccionFicha('LÍDERES DE LÍNEA'),
            if (g.lideresLineaNombres.isEmpty)
              _sinDatos('Sin líderes de línea asignados')
            else
              ...g.lideresLineaNombres
                  .map((n) => _chipPersona(n,
                      Icons.supervisor_account)),
            const SizedBox(height: 16),

            _seccionFicha('LÍDERES DE CÉDULA'),
            if (g.lideresCedulaNombres.isEmpty)
              _sinDatos('Sin líderes de cédula asignados')
            else
              ...g.lideresCedulaNombres
                  .map((n) => _chipPersona(n, Icons.person)),
            const SizedBox(height: 16),

            _seccionFicha('NUEVOS CREYENTES'),
            if (g.miembrosNombres.isEmpty)
              _sinDatos('Sin miembros asignados')
            else
              ...g.miembrosNombres.map((n) =>
                  _chipPersona(n, Icons.person_outline)),
          ],
        ),
      ),
    );
  }

  Widget _seccionFicha(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(titulo,
          style: const TextStyle(
              color: AppColors.textoTerciario,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _chipPersona(String nombre, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borde),
            ),
            child: Icon(icono,
                color: AppColors.textoPrimario, size: 16),
          ),
          const SizedBox(width: 10),
          Text(nombre,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sinDatos(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(texto,
          style: const TextStyle(
              color: AppColors.textoTerciario, fontSize: 12)),
    );
  }

  void _confirmarEliminar(Grupo g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoSecundario,
        title: const Text('Eliminar grupo',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: Text('¿Eliminar el grupo "${g.nombre}"?',
            style: const TextStyle(
                color: AppColors.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(
                    color: AppColors.textoSecundario)),
          ),
          TextButton(
            onPressed: () {
              _service.eliminarGrupo(g.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario(BuildContext context,
      {Grupo? grupo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioGrupo(
        grupo: grupo,
        redIdInicial: widget.redId,
        redNombreInicial: widget.redNombre,
        onGuardar: (g) async {
          if (grupo == null) {
            await _service.agregarGrupo(g);
          } else {
            await _service.actualizarGrupo(grupo.id!, g);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---- FORMULARIO GRUPO ----
class FormularioGrupo extends StatefulWidget {
  final Grupo? grupo;
  final String? redIdInicial;
  final String? redNombreInicial;
  final Function(Grupo) onGuardar;

  const FormularioGrupo({
    super.key,
    this.grupo,
    this.redIdInicial,
    this.redNombreInicial,
    required this.onGuardar,
  });

  @override
  State<FormularioGrupo> createState() =>
      _FormularioGrupoState();
}

class _FormularioGrupoState extends State<FormularioGrupo> {
  final _service = FirestoreService();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _hora = TextEditingController();
  final _liderLineaNombre = TextEditingController();
  String _estado = 'Activo';
  String? _redId;
  String _redNombre = '';
  List<Red> _redesDisponibles = [];
  double? _latitud;
  double? _longitud;
  bool _cargando = false;
  List<Miembro> _todosMiembros = [];
  List<Miembro> _lideresLinea = [];
  List<Miembro> _lideresCedula = [];
  List<Miembro> _miembros = [];
  bool _seleccionesCargadas = false;

  // Mismos tipos predefinidos que en RedesScreen, para poder crear una
  // red nueva sin salir de este formulario si la que se necesita no
  // existe todavía.
  final List<Map<String, dynamic>> _tiposRedPredefinidos = const [
    {'tipo': 'Hombres', 'icono': '👨'},
    {'tipo': 'Mujeres', 'icono': '👩'},
    {'tipo': 'Jóvenes', 'icono': '🧑'},
    {'tipo': 'Niños', 'icono': '👦'},
    {'tipo': 'Adultos mayores', 'icono': '👴'},
    {'tipo': 'Personalizada', 'icono': '👥'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    _cargarRedes();
    if (widget.grupo != null) {
      final g = widget.grupo!;
      _nombre.text = g.nombre;
      _direccion.text = g.direccion;
      _hora.text = g.hora;
      _liderLineaNombre.text = g.lideresLineaNombres.isNotEmpty
    ? g.lideresLineaNombres.first : '';
      _estado = g.estado;
      _redId = g.redId;
      _redNombre = g.redNombre ?? '';
      _latitud = g.latitud;
      _longitud = g.longitud;
    } else if (widget.redIdInicial != null) {
      // Se llegó aquí desde la pantalla de una red específica: se
      // preselecciona esa red, pero el usuario todavía puede cambiarla.
      _redId = widget.redIdInicial;
      _redNombre = widget.redNombreInicial ?? '';
    }
  }

  Future<void> _cargarRedes() async {
    _service.getRedes().listen((lista) {
      setState(() => _redesDisponibles = lista);
    });
  }


  Future<void> _cargarMiembros() async {
    _service.getMiembros().listen((lista) {
      setState(() {
        _todosMiembros = lista;
        // Al editar un grupo, se preseleccionan los líderes y miembros
        // que ya tenía asignados (solo la primera vez que carga la lista).
        final g = widget.grupo;
        if (!_seleccionesCargadas && g != null) {
          _lideresLinea = lista
              .where((m) => g.lideresLineaIds.contains(m.id))
              .toList();
          _lideresCedula = lista
              .where((m) => g.lideresCedulaIds.contains(m.id))
              .toList();
          _miembros = lista
              .where((m) => g.miembrosIds.contains(m.id))
              .toList();
          _seleccionesCargadas = true;
        }
      });
    });
  }

  void _seleccionarPersonas({
    required String titulo,
    required List<Miembro> seleccionados,
    required Function(List<Miembro>) onConfirmar,
    String? filtroRol,
    String? redId,
    bool soloCreyentes = false,
  }) {
    // Filtra siempre por la red seleccionada del grupo (cada lista de
    // líderes/creyentes debe salir SOLO de esa red), y además por rol
    // cuando aplica (líder de línea / líder de cédula / creyente).
    final disponibles = _todosMiembros.where((m) {
      if (redId != null && !m.redesIds.contains(redId)) return false;
      if (filtroRol != null && m.rolLider != filtroRol) return false;
      if (soloCreyentes && m.esLider) return false;
      return true;
    }).toList();
    final tempSel = List<Miembro>.from(seleccionados);
    var busqueda = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtrados = busqueda.isEmpty
              ? disponibles
              : disponibles
                  .where((m) => m.nombreCompleto
                      .toLowerCase()
                      .contains(busqueda.toLowerCase()))
                  .toList();
          return AlertDialog(
            backgroundColor: AppColors.fondoSecundario,
            title: Text(titulo,
                style: const TextStyle(
                    color: AppColors.textoPrimario)),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                children: [
                  if (disponibles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        autofocus: false,
                        style: const TextStyle(
                            color: AppColors.textoPrimario,
                            fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          hintStyle: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textoSecundario,
                              size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.fondoInput,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setS(() => busqueda = v),
                      ),
                    ),
                  Expanded(
                    child: disponibles.isEmpty
                        ? Center(
                            child: Text(
                              filtroRol != null
                                  ? 'Esta red no tiene "$filtroRol" registrados'
                                  : (soloCreyentes
                                      ? 'Esta red no tiene creyentes '
                                          'registrados'
                                      : 'No hay miembros registrados'),
                              style: const TextStyle(
                                  color: AppColors.textoSecundario),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : filtrados.isEmpty
                            ? const Center(
                                child: Text(
                                  'Sin resultados',
                                  style: TextStyle(
                                      color: AppColors.textoSecundario),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtrados.length,
                                itemBuilder: (_, i) {
                                  final m = filtrados[i];
                                  final sel = tempSel
                                      .any((s) => s.id == m.id);
                                  return CheckboxListTile(
                                    value: sel,
                                    activeColor:
                                        AppColors.textoPrimario,
                                    checkColor:
                                        AppColors.fondoPrincipal,
                                    title: Text(m.nombreCompleto,
                                        style: const TextStyle(
                                            color:
                                                AppColors.textoPrimario,
                                            fontSize: 13)),
                                    subtitle: Text(m.redesTexto,
                                        style: const TextStyle(
                                            color: AppColors
                                                .textoSecundario,
                                            fontSize: 11)),
                                    onChanged: (v) => setS(() {
                                      if (v == true) {
                                        tempSel.add(m);
                                      } else {
                                        tempSel.removeWhere(
                                            (s) => s.id == m.id);
                                      }
                                    }),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: AppColors.textoSecundario))),
              TextButton(
                  onPressed: () {
                    onConfirmar(tempSel);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirmar',
                      style: TextStyle(
                          color: AppColors.textoPrimario))),
            ],
          );
        },
      ),
    );
  }

  void _seleccionarRed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoSecundario,
        title: const Text('Seleccionar red',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _redesDisponibles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8),
                          child: Text(
                            'Todavía no has creado ninguna red.\n'
                            'Crea la primera para poder asignarle '
                            'este grupo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _redesDisponibles.length,
                        itemBuilder: (_, i) {
                          final r = _redesDisponibles[i];
                          return ListTile(
                            leading: Text(r.icono,
                                style:
                                    const TextStyle(fontSize: 20)),
                            title: Text(r.nombre,
                                style: const TextStyle(
                                    color: AppColors.textoPrimario,
                                    fontSize: 14)),
                            subtitle: Text(
                                '${r.lideresIds.length} líderes',
                                style: const TextStyle(
                                    color:
                                        AppColors.textoSecundario,
                                    fontSize: 11)),
                            onTap: () {
                              setState(() {
                                // Si cambia de red, se limpian los
                                // líderes/creyentes ya elegidos que
                                // no pertenezcan a la nueva red, para
                                // no arrastrar gente de la red
                                // anterior.
                                if (_redId != r.id) {
                                  _lideresLinea = _lideresLinea
                                      .where((m) =>
                                          m.redesIds.contains(r.id) &&
                                          m.rolLider ==
                                              'Líder de línea')
                                      .toList();
                                  _lideresCedula = _lideresCedula
                                      .where((m) =>
                                          m.redesIds.contains(r.id) &&
                                          m.rolLider ==
                                              'Líder de cédula')
                                      .toList();
                                  _miembros = _miembros
                                      .where((m) =>
                                          m.redesIds.contains(r.id) &&
                                          !m.esLider)
                                      .toList();
                                }
                                _redId = r.id;
                                _redNombre = r.nombre;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              Container(height: 0.5, color: AppColors.borde),
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: AppColors.textoPrimario),
                title: const Text('Crear nueva red',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _crearRedYSeleccionar();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textoSecundario)),
          ),
        ],
      ),
    );
  }

  // Abre el mismo formulario que se usa en la pantalla de Redes para
  // crear una red nueva, sin salir de este formulario de grupo. Al
  // guardarse, la nueva red queda seleccionada automáticamente.
  void _crearRedYSeleccionar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioRed(
        tiposPredefinidos: _tiposRedPredefinidos,
        onGuardar: (r) async {
          final nuevoId = await _service.agregarRed(r);
          if (!mounted) return;
          Navigator.pop(context);
          if (nuevoId != null) {
            setState(() {
              _redId = nuevoId;
              _redNombre = r.nombre;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo crear la red, intenta '
                    'de nuevo'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.grupo == null
                  ? 'Nuevo grupo'
                  : 'Editar grupo',
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _campo('NOMBRE DEL GRUPO', _nombre),
            _campo('DIRECCIÓN / BARRIO', _direccion),
            GestureDetector(
              onTap: _marcarUbicacion,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fondoInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitud != null
                          ? Icons.location_on
                          : Icons.location_on_outlined,
                      color: _latitud != null
                          ? AppColors.exito
                          : AppColors.textoSecundario,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latitud != null
                            ? 'Ubicación marcada en el mapa'
                            : 'Marcar ubicación en el mapa (opcional)',
                        style: const TextStyle(
                            color: AppColors.textoPrimario, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textoSecundario, size: 18),
                  ],
                ),
              ),
            ),
            _campo('HORA DE REUNIÓN (ej: 7:00 PM)', _hora),

            _labelSeccion('RED'),
            GestureDetector(
              onTap: _seleccionarRed,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fondoInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _redId != null
                        ? AppColors.exito
                        : AppColors.borde,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      color: _redId != null
                          ? AppColors.exito
                          : AppColors.textoSecundario,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _redId != null
                            ? _redNombre
                            : 'Selecciona la red a la que pertenece',
                        style: const TextStyle(
                            color: AppColors.textoPrimario, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textoSecundario, size: 18),
                  ],
                ),
              ),
            ),

            _labelSeccion('ESTADO'),
            Wrap(
              spacing: 8,
              children: ['Activo', 'En formación', 'Inactivo']
                  .map((e) {
                final sel = _estado == e;
                return GestureDetector(
                  onTap: () => setState(() => _estado = e),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.textoPrimario
                          : AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? AppColors.textoPrimario
                              : AppColors.borde),
                    ),
                    child: Text(e,
                        style: TextStyle(
                            color: sel
                                ? AppColors.fondoPrincipal
                                : AppColors.textoSecundario,
                            fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            _botonSeleccion(
              titulo: 'LÍDERES DE LÍNEA',
              seleccionados: _lideresLinea,
              icono: Icons.supervisor_account,
              onTap: () {
                if (_redId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero selecciona la red'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                _seleccionarPersonas(
                  titulo: 'Líderes de línea de $_redNombre',
                  seleccionados: _lideresLinea,
                  redId: _redId,
                  filtroRol: 'Líder de línea',
                  onConfirmar: (lista) =>
                      setState(() => _lideresLinea = lista),
                );
              },
            ),
            const SizedBox(height: 12),

            _botonSeleccion(
              titulo: 'LÍDERES DE CÉDULA',
              seleccionados: _lideresCedula,
              icono: Icons.person,
              onTap: () {
                if (_redId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero selecciona la red'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                _seleccionarPersonas(
                  titulo: 'Líderes de cédula de $_redNombre',
                  seleccionados: _lideresCedula,
                  redId: _redId,
                  filtroRol: 'Líder de cédula',
                  onConfirmar: (lista) =>
                      setState(() => _lideresCedula = lista),
                );
              },
            ),
            const SizedBox(height: 12),

            _botonSeleccion(
              titulo: 'NUEVOS CREYENTES',
              seleccionados: _miembros,
              icono: Icons.people,
              onTap: () {
                if (_redId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero selecciona la red'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                _seleccionarPersonas(
                  titulo: 'Nuevos creyentes de $_redNombre',
                  seleccionados: _miembros,
                  redId: _redId,
                  soloCreyentes: true,
                  onConfirmar: (lista) =>
                      setState(() => _miembros = lista),
                );
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.acentoTexto,
                            strokeWidth: 2))
                    : Text(
                        widget.grupo == null
                            ? 'Guardar grupo'
                            : 'Actualizar',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonSeleccion({
    required String titulo,
    required List<Miembro> seleccionados,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo,
                style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add,
                  size: 14, color: AppColors.textoPrimario),
              label: const Text('Seleccionar',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 12)),
            ),
          ],
        ),
        if (seleccionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: const Center(
              child: Text('Ninguno seleccionado',
                  style: TextStyle(
                      color: AppColors.textoTerciario,
                      fontSize: 12)),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: seleccionados
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.acentoSuave,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.bordeActivo),
                      ),
                      child: Text(m.nombreCompleto,
                          style: const TextStyle(
                              color: AppColors.textoPrimario,
                              fontSize: 12)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(
                color: AppColors.textoPrimario, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _labelSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto,
          style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 11,
              letterSpacing: 0.8)),
    );
  }

  Future<void> _marcarUbicacion() async {
    final resultado = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorUbicacionMapa(
          latitudInicial: _latitud,
          longitudInicial: _longitud,
        ),
      ),
    );
    if (resultado != null) {
      setState(() {
        _latitud = resultado['lat'];
        _longitud = resultado['lng'];
      });
    }
  }

  Future<void> _guardar() async {
    if (_nombre.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del grupo es obligatorio'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_redId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debes seleccionar (o crear) la red a la que '
              'pertenece este grupo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final grupo = Grupo(
      nombre: _nombre.text.trim(),
      direccion: _direccion.text.trim(),
      latitud: _latitud,
      longitud: _longitud,
      hora: _hora.text.trim(),
      estado: _estado,
      redId: _redId,
      redNombre: _redNombre.isEmpty ? null : _redNombre,
      lideresLineaIds:
          _lideresLinea.map((m) => m.id!).toList(),
      lideresLineaNombres:
          _lideresLinea.map((m) => m.nombreCompleto).toList(),
      lideresCedulaIds:
          _lideresCedula.map((m) => m.id!).toList(),
      lideresCedulaNombres:
          _lideresCedula.map((m) => m.nombreCompleto).toList(),
      miembrosIds: _miembros.map((m) => m.id!).toList(),
      miembrosNombres:
          _miembros.map((m) => m.nombreCompleto).toList(),
      fechaCreacion: DateTime.now(),
    );
    await widget.onGuardar(grupo);
    setState(() => _cargando = false);
  }
}