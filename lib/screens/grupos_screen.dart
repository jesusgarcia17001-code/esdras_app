import 'package:flutter/material.dart';
import '../models/grupo_model.dart';
import '../models/miembro_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

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
  final Function(Grupo) onGuardar;

  const FormularioGrupo(
      {super.key, this.grupo, required this.onGuardar});

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
  bool _cargando = false;
  List<Miembro> _todosMiembros = [];
  List<Miembro> _lideresLinea = [];
  List<Miembro> _lideresCedula = [];
  List<Miembro> _miembros = [];

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    if (widget.grupo != null) {
      final g = widget.grupo!;
      _nombre.text = g.nombre;
      _direccion.text = g.direccion;
      _hora.text = g.hora;
      _liderLineaNombre.text = g.lideresLineaNombres.isNotEmpty
    ? g.lideresLineaNombres.first : '';
      _estado = g.estado;
    }
  }

  Future<void> _cargarMiembros() async {
    _service.getMiembros().listen((lista) {
      setState(() => _todosMiembros = lista);
    });
  }

  void _seleccionarPersonas({
    required String titulo,
    required List<Miembro> seleccionados,
    required Function(List<Miembro>) onConfirmar,
    String? filtroRol,
  }) {
    final disponibles = filtroRol != null
        ? _todosMiembros
            .where((m) => m.rolLider == filtroRol)
            .toList()
        : _todosMiembros;
    final tempSel = List<Miembro>.from(seleccionados);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.fondoSecundario,
          title: Text(titulo,
              style: const TextStyle(
                  color: AppColors.textoPrimario)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: disponibles.isEmpty
                ? Center(
                    child: Text(
                      filtroRol != null
                          ? 'No hay líderes con ese rol'
                          : 'No hay miembros registrados',
                      style: const TextStyle(
                          color: AppColors.textoSecundario),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: disponibles.length,
                    itemBuilder: (_, i) {
                      final m = disponibles[i];
                      final sel =
                          tempSel.any((s) => s.id == m.id);
                      return CheckboxListTile(
                        value: sel,
                        activeColor: AppColors.textoPrimario,
                        checkColor: AppColors.fondoPrincipal,
                        title: Text(m.nombreCompleto,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 13)),
                        subtitle: Text(m.red,
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
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
            _campo('HORA DE REUNIÓN (ej: 7:00 PM)', _hora),

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
              onTap: () => _seleccionarPersonas(
                titulo: 'Seleccionar líderes de línea',
                seleccionados: _lideresLinea,
                filtroRol: 'Líder de línea',
                onConfirmar: (lista) =>
                    setState(() => _lideresLinea = lista),
              ),
            ),
            const SizedBox(height: 12),

            _botonSeleccion(
              titulo: 'LÍDERES DE CÉDULA',
              seleccionados: _lideresCedula,
              icono: Icons.person,
              onTap: () => _seleccionarPersonas(
                titulo: 'Seleccionar líderes de cédula',
                seleccionados: _lideresCedula,
                filtroRol: 'Líder de cédula',
                onConfirmar: (lista) =>
                    setState(() => _lideresCedula = lista),
              ),
            ),
            const SizedBox(height: 12),

            _botonSeleccion(
              titulo: 'NUEVOS CREYENTES',
              seleccionados: _miembros,
              icono: Icons.people,
              onTap: () => _seleccionarPersonas(
                titulo: 'Seleccionar nuevos creyentes',
                seleccionados: _miembros,
                onConfirmar: (lista) =>
                    setState(() => _miembros = lista),
              ),
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
                            color: AppColors.fondoPrincipal,
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
    setState(() => _cargando = true);
    final grupo = Grupo(
      nombre: _nombre.text.trim(),
      direccion: _direccion.text.trim(),
      hora: _hora.text.trim(),
      estado: _estado,
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