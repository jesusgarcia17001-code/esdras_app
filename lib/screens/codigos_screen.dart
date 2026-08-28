import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/iglesia_service.dart';
import '../services/roles_service.dart';
import '../models/rol_model.dart';
import '../theme/app_theme.dart';

class CodigosScreen extends StatefulWidget {
  final String iglesiaId;
  const CodigosScreen({super.key, required this.iglesiaId});

  @override
  State<CodigosScreen> createState() => _CodigosScreenState();
}

class _CodigosScreenState extends State<CodigosScreen> {
  final _iglesiaService = IglesiaService();
  final _rolesService = RolesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: const Text('Códigos de invitación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _generarCodigo(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream:
            _iglesiaService.getCodigos(widget.iglesiaId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.white));
          }
          final codigos = snapshot.data!;
          if (codigos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjeta,
                      borderRadius:
                          BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.borde),
                    ),
                    child: const Icon(Icons.key_outlined,
                        color: AppColors.textoSecundario,
                        size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay códigos generados',
                      style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _generarCodigo,
                    child: const Text(
                        'Generar primer código',
                        style: TextStyle(
                            color: AppColors.textoPrimario)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codigos.length,
            itemBuilder: (_, i) =>
                _tarjetaCodigo(codigos[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fondoTarjeta,
        onPressed: _generarCodigo,
        child: const Icon(Icons.add,
            color: AppColors.textoPrimario),
      ),
    );
  }

  Widget _tarjetaCodigo(Map<String, dynamic> c) {
    final activo = c['activo'] as bool;
    final expiracion =
        (c['fechaExpiracion'] as dynamic).toDate();
    final expirado = DateTime.now().isAfter(expiracion);
    final usos = c['usosActuales'] as int;
    final limite = c['limiteUsos'] as int;
    final usuarios =
        List<Map<String, dynamic>>.from(c['usuarios'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activo && !expirado
              ? AppColors.bordeActivo
              : AppColors.borde,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Código
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c['codigo'],
                            style: const TextStyle(
                              color: AppColors.textoPrimario,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(
                                      text: c['codigo']));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Código copiado'),
                                  behavior: SnackBarBehavior
                                      .floating,
                                ),
                              );
                            },
                            child: const Icon(
                                Icons.copy_outlined,
                                color:
                                    AppColors.textoSecundario,
                                size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rol: ${c['rolNombre']}',
                        style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activo && !expirado
                            ? AppColors.exito.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: activo && !expirado
                              ? AppColors.exito
                                  .withOpacity(0.3)
                              : AppColors.error
                                  .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        expirado
                            ? 'Expirado'
                            : activo
                                ? 'Activo'
                                : 'Desactivado',
                        style: TextStyle(
                          color: activo && !expirado
                              ? AppColors.exito
                              : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (activo && !expirado) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            _iglesiaService.desactivarCodigo(
                                widget.iglesiaId, c['id']),
                        child: const Text('Desactivar',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
              height: 0.5,
              color: AppColors.borde,
              margin: const EdgeInsets.symmetric(
                  horizontal: 16)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _infoChip(Icons.people_outline,
                    '$usos/$limite usos'),
                const SizedBox(width: 8),
                _infoChip(
                    Icons.timer_outlined,
                    'Expira: ${DateFormat('dd/MM/yy').format(expiracion)}'),
                const Spacer(),
                if (usuarios.isNotEmpty)
                  GestureDetector(
                    onTap: () => _verUsuarios(usuarios),
                    child: const Text('Ver usuarios →',
                        style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono,
            color: AppColors.textoSecundario, size: 12),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11)),
      ],
    );
  }

  void _verUsuarios(List<Map<String, dynamic>> usuarios) {
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Usuarios que usaron este código',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...usuarios.map((u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fondoTarjeta,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.acentoSuave,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            (u['nombre'] as String)
                                    .isNotEmpty
                                ? (u['nombre'] as String)[0]
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color:
                                    AppColors.textoPrimario,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(u['nombre'],
                                style: const TextStyle(
                                    color:
                                        AppColors.textoPrimario,
                                    fontSize: 13)),
                            Text(u['email'],
                                style: const TextStyle(
                                    color: AppColors
                                        .textoSecundario,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _generarCodigo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoSecundario,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioCodigo(
        iglesiaId: widget.iglesiaId,
        rolesService: _rolesService,
        iglesiaService: _iglesiaService,
        onGenerado: (codigo) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Código generado: ${codigo['codigo']}'),
              backgroundColor: AppColors.exito,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

// ---- FORMULARIO CÓDIGO ----
class FormularioCodigo extends StatefulWidget {
  final String iglesiaId;
  final RolesService rolesService;
  final IglesiaService iglesiaService;
  final Function(Map<String, dynamic>) onGenerado;

  const FormularioCodigo({
    super.key,
    required this.iglesiaId,
    required this.rolesService,
    required this.iglesiaService,
    required this.onGenerado,
  });

  @override
  State<FormularioCodigo> createState() =>
      _FormularioCodigoState();
}

class _FormularioCodigoState extends State<FormularioCodigo> {
  RolPersonalizado? _rolSeleccionado;
  int _diasExpiracion = 7;
  int _limiteUsos = 1;
  bool _cargando = false;
  List<RolPersonalizado> _roles = [];

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    widget.rolesService
        .getRoles(widget.iglesiaId)
        .listen((roles) {
      setState(() {
        _roles = roles;
        if (roles.isNotEmpty) _rolSeleccionado = roles.last;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borde,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Generar código de invitación',
              style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Rol
          const Text('ROL A ASIGNAR',
              style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 11,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<RolPersonalizado>(
                value: _rolSeleccionado,
                isExpanded: true,
                dropdownColor: AppColors.fondoSecundario,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 14),
                items: _roles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.nombre),
                        ))
                    .toList(),
                onChanged: (r) =>
                    setState(() => _rolSeleccionado = r),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Días de expiración
          const Text('EXPIRA EN',
              style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 11,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [1, 3, 7, 15, 30].map((dias) {
              final sel = _diasExpiracion == dias;
              return GestureDetector(
                onTap: () =>
                    setState(() => _diasExpiracion = dias),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
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
                  child: Text(
                    '${dias}d',
                    style: TextStyle(
                        color: sel
                            ? AppColors.fondoPrincipal
                            : AppColors.textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Límite de usos
          const Text('LÍMITE DE USOS',
              style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 11,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 5, 10, 20].map((usos) {
              final sel = _limiteUsos == usos;
              return GestureDetector(
                onTap: () =>
                    setState(() => _limiteUsos = usos),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
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
                  child: Text(
                    '$usos',
                    style: TextStyle(
                        color: sel
                            ? AppColors.fondoPrincipal
                            : AppColors.textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textoSecundario,
                    size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El código tendrá rol "${_rolSeleccionado?.nombre ?? ''}", expira en $_diasExpiracion días y permite $_limiteUsos uso(s).',
                    style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cargando ? null : _generar,
              child: _cargando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.acentoTexto,
                          strokeWidth: 2))
                  : const Text('Generar código',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generar() async {
    if (_rolSeleccionado == null) return;
    setState(() => _cargando = true);
    final resultado =
        await widget.iglesiaService.generarCodigo(
      iglesiaId: widget.iglesiaId,
      rolId: _rolSeleccionado!.id ?? '',
      rolNombre: _rolSeleccionado!.nombre,
      diasExpiracion: _diasExpiracion,
      limiteUsos: _limiteUsos,
    );
    setState(() => _cargando = false);
    if (resultado != null) {
      widget.onGenerado(resultado);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el código. Intenta de nuevo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}