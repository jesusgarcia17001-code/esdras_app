import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/miembro_model.dart';
import '../models/red_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MiembrosScreen extends StatefulWidget {
  const MiembrosScreen({super.key});

  @override
  State<MiembrosScreen> createState() =>
      _MiembrosScreenState();
}

class _MiembrosScreenState extends State<MiembrosScreen> {
  final _service = FirestoreService();
  String _filtroRed = 'Todos';
  String _filtroEstado = 'Todos';
  String _filtroBautizado = 'Todos';
  String _filtroGenero = 'Todos';
  String _busqueda = '';
  final _buscadorCtrl = TextEditingController();
  bool _importando = false;
  List<Red> _redesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _service.getRedes().listen((lista) {
      setState(() => _redesDisponibles = lista);
    });
  }

  Future<void> _confirmarImportacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoTarjeta,
        title: const Text('Importar miembros',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: const Text(
          'Se van a subir los miembros del archivo base_sinai_perfiles.json '
          'a esta iglesia. Si un miembro ya fue importado antes, se '
          'actualiza en vez de duplicarse. ¿Continuar?',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _importando = true);
    try {
      final cantidad = await _service.importarMiembrosDesdeJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cantidad miembros importados correctamente'),
            backgroundColor: AppColors.exito,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  List<String> get _redes => [
        'Todos',
        ..._redesDisponibles.map((r) => r.nombre),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Miembros'),
        actions: [
          IconButton(
            icon: _importando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Importar miembros desde archivo',
            onPressed: _importando ? null : _confirmarImportacion,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _abrirFormulario(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fondoTarjeta,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borde),
              ),
              child: TextField(
                controller: _buscadorCtrl,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Buscar por nombre, cédula, teléfono...',
                  hintStyle: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 13),
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.textoSecundario,
                      size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) =>
                    setState(() => _busqueda = v.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Miembro>>(
              stream: _service.getMiembros(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white));
                }
                final todos = snapshot.data ?? [];
                final miembros = _filtrar(todos);
                if (miembros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.fondoTarjeta,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.borde),
                          ),
                          child: const Icon(
                              Icons.people_outline,
                              color: AppColors.textoSecundario,
                              size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('No hay miembros registrados',
                            style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 15)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              _abrirFormulario(context),
                          child: const Text(
                              'Registrar primer miembro',
                              style: TextStyle(
                                  color: AppColors.textoPrimario)),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${miembros.length} miembro${miembros.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: miembros.length,
                        itemBuilder: (_, i) =>
                            _tarjetaMiembro(miembros[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fondoTarjeta,
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add,
            color: AppColors.textoPrimario),
      ),
    );
  }

  List<Miembro> _filtrar(List<Miembro> todos) {
    return todos.where((m) {
      if (_filtroRed != 'Todos' &&
          !m.redesNombres.contains(_filtroRed)) {
        return false;
      }
      if (_filtroEstado != 'Todos' &&
          m.estado != _filtroEstado) return false;
      if (_filtroBautizado == 'Bautizados' && !m.bautizado)
        return false;
      if (_filtroBautizado == 'No bautizados' && m.bautizado)
        return false;
      if (_filtroGenero != 'Todos' &&
          m.genero != _filtroGenero) return false;
      if (_busqueda.isNotEmpty) {
        final q = _busqueda;
        if (!m.nombreCompleto.toLowerCase().contains(q) &&
            !m.cedula.toLowerCase().contains(q) &&
            !m.telefono.toLowerCase().contains(q) &&
            !m.email.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              const Text('Filtros',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _labelFiltro('ESTADO'),
              _chipsFiltro(
                ['Todos', 'Activo', 'Inactivo'],
                _filtroEstado,
                (v) => setS(() =>
                    setState(() => _filtroEstado = v)),
              ),
              const SizedBox(height: 12),
              _labelFiltro('BAUTISMO'),
              _chipsFiltro(
                ['Todos', 'Bautizados', 'No bautizados'],
                _filtroBautizado,
                (v) => setS(() =>
                    setState(() => _filtroBautizado = v)),
              ),
              const SizedBox(height: 12),
              _labelFiltro('GÉNERO'),
              _chipsFiltro(
                ['Todos', 'Masculino', 'Femenino'],
                _filtroGenero,
                (v) => setS(() =>
                    setState(() => _filtroGenero = v)),
              ),
              const SizedBox(height: 12),
              _labelFiltro('RED'),
              _chipsFiltro(
                _redes,
                _filtroRed,
                (v) => setS(() =>
                    setState(() => _filtroRed = v)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setS(() => setState(() {
                          _filtroEstado = 'Todos';
                          _filtroBautizado = 'Todos';
                          _filtroGenero = 'Todos';
                          _filtroRed = 'Todos';
                        }));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fondoTarjeta,
                    foregroundColor: AppColors.textoPrimario,
                  ),
                  child: const Text('Limpiar filtros'),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelFiltro(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto,
          style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 11,
              letterSpacing: 0.8)),
    );
  }

  Widget _chipsFiltro(List<String> opciones,
      String seleccionado, Function(String) onTap) {
    return Wrap(
      spacing: 8,
      children: opciones.map((o) {
        final sel = seleccionado == o;
        return GestureDetector(
          onTap: () => onTap(o),
          child: Container(
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
            child: Text(o,
                style: TextStyle(
                    color: sel
                        ? AppColors.fondoPrincipal
                        : AppColors.textoSecundario,
                    fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _tarjetaMiembro(Miembro m) {
    return GestureDetector(
      onTap: () => _verPerfil(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoTarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.acentoSuave,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borde),
              ),
              child: m.fotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(m.fotoUrl!,
                          fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        m.nombreCompleto.isNotEmpty
                            ? m.nombreCompleto[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.textoPrimario,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nombreCompleto,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (m.cedula.isNotEmpty)
                        Text(m.cedula,
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 11)),
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 150),
                        child: _badge(
                          m.redesNombres.isEmpty
                              ? 'Sin red'
                              : m.redesNombres.length == 1
                                  ? m.redesNombres.first
                                  : '${m.redesNombres.first} +${m.redesNombres.length - 1}',
                          ajustarTexto: true,
                        ),
                      ),
                      if (m.bautizado)
                        _badge('✓ Bautizado',
                            color: AppColors.exito),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: m.estado == 'Activo'
                        ? AppColors.exito
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    color: AppColors.textoTerciario, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String texto,
      {Color? color, bool ajustarTexto = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textoSecundario)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          maxLines: 1,
          overflow: ajustarTexto
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: TextStyle(
              color: color ?? AppColors.textoSecundario,
              fontSize: 10)),
    );
  }

  void _verPerfil(Miembro m) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                PerfilMiembroScreen(miembro: m)));
  }

  void _abrirFormulario(BuildContext context,
      {Miembro? miembro}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioMiembroScreen(
          miembro: miembro,
          onGuardar: (m) async {
            if (miembro == null) {
              return await _service.agregarMiembro(m);
            } else {
              await _service.actualizarMiembro(
                  miembro.id!, m);
              return miembro.id;
            }
          },
        ),
      ),
    );
  }
}

// ---- PERFIL MIEMBRO ----
class PerfilMiembroScreen extends StatelessWidget {
  final Miembro miembro;
  const PerfilMiembroScreen(
      {super.key, required this.miembro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Perfil del miembro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormularioMiembroScreen(
                    miembro: miembro,
                    onGuardar: (m) async {
                      final service = FirestoreService();
                      await service.actualizarMiembro(
                          miembro.id!, m);
                      return miembro.id;
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.fondoTarjeta,
                  title: const Text('Eliminar miembro',
                      style: TextStyle(
                          color: AppColors.textoPrimario)),
                  content: Text(
                    '¿Seguro que quieres eliminar a '
                    '${miembro.nombreCompleto}? Esta acción no se '
                    'puede deshacer.',
                    style: const TextStyle(
                        color: AppColors.textoSecundario),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Eliminar',
                          style: TextStyle(
                              color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmar == true && context.mounted) {
                await FirestoreService()
                    .eliminarMiembro(miembro.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Miembro eliminado'),
                      backgroundColor: AppColors.exito,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: miembro.fotoUrl != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(23),
                            child: Image.network(
                                miembro.fotoUrl!,
                                fit: BoxFit.cover))
                        : Center(
                            child: Text(
                              miembro.nombreCompleto.isNotEmpty
                                  ? miembro.nombreCompleto[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.textoPrimario,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(miembro.nombreCompleto,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...miembro.redesNombres.isEmpty
                          ? [_badgePerfil('Sin red')]
                          : miembro.redesNombres
                              .map((r) => _badgePerfil(r)),
                      if (miembro.bautizado)
                        _badgePerfil('✓ Bautizado',
                            color: AppColors.exito),
                      _badgePerfil(miembro.estado,
                          color: miembro.estado == 'Activo'
                              ? AppColors.exito
                              : AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _seccion('INFORMACIÓN PERSONAL', [
              if (miembro.cedula.isNotEmpty)
                _fila('Cédula', miembro.cedula),
              if (miembro.fechaNacimiento != null)
                _fila('Fecha de nacimiento',
                    DateFormat('dd/MM/yyyy')
                        .format(miembro.fechaNacimiento!)),
              if (miembro.fechaNacimiento != null)
                _fila('Edad', '${miembro.edad} años'),
              _fila('Género', miembro.genero),
              _fila('Estado civil', miembro.estadoCivil),
            ]),
            _seccion('CONTACTO', [
              if (miembro.telefono.isNotEmpty)
                _fila('Teléfono', miembro.telefono),
              if (miembro.email.isNotEmpty)
                _fila('Correo', miembro.email),
              if (miembro.direccion.isNotEmpty)
                _fila('Dirección', miembro.direccion),
            ]),
            _seccion('INFORMACIÓN ESPIRITUAL', [
              _fila('Redes', miembro.redesTexto),
              _fila('Bautizado',
                  miembro.bautizado ? 'Sí' : 'No'),
              if (miembro.ministerios.isNotEmpty)
                _fila('Ministerios',
                    miembro.ministerios.join(', ')),
              if (miembro.rolIglesia.isNotEmpty)
                _fila('Rol en iglesia', miembro.rolIglesia),
            ]),
            if (miembro.trabaja)
              _seccion('INFORMACIÓN LABORAL', [
                _fila('Trabaja', 'Sí'),
                if (miembro.profesion.isNotEmpty)
                  _fila('Profesión', miembro.profesion),
                if (miembro.lugarTrabajo.isNotEmpty)
                  _fila('Lugar de trabajo',
                      miembro.lugarTrabajo),
              ]),
            _seccion('MEMBRESÍA', [
              _fila('Fecha de ingreso',
                  DateFormat('dd/MM/yyyy')
                      .format(miembro.fechaIngreso)),
              if (miembro.grupoNombre != null)
                _fila('Grupo', miembro.grupoNombre!),
              if (miembro.liderAsignadoNombre != null)
                _fila('Líder asignado',
                    miembro.liderAsignadoNombre!),
            ]),
            if (miembro.notas.isNotEmpty)
              _seccion('NOTAS', [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fondoTarjeta,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Text(miembro.notas,
                      style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 13,
                          height: 1.5)),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    if (hijos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                color: AppColors.textoTerciario,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(children: hijos),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _fila(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: AppColors.borde, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  static Widget _badgePerfil(String texto, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textoSecundario)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (color ?? AppColors.textoSecundario)
                .withOpacity(0.3)),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color ?? AppColors.textoSecundario,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ---- FORMULARIO COMPLETO ----
class FormularioMiembroScreen extends StatefulWidget {
  final Miembro? miembro;
  final Future<String?> Function(Miembro) onGuardar;

  const FormularioMiembroScreen(
      {super.key, this.miembro, required this.onGuardar});

  @override
  State<FormularioMiembroScreen> createState() =>
      _FormularioMiembroScreenState();
}

class _FormularioMiembroScreenState
    extends State<FormularioMiembroScreen> {
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  bool _cargando = false;
  File? _fotoSeleccionada;
  String? _fotoUrlExistente;

  final _nombre = TextEditingController();
  final _cedula = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _profesion = TextEditingController();
  final _lugarTrabajo = TextEditingController();
  final _notas = TextEditingController();

  String _genero = 'Masculino';
  String _estadoCivil = 'Soltero';
  String _estado = 'Activo';
  bool _bautizado = false;
  bool _trabaja = false;
  bool _esLider = false;
  String _rolLider = 'Pastor';
  DateTime? _fechaNacimiento;
  DateTime _fechaIngreso = DateTime.now();
  List<String> _ministerios = [];

  // Redes desde Firestore (multi-selección)
  List<String> _redesIdsSel = [];
  List<String> _redesSel = [];
  List<Map<String, dynamic>> _redesDisponibles = [];

  // Grupo desde Firestore
  String? _grupoId;
  String _grupoNombre = '';
  List<Map<String, dynamic>> _gruposDisponibles = [];

  String _prefijoCedula = 'V';

  final List<String> _ministeriosDisponibles = [
    'Alabanza', 'Ujieres', 'Danza', 'Teatro',
    'Medios audiovisuales', 'Niños', 'Jóvenes',
    'Intercesión', 'Evangelismo', 'Administración',
  ];

  @override
  void initState() {
    super.initState();
    _cargarRedes();
    _cargarGrupos();
    if (widget.miembro != null) {
      final m = widget.miembro!;
      _nombre.text = m.nombreCompleto;
      if (m.cedula.contains('-')) {
        final partes = m.cedula.split('-');
        _prefijoCedula = partes[0];
        _cedula.text = partes.length > 1 ? partes[1] : '';
      } else {
        _cedula.text = m.cedula;
      }
      _email.text = m.email;
      _telefono.text = m.telefono;
      _direccion.text = m.direccion;
      _profesion.text = m.profesion;
      _lugarTrabajo.text = m.lugarTrabajo;
      _notas.text = m.notas;
      _genero = m.genero;
      _estadoCivil = m.estadoCivil;
      _estado = m.estado;
      _bautizado = m.bautizado;
      _trabaja = m.trabaja;
      _esLider = m.esLider;
      _rolLider = m.rolLider.isEmpty ? 'Pastor' : m.rolLider;
      _fechaNacimiento = m.fechaNacimiento;
      _fechaIngreso = m.fechaIngreso;
      _ministerios = List.from(m.ministerios);
      _fotoUrlExistente = m.fotoUrl;
      _redesIdsSel = List.from(m.redesIds);
      _redesSel = List.from(m.redesNombres);
      _grupoId = m.grupoId;
      _grupoNombre = m.grupoNombre ?? '';
    }
  }

  Future<void> _cargarRedes() async {
    _firestoreService.getRedes().listen((redes) {
      setState(() {
        _redesDisponibles = redes
            .map((r) => {
                  'id': r.id ?? '',
                  'nombre': r.nombre,
                  'tipo': r.tipo,
                })
            .toList();
      });
    });
  }

  Future<void> _cargarGrupos() async {
    _firestoreService.getGrupos().listen((grupos) {
      setState(() {
        _gruposDisponibles = grupos
            .map((g) => {
                  'id': g.id ?? '',
                  'nombre': g.nombre,
                  'hora': g.hora,
                  'direccion': g.direccion,
                })
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: Text(widget.miembro == null
            ? 'Nuevo miembro'
            : 'Editar miembro'),
        actions: [
          TextButton(
            onPressed: _cargando ? null : _guardar,
            child: _cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Guardar',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _seleccionarFoto,
                child: Stack(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.fondoTarjeta,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.bordeActivo),
                      ),
                      child: _fotoSeleccionada != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(23),
                              child: Image.file(
                                  _fotoSeleccionada!,
                                  fit: BoxFit.cover))
                          : _fotoUrlExistente != null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(23),
                                  child: Image.network(
                                      _fotoUrlExistente!,
                                      fit: BoxFit.cover))
                              : const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textoSecundario,
                                  size: 36),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.textoPrimario,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: AppColors.fondoPrincipal,
                            size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _tituloSeccion('DATOS PERSONALES'),
            _campo('Nombre completo *', _nombre),
            _campoCedula(),
            _campo('Teléfono', _telefono,
                tipo: TextInputType.phone),
            _campo('Correo electrónico', _email,
                tipo: TextInputType.emailAddress),
            _campo('Dirección', _direccion),
            _selector('Género', ['Masculino', 'Femenino'],
                _genero, (v) => setState(() => _genero = v)),
            _selector(
                'Estado civil',
                ['Soltero', 'Casado', 'Viudo', 'Divorciado'],
                _estadoCivil,
                (v) => setState(() => _estadoCivil = v)),
            _fechaSelector('Fecha de nacimiento',
                _fechaNacimiento,
                (d) => setState(() => _fechaNacimiento = d)),

            const SizedBox(height: 8),
            _tituloSeccion('INFORMACIÓN ESPIRITUAL'),
            _selectorRed(),
            _switchCampo('Bautizado', _bautizado,
                (v) => setState(() => _bautizado = v)),
            _tituloSeccion('MINISTERIOS'),
            _ministeriosSelector(),

            const SizedBox(height: 8),
            _tituloSeccion('INFORMACIÓN LABORAL'),
            _switchCampo('Trabaja actualmente', _trabaja,
                (v) => setState(() => _trabaja = v)),
            if (_trabaja) ...[
              _campo('Profesión', _profesion),
              _campo('Lugar de trabajo', _lugarTrabajo),
            ],

            const SizedBox(height: 8),
            _tituloSeccion('MEMBRESÍA'),
            _selector('Estado', ['Activo', 'Inactivo'],
                _estado, (v) => setState(() => _estado = v)),
            _fechaSelector('Fecha de ingreso', _fechaIngreso,
                (d) => setState(() => _fechaIngreso = d)),
            _switchCampo('Es líder', _esLider,
                (v) => setState(() => _esLider = v)),
            if (_esLider)
              _selector(
                  'Rol de liderazgo',
                  ['Pastor', 'Líder principal',
                    'Líder de línea', 'Líder de cédula'],
                  _rolLider,
                  (v) => setState(() => _rolLider = v)),
            if (!_esLider) _selectorGrupo(),

            const SizedBox(height: 8),
            _tituloSeccion('NOTAS ADICIONALES'),
            _campoMultilinea('Observaciones', _notas),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(texto,
          style: const TextStyle(
              color: AppColors.textoTerciario,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _campoCedula() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cédula',
            style: TextStyle(
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
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _prefijoCedula,
                    dropdownColor: AppColors.fondoSecundario,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 14),
                    items: ['V', 'E']
                        .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('$p-')))
                        .toList(),
                    onChanged: (p) => setState(
                        () => _prefijoCedula = p!),
                  ),
                ),
              ),
              Container(
                  width: 0.5,
                  height: 40,
                  color: AppColors.borde),
              Expanded(
                child: TextField(
                  controller: _cedula,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12),
                    hintText: '12345678',
                    hintStyle: TextStyle(
                        color: AppColors.textoSecundario),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {TextInputType tipo = TextInputType.text}) {
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
            keyboardType: tipo,
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

  Widget _campoMultilinea(
      String label, TextEditingController ctrl) {
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
            maxLines: 3,
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

  Widget _selector(String label, List<String> opciones,
      String valor, Function(String) onChange) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: opciones.contains(valor)
                  ? valor
                  : opciones.first,
              isExpanded: true,
              dropdownColor: AppColors.fondoSecundario,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 14),
              items: opciones
                  .map((o) => DropdownMenuItem(
                      value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChange(v!),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _switchCampo(String label, bool valor,
      Function(bool) onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 14)),
          const Spacer(),
          Switch(
            value: valor,
            onChanged: onChange,
            activeColor: AppColors.textoPrimario,
            activeTrackColor: AppColors.bordeActivo,
          ),
        ],
      ),
    );
  }

  Widget _fechaSelector(String label, DateTime? valor,
      Function(DateTime) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: valor ?? DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
              builder: (_, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                      primary: Colors.white),
                ),
                child: child!,
              ),
            );
            if (d != null) onChange(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textoSecundario,
                    size: 16),
                const SizedBox(width: 10),
                Text(
                  valor != null
                      ? DateFormat('dd/MM/yyyy').format(valor)
                      : 'Seleccionar fecha',
                  style: TextStyle(
                      color: valor != null
                          ? AppColors.textoPrimario
                          : AppColors.textoSecundario,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _ministeriosSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ministeriosDisponibles.map((min) {
            final sel = _ministerios.contains(min);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _ministerios.remove(min);
                } else {
                  _ministerios.add(min);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
                child: Text(min,
                    style: TextStyle(
                        color: sel
                            ? AppColors.fondoPrincipal
                            : AppColors.textoSecundario,
                        fontSize: 12)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _selectorRed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RED',
            style: TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _mostrarSelectorRed(),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_outlined,
                    color: AppColors.textoSecundario,
                    size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: _redesSel.isEmpty
                      ? const Text(
                          'Seleccionar redes',
                          style: TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 14),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _redesSel
                              .map((nombre) => Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors
                                          .acentoSuave,
                                      borderRadius:
                                          BorderRadius
                                              .circular(20),
                                    ),
                                    child: Text(
                                      nombre,
                                      style: const TextStyle(
                                          color: AppColors
                                              .acento,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight
                                                  .w600),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                if (_redesSel.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _redesIdsSel.clear();
                      _redesSel.clear();
                    }),
                    child: const Icon(Icons.close,
                        color: AppColors.textoSecundario,
                        size: 16),
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: AppColors.textoTerciario,
                      size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _selectorGrupo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GRUPO PEQUEÑO',
            style: TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _mostrarSelectorGrupo(),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_work_outlined,
                    color: AppColors.textoSecundario,
                    size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _grupoNombre.isEmpty
                        ? 'Asignar a un grupo'
                        : _grupoNombre,
                    style: TextStyle(
                        color: _grupoNombre.isEmpty
                            ? AppColors.textoSecundario
                            : AppColors.textoPrimario,
                        fontSize: 14),
                  ),
                ),
                if (_grupoNombre.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _grupoId = null;
                      _grupoNombre = '';
                    }),
                    child: const Icon(Icons.close,
                        color: AppColors.textoSecundario,
                        size: 16),
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: AppColors.textoTerciario,
                      size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _mostrarSelectorRed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seleccionar redes',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Ve al módulo Redes para crear una nueva red'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add,
                      size: 16,
                      color: AppColors.textoPrimario),
                  label: const Text('Nueva red',
                      style: TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 12)),
                ),
              ],
            ),
            const Text(
                'Un miembro puede pertenecer a varias redes',
                style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 12)),
            const SizedBox(height: 12),
            if (_redesDisponibles.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.hub_outlined,
                        color: AppColors.textoSecundario,
                        size: 32),
                    SizedBox(height: 8),
                    Text('No hay redes creadas',
                        style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Ve al módulo Redes para crear una',
                        style: TextStyle(
                            color: AppColors.textoTerciario,
                            fontSize: 12)),
                  ],
                ),
              )
            else ...[
              ...(_redesDisponibles.map((r) {
                final sel = _redesIdsSel.contains(r['id']);
                final emoji =
                    r['tipo'] == 'Hombres' ? '👨' :
                    r['tipo'] == 'Mujeres' ? '👩' :
                    r['tipo'] == 'Jóvenes' ? '🧑' :
                    r['tipo'] == 'Niños' ? '👦' :
                    r['tipo'] == 'Adultos mayores' ? '👴' : '👥';
                return GestureDetector(
                  onTap: () {
                    setS(() {
                      setState(() {
                        if (sel) {
                          _redesIdsSel.remove(r['id']);
                          _redesSel.remove(r['nombre']);
                        } else {
                          _redesIdsSel.add(r['id']);
                          _redesSel.add(r['nombre']);
                        }
                      });
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.acentoSuave
                          : AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? AppColors.bordeActivo
                              : AppColors.borde),
                    ),
                    child: Row(
                      children: [
                        Text(emoji,
                            style: const TextStyle(
                                fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(r['nombre'],
                                  style: const TextStyle(
                                      color: AppColors
                                          .textoPrimario,
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w500)),
                              Text('Red de ${r['tipo']}',
                                  style: const TextStyle(
                                      color: AppColors
                                          .textoSecundario,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          sel
                              ? Icons.check_box
                              : Icons
                                  .check_box_outline_blank,
                          color: sel
                              ? AppColors.acento
                              : AppColors.textoTerciario,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              })),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _mostrarSelectorGrupo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text('Asignar a grupo pequeño',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_gruposDisponibles.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.home_work_outlined,
                        color: AppColors.textoSecundario,
                        size: 32),
                    SizedBox(height: 8),
                    Text('No hay grupos creados',
                        style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Ve al módulo Grupos para crear uno',
                        style: TextStyle(
                            color: AppColors.textoTerciario,
                            fontSize: 12)),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _gruposDisponibles.map((g) {
                    final sel = _grupoId == g['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _grupoId = g['id'];
                          _grupoNombre = g['nombre'];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.acentoSuave
                              : AppColors.fondoTarjeta,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? AppColors.bordeActivo
                                  : AppColors.borde),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.acentoSuave,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.borde),
                              ),
                              child: const Icon(
                                  Icons.home_work_outlined,
                                  color:
                                      AppColors.textoPrimario,
                                  size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(g['nombre'],
                                      style: const TextStyle(
                                          color: AppColors
                                              .textoPrimario,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500)),
                                  Text(
                                      'Jueves · ${g['hora']} · ${g['direccion']}',
                                      style: const TextStyle(
                                          color: AppColors
                                              .textoSecundario,
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis),
                                ],
                              ),
                            ),
                            if (sel)
                              const Icon(Icons.check,
                                  color:
                                      AppColors.textoPrimario,
                                  size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto() async {
    final foto = await _storageService.seleccionarFoto();
    if (foto != null) setState(() => _fotoSeleccionada = foto);
  }

  Future<void> _guardar() async {
    if (_nombre.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);

    String? fotoUrl = _fotoUrlExistente;
    if (_fotoSeleccionada != null) {
      final tempId =
          DateTime.now().millisecondsSinceEpoch.toString();
      fotoUrl = await _storageService.subirFotoMiembro(
          _fotoSeleccionada!, tempId);
    }

    final cedulaCompleta = _cedula.text.isNotEmpty
        ? '$_prefijoCedula-${_cedula.text.trim()}'
        : '';

    final miembro = Miembro(
      nombreCompleto: _nombre.text.trim(),
      cedula: cedulaCompleta,
      email: _email.text.trim(),
      telefono: _telefono.text.trim(),
      direccion: _direccion.text.trim(),
      fotoUrl: fotoUrl,
      fechaNacimiento: _fechaNacimiento,
      genero: _genero,
      estadoCivil: _estadoCivil,
      bautizado: _bautizado,
      redesIds: _redesIdsSel,
      redesNombres: _redesSel,
      ministerios: _ministerios,
      rolIglesia: _esLider ? _rolLider : '',
      trabaja: _trabaja,
      profesion: _profesion.text.trim(),
      lugarTrabajo: _lugarTrabajo.text.trim(),
      estado: _estado,
      fechaIngreso: _fechaIngreso,
      grupoId: _grupoId,
      grupoNombre:
          _grupoNombre.isEmpty ? null : _grupoNombre,
      notas: _notas.text.trim(),
      esLider: _esLider,
      rolLider: _esLider ? _rolLider : '',
      fechaRegistro:
          widget.miembro?.fechaRegistro ?? DateTime.now(),
    );

    final miembroId = await widget.onGuardar(miembro);

    // El miembro se sincroniza hacia adelante: cada red que se le
    // haya asignado aquí lo agrega automáticamente a su propia lista
    // de miembros, sin tener que repetir el trabajo desde Redes.
    if (miembroId != null && _redesIdsSel.isNotEmpty) {
      for (var i = 0; i < _redesIdsSel.length; i++) {
        await _firestoreService.sincronizarPersonasConRed(
          personas: [
            MapEntry(miembroId, _nombre.text.trim())
          ],
          redId: _redesIdsSel[i],
          redNombre:
              i < _redesSel.length ? _redesSel[i] : _redesIdsSel[i],
        );
      }
    }

    setState(() => _cargando = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Miembro guardado correctamente'),
        backgroundColor: AppColors.exito,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}