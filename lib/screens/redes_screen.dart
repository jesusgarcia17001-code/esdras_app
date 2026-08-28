import 'package:flutter/material.dart';
import '../models/red_model.dart';
import '../models/miembro_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class RedesScreen extends StatefulWidget {
  const RedesScreen({super.key});

  @override
  State<RedesScreen> createState() => _RedesScreenState();
}

class _RedesScreenState extends State<RedesScreen> {
  final _service = FirestoreService();

  final List<Map<String, dynamic>> _tiposPredefinidos = [
    {'tipo': 'Hombres', 'icono': '👨'},
    {'tipo': 'Mujeres', 'icono': '👩'},
    {'tipo': 'Jóvenes', 'icono': '🧑'},
    {'tipo': 'Niños', 'icono': '👦'},
    {'tipo': 'Adultos mayores', 'icono': '👴'},
    {'tipo': 'Personalizada', 'icono': '👥'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Redes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirFormulario(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Red>>(
        stream: _service.getRedes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.white));
          }
          final redes = snapshot.data ?? [];
          if (redes.isEmpty) {
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
                    child: const Center(
                        child: Text('👥',
                            style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay redes creadas',
                      style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _abrirFormulario(context),
                    child: const Text('Crear primera red',
                        style: TextStyle(
                            color: AppColors.textoPrimario)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: redes.length,
            itemBuilder: (_, i) => _tarjetaRed(redes[i]),
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

  Widget _tarjetaRed(Red r) {
    return GestureDetector(
      onTap: () => _verDetalle(r),
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.acentoSuave,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: Center(
                      child: Text(r.icono,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.nombre,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Red de ${r.tipo}',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textoSecundario,
                        size: 20),
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
                      if (v == 'editar')
                        _abrirFormulario(context, red: r);
                      if (v == 'eliminar')
                        _confirmarEliminar(r);
                    },
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
                  _miniChip(Icons.star_outline,
                      '${r.lideresIds.length} líderes'),
                  const SizedBox(width: 8),
                  _miniChip(Icons.people_outline,
                      '${r.miembrosIds.length} miembros'),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textoTerciario,
                      size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: AppColors.textoSecundario, size: 12),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(
                color: AppColors.textoSecundario, fontSize: 11)),
      ],
    );
  }

  void _verDetalle(Red r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                  Text(r.icono,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.nombre,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Red de ${r.tipo}',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _seccion('LÍDERES DE LA RED'),
              if (r.lideresNombres.isEmpty)
                _sinDatos('Sin líderes asignados')
              else
                ...r.lideresNombres.map((n) =>
                    _chipPersona(n, Icons.star)),
              const SizedBox(height: 20),
              _seccion('MIEMBROS'),
              if (r.miembrosNombres.isEmpty)
                _sinDatos('Sin miembros asignados')
              else
                ...r.miembrosNombres.map((n) =>
                    _chipPersona(n, Icons.person_outline)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
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

  void _confirmarEliminar(Red r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoSecundario,
        title: const Text('Eliminar red',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: Text('¿Eliminar la red "${r.nombre}"?',
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
              _service.eliminarRed(r.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {Red? red}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioRed(
        red: red,
        tiposPredefinidos: _tiposPredefinidos,
        onGuardar: (r) async {
          if (red == null) {
            await _service.agregarRed(r);
          } else {
            await _service.actualizarRed(red.id!, r);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---- FORMULARIO RED ----
class FormularioRed extends StatefulWidget {
  final Red? red;
  final List<Map<String, dynamic>> tiposPredefinidos;
  final Function(Red) onGuardar;

  const FormularioRed({
    super.key,
    this.red,
    required this.tiposPredefinidos,
    required this.onGuardar,
  });

  @override
  State<FormularioRed> createState() => _FormularioRedState();
}

class _FormularioRedState extends State<FormularioRed> {
  final _service = FirestoreService();
  final _nombre = TextEditingController();
  String _tipo = 'Hombres';
  String _icono = '👨';
  List<Miembro> _todosMiembros = [];
  List<Miembro> _lideres = [];
  List<Miembro> _miembros = [];
  bool _cargando = false;
  bool _seleccionesCargadas = false;

  @override
  void initState() {
    super.initState();
    _service.getMiembros().listen((l) {
      setState(() {
        _todosMiembros = l;
        final r = widget.red;
        if (!_seleccionesCargadas && r != null) {
          _lideres =
              l.where((m) => r.lideresIds.contains(m.id)).toList();
          _miembros =
              l.where((m) => r.miembrosIds.contains(m.id)).toList();
          _seleccionesCargadas = true;
        }
      });
    });
    if (widget.red != null) {
      final r = widget.red!;
      _nombre.text = r.nombre;
      _tipo = r.tipo;
      _icono = r.icono;
    }
  }

  void _seleccionar({
    required String titulo,
    required List<Miembro> seleccionados,
    required Function(List<Miembro>) onConfirmar,
  }) {
    final temp = List<Miembro>.from(seleccionados);
    var busqueda = '';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtrados = busqueda.isEmpty
              ? _todosMiembros
              : _todosMiembros
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
                  if (_todosMiembros.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
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
                    child: _todosMiembros.isEmpty
                        ? const Center(
                            child: Text('No hay miembros registrados',
                                style: TextStyle(
                                    color: AppColors.textoSecundario)))
                        : filtrados.isEmpty
                            ? const Center(
                                child: Text('Sin resultados',
                                    style: TextStyle(
                                        color:
                                            AppColors.textoSecundario)))
                            : ListView.builder(
                                itemCount: filtrados.length,
                                itemBuilder: (_, i) {
                                  final m = filtrados[i];
                                  final sel =
                                      temp.any((s) => s.id == m.id);
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
                    onConfirmar(temp);
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
              widget.red == null ? 'Nueva red' : 'Editar red',
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _campo('NOMBRE DE LA RED', _nombre),

            const Text('TIPO DE RED',
                style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tiposPredefinidos.map((t) {
                final sel = _tipo == t['tipo'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _tipo = t['tipo'];
                    _icono = t['icono'];
                    if (_nombre.text.isEmpty) {
                      _nombre.text = 'Red de ${t['tipo']}';
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.textoPrimario
                          : AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? AppColors.textoPrimario
                              : AppColors.borde),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t['icono'],
                            style: const TextStyle(
                                fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(t['tipo'],
                            style: TextStyle(
                                color: sel
                                    ? AppColors.fondoPrincipal
                                    : AppColors.textoSecundario,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _botonSeleccion(
              titulo: 'LÍDERES DE LA RED',
              seleccionados: _lideres,
              icono: Icons.star,
              onTap: () => _seleccionar(
                titulo: 'Seleccionar líderes',
                seleccionados: _lideres,
                onConfirmar: (l) =>
                    setState(() => _lideres = l),
              ),
            ),
            const SizedBox(height: 12),

            _botonSeleccion(
              titulo: 'MIEMBROS',
              seleccionados: _miembros,
              icono: Icons.people,
              onTap: () => _seleccionar(
                titulo: 'Seleccionar miembros',
                seleccionados: _miembros,
                onConfirmar: (l) =>
                    setState(() => _miembros = l),
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
                            color: AppColors.acentoTexto,
                            strokeWidth: 2))
                    : Text(
                        widget.red == null
                            ? 'Guardar red'
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

  Future<void> _guardar() async {
    if (_nombre.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la red es obligatorio'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final red = Red(
      nombre: _nombre.text.trim(),
      tipo: _tipo,
      icono: _icono,
      lideresIds: _lideres.map((m) => m.id!).toList(),
      lideresNombres:
          _lideres.map((m) => m.nombreCompleto).toList(),
      miembrosIds: _miembros.map((m) => m.id!).toList(),
      miembrosNombres:
          _miembros.map((m) => m.nombreCompleto).toList(),
      fechaCreacion: DateTime.now(),
    );
    await widget.onGuardar(red);
    setState(() => _cargando = false);
  }
}