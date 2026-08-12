import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/academia_model.dart';
import '../models/miembro_model.dart';
import '../services/firestore_service.dart';

class AcademiaScreen extends StatefulWidget {
  const AcademiaScreen({super.key});

  @override
  State<AcademiaScreen> createState() => _AcademiaScreenState();
}

class _AcademiaScreenState extends State<AcademiaScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        title: const Text('Academia de Líderes',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFBBF24)),
            onPressed: () => _abrirFormularioNivel(context),
          ),
        ],
      ),
      body: StreamBuilder<List<NivelAcademia>>(
        stream: _service.getNiveles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFBBF24)));
          }
          final niveles = snapshot.data ?? [];
          if (niveles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined,
                      color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  const Text('No hay niveles creados',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _abrirFormularioNivel(context),
                    child: const Text('Crear Nivel 1',
                        style:
                            TextStyle(color: Color(0xFFFBBF24))),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: niveles.length,
            itemBuilder: (_, i) => _tarjetaNivel(niveles[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFBBF24),
        onPressed: () => _abrirFormularioNivel(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _tarjetaNivel(NivelAcademia nivel) {
    return GestureDetector(
      onTap: () => _verDetalle(nivel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school,
                        color: Color(0xFFFBBF24), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nivel.nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        if (nivel.descripcion.isNotEmpty)
                          Text(nivel.descripcion,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white24),
                ],
              ),
            ),
            Container(
                height: 0.5,
                color: Colors.white10,
                margin:
                    const EdgeInsets.symmetric(horizontal: 14)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _miniChip(
                      Icons.person_outline,
                      '${nivel.profesoresNombres.length} Prof.',
                      const Color(0xFF60A5FA)),
                  const SizedBox(width: 8),
                  _miniChip(
                      Icons.people_outline,
                      '${nivel.alumnosNombres.length} Alumnos',
                      const Color(0xFFFBBF24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icono, String texto, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  void _verDetalle(NivelAcademia nivel) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DetalleNivelScreen(nivel: nivel)),
    );
  }

  void _abrirFormularioNivel(BuildContext context,
      {NivelAcademia? nivel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioNivel(
        nivel: nivel,
        onGuardar: (n) async {
          if (nivel == null) {
            await _service.agregarNivel(n);
          } else {
            await _service.actualizarNivel(nivel.id!, n);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---- DETALLE NIVEL ----
class DetalleNivelScreen extends StatefulWidget {
  final NivelAcademia nivel;
  const DetalleNivelScreen({super.key, required this.nivel});

  @override
  State<DetalleNivelScreen> createState() => _DetalleNivelScreenState();
}

class _DetalleNivelScreenState extends State<DetalleNivelScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        title: Text(widget.nivel.nombre,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFFBBF24),
          labelColor: const Color(0xFFFBBF24),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Participantes'),
            Tab(text: 'Sesiones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _tabParticipantes(),
          _tabSesiones(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFBBF24),
        onPressed: () => _abrirFormularioSesion(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva sesión',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _tabParticipantes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profesores
          _seccion('PROFESORES', const Color(0xFF60A5FA)),
          if (widget.nivel.profesoresNombres.isEmpty)
            _sinDatos('Sin profesores asignados')
          else
            ...widget.nivel.profesoresNombres
                .map((n) => _chipPersona(
                    n, const Color(0xFF60A5FA), Icons.person)),
          const SizedBox(height: 20),

          // Alumnos
          _seccion('ALUMNOS', const Color(0xFFFBBF24)),
          if (widget.nivel.alumnosNombres.isEmpty)
            _sinDatos('Sin alumnos inscritos')
          else
            ...widget.nivel.alumnosNombres
                .map((n) => _chipPersona(
                    n, const Color(0xFFFBBF24), Icons.school)),
        ],
      ),
    );
  }

  Widget _tabSesiones() {
    return StreamBuilder<List<Sesion>>(
      stream: _service.getSesiones(widget.nivel.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFBBF24)));
        }
        final sesiones = snapshot.data ?? [];
        if (sesiones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                const Text('No hay sesiones registradas',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _abrirFormularioSesion,
                  child: const Text('Registrar primera sesión',
                      style:
                          TextStyle(color: Color(0xFFFBBF24))),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sesiones.length,
          itemBuilder: (_, i) => _tarjetaSesion(sesiones[i]),
        );
      },
    );
  }

  Widget _tarjetaSesion(Sesion s) {
    final fecha =
        DateFormat('dd MMM yyyy', 'es').format(s.fecha);
    final total =
        s.presentesIds.length + s.ausentesIds.length;
    final pct = total > 0
        ? (s.presentesIds.length / total * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.tema,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pct% asist.',
                    style: const TextStyle(
                        color: Color(0xFF34D399), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(fecha,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniChip(Icons.check_circle_outline,
                  '${s.presentesIds.length} presentes',
                  const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _miniChip(Icons.cancel_outlined,
                  '${s.ausentesIds.length} ausentes',
                  Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icono, String texto, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _seccion(String titulo, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(titulo,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chipPersona(String nombre, Color color, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(nombre,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sinDatos(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(texto,
          style:
              const TextStyle(color: Colors.white24, fontSize: 12)),
    );
  }

  void _abrirFormularioSesion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioSesion(
        nivel: widget.nivel,
        onGuardar: (s) async {
          await _service.agregarSesion(widget.nivel.id!, s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---- FORMULARIO NIVEL ----
class FormularioNivel extends StatefulWidget {
  final NivelAcademia? nivel;
  final Function(NivelAcademia) onGuardar;
  const FormularioNivel(
      {super.key, this.nivel, required this.onGuardar});

  @override
  State<FormularioNivel> createState() => _FormularioNivelState();
}

class _FormularioNivelState extends State<FormularioNivel> {
  final _service = FirestoreService();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  List<Miembro> _todosMiembros = [];
  List<Miembro> _profesores = [];
  List<Miembro> _alumnos = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _service.getMiembros().listen((l) {
      setState(() => _todosMiembros = l);
    });
    if (widget.nivel != null) {
      _nombre.text = widget.nivel!.nombre;
      _descripcion.text = widget.nivel!.descripcion;
    }
  }

  void _seleccionar({
    required String titulo,
    required Color color,
    required List<Miembro> seleccionados,
    required Function(List<Miembro>) onConfirmar,
  }) {
    final temp = List<Miembro>.from(seleccionados);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D2E),
          title: Text(titulo,
              style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _todosMiembros.isEmpty
                ? const Center(
                    child: Text('No hay miembros registrados',
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: _todosMiembros.length,
                    itemBuilder: (_, i) {
                      final m = _todosMiembros[i];
                      final sel =
                          temp.any((s) => s.id == m.id);
                      return CheckboxListTile(
                        value: sel,
                        activeColor: color,
                        checkColor: Colors.white,
                        title: Text(m.nombreCompleto,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13)),
                        subtitle: Text(m.red,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11)),
                        onChanged: (v) => setS(() {
                          if (v == true) {
                            temp.add(m);
                          } else {
                            temp.removeWhere(
                                (s) => s.id == m.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white38))),
            TextButton(
                onPressed: () {
                  onConfirmar(temp);
                  Navigator.pop(ctx);
                },
                child: Text('Confirmar',
                    style: TextStyle(color: color))),
          ],
        ),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.nivel == null ? 'Nuevo nivel' : 'Editar nivel',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _campo('NOMBRE DEL NIVEL (ej: Nivel 1)', _nombre),
            _campo('DESCRIPCIÓN', _descripcion),

            _botonSeleccion(
              titulo: 'PROFESORES',
              color: const Color(0xFF60A5FA),
              seleccionados: _profesores,
              icono: Icons.person,
              onTap: () => _seleccionar(
                titulo: 'Seleccionar profesores',
                color: const Color(0xFF60A5FA),
                seleccionados: _profesores,
                onConfirmar: (l) =>
                    setState(() => _profesores = l),
              ),
            ),
            const SizedBox(height: 12),
            _botonSeleccion(
              titulo: 'ALUMNOS',
              color: const Color(0xFFFBBF24),
              seleccionados: _alumnos,
              icono: Icons.school,
              onTap: () => _seleccionar(
                titulo: 'Seleccionar alumnos',
                color: const Color(0xFFFBBF24),
                seleccionados: _alumnos,
                onConfirmar: (l) =>
                    setState(() => _alumnos = l),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : Text(
                        widget.nivel == null
                            ? 'Guardar nivel'
                            : 'Actualizar',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonSeleccion({
    required String titulo,
    required Color color,
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
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            TextButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.add, size: 14, color: color),
              label: Text('Seleccionar',
                  style: TextStyle(color: color, fontSize: 12)),
            ),
          ],
        ),
        if (seleccionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text('Ninguno seleccionado',
                  style: TextStyle(
                      color: Colors.white24, fontSize: 12)),
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
                      ),
                      child: Text(m.nombreCompleto,
                          style: TextStyle(
                              color: color, fontSize: 12)),
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
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(
                color: Colors.white, fontSize: 14),
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

  Future<void> _guardar() async {
    if (_nombre.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del nivel es obligatorio'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final nivel = NivelAcademia(
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      profesoresIds: _profesores.map((m) => m.id!).toList(),
      profesoresNombres:
          _profesores.map((m) => m.nombreCompleto).toList(),
      alumnosIds: _alumnos.map((m) => m.id!).toList(),
      alumnosNombres:
          _alumnos.map((m) => m.nombreCompleto).toList(),
      fechaCreacion: DateTime.now(),
    );
    await widget.onGuardar(nivel);
    setState(() => _cargando = false);
  }
}

// ---- FORMULARIO SESION ----
class FormularioSesion extends StatefulWidget {
  final NivelAcademia nivel;
  final Function(Sesion) onGuardar;
  const FormularioSesion(
      {super.key, required this.nivel, required this.onGuardar});

  @override
  State<FormularioSesion> createState() => _FormularioSesionState();
}

class _FormularioSesionState extends State<FormularioSesion> {
  final _tema = TextEditingController();
  DateTime _fecha = DateTime.now();
  Map<String, bool> _asistencia = {};
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    // Inicializar asistencia con todos los alumnos
    for (final id in widget.nivel.alumnosIds) {
      _asistencia[id] = false;
    }
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nueva sesión',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Tema
            const Text('TEMA DE LA CLASE',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _tema,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fecha
            const Text('FECHA',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (_, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFBBF24)),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _fecha = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1117),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fecha),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Asistencia
            Row(
              children: [
                const Text('ASISTENCIA',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.8)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _asistencia.updateAll((_, __) => true);
                  }),
                  child: const Text('Todos presentes',
                      style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11)),
                ),
              ],
            ),

            if (widget.nivel.alumnosIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay alumnos en este nivel',
                    style: TextStyle(
                        color: Colors.white24, fontSize: 12)),
              )
            else
              ...widget.nivel.alumnosIds
                  .asMap()
                  .entries
                  .map((e) {
                final i = e.key;
                final id = e.value;
                final nombre = widget.nivel.alumnosNombres[i];
                final presente = _asistencia[id] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1117),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CheckboxListTile(
                    value: presente,
                    activeColor: const Color(0xFF34D399),
                    checkColor: Colors.white,
                    title: Text(nombre,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                    secondary: Icon(
                      presente
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: presente
                          ? const Color(0xFF34D399)
                          : Colors.redAccent,
                      size: 20,
                    ),
                    onChanged: (v) => setState(
                        () => _asistencia[id] = v ?? false),
                  ),
                );
              }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Guardar sesión',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_tema.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El tema es obligatorio'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final presentes = _asistencia.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final ausentes = _asistencia.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    final presentesNombres = widget.nivel.alumnosIds
        .asMap()
        .entries
        .where((e) => presentes.contains(e.value))
        .map((e) => widget.nivel.alumnosNombres[e.key])
        .toList();

    final ausentesNombres = widget.nivel.alumnosIds
        .asMap()
        .entries
        .where((e) => ausentes.contains(e.value))
        .map((e) => widget.nivel.alumnosNombres[e.key])
        .toList();

    final sesion = Sesion(
      nivelId: widget.nivel.id!,
      nivelNombre: widget.nivel.nombre,
      fecha: _fecha,
      tema: _tema.text.trim(),
      presentesIds: presentes,
      presentesNombres: presentesNombres,
      ausentesIds: ausentes,
      ausentesNombres: ausentesNombres,
    );
    await widget.onGuardar(sesion);
    setState(() => _cargando = false);
  }
}