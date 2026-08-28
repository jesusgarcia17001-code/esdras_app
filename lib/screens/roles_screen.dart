import 'package:flutter/material.dart';
import '../models/rol_model.dart';
import '../models/usuario_iglesia_model.dart';
import '../services/roles_service.dart';
import '../services/iglesia_service.dart';
import '../theme/app_theme.dart';
import 'codigos_screen.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen>
    with SingleTickerProviderStateMixin {
  final _rolesService = RolesService();
  final _iglesiaService = IglesiaService();
  late TabController _tabCtrl;
  String? _iglesiaId;
  UsuarioIglesia? _usuarioActual;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await _iglesiaService.getUsuario();
    if (usuario?.iglesiaId != null) {
      setState(() => _iglesiaId = usuario!.iglesiaId);
      final u = await _rolesService
          .getUsuarioActual(usuario!.iglesiaId!);
      setState(() => _usuarioActual = u);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
appBar: AppBar(
  backgroundColor: AppColors.fondoPrincipal,
  title: const Text('Roles y permisos'),
  actions: [
    IconButton(
      icon: const Icon(Icons.key_outlined),
      tooltip: 'Códigos de invitación',
      onPressed: () {
        if (_iglesiaId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CodigosScreen(iglesiaId: _iglesiaId!),
            ),
          );
        }
      },
    ),
  ],
  bottom: TabBar(controller: _tabCtrl,
  indicatorColor: AppColors.textoPrimario,
  labelColor: AppColors.textoPrimario,
  unselectedLabelColor: AppColors.textoSecundario,
  tabs: const [
    Tab(text: 'Miembros'),
    Tab(text: 'Roles'),
  ],),
),
      
      body: _iglesiaId == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6B5EFF)))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _tabMiembros(),
                _tabRoles(),
              ],
            ),
      floatingActionButton: _tabCtrl.index == 1 &&
              (_usuarioActual?.tienePermiso(
                      Permiso.controlTotal) ??
                  false)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6B5EFF),
              onPressed: () => _abrirFormularioRol(),
              child: const Icon(Icons.add, color: AppColors.textoPrimario),
            )
          : null,
    );
  }

  Widget _tabMiembros() {
    return StreamBuilder<List<UsuarioIglesia>>(
      stream: _rolesService.getUsuariosIglesia(_iglesiaId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6B5EFF)));
        }
        final usuarios = snapshot.data!;
        if (usuarios.isEmpty) {
          return const Center(
            child: Text('No hay miembros en la iglesia',
                style: TextStyle(
                    color: AppColors.textoTerciario, fontSize: 14)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          itemBuilder: (_, i) =>
              _tarjetaUsuario(usuarios[i]),
        );
      },
    );
  }

  Widget _tarjetaUsuario(UsuarioIglesia u) {
    final colores = {
      1: const Color(0xFF6B5EFF),
      2: const Color(0xFFFBBF24),
      3: const Color(0xFF34D399),
      4: const Color(0xFF60A5FA),
      5: const Color(0xFFF97336),
    };
    final color =
        colores[u.nivelRol] ?? const Color(0xFF6B5EFF);
    final esMiActual =
        u.uid == _rolesService.uid;
    final puedoGestionar = _usuarioActual != null &&
        (_usuarioActual!.tienePermiso(Permiso.controlTotal) ||
            _usuarioActual!.puedeGestionarA(u));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: esMiActual
            ? Border.all(
                color: const Color(0xFF6B5EFF).withOpacity(0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: u.fotoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(u.fotoUrl!,
                        fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      u.nombreCompleto.isNotEmpty
                          ? u.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: color,
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
                Row(
                  children: [
                    Text(u.nombreCompleto,
                        style: const TextStyle(
                            color: AppColors.textoPrimario,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    if (esMiActual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5EFF)
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: const Text('Tú',
                            style: TextStyle(
                                color: Color(0xFF6B5EFF),
                                fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(u.rolNombre,
                      style: TextStyle(
                          color: color, fontSize: 11)),
                ),
              ],
            ),
          ),
          if (puedoGestionar && !esMiActual)
            IconButton(
              icon: const Icon(Icons.manage_accounts,
                  color: AppColors.textoTerciario),
              onPressed: () =>
                  _cambiarRolUsuario(u),
            ),
        ],
      ),
    );
  }

  Widget _tabRoles() {
    return StreamBuilder<List<RolPersonalizado>>(
      stream: _rolesService.getRoles(_iglesiaId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6B5EFF)));
        }
        final roles = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (_, i) => _tarjetaRol(roles[i]),
        );
      },
    );
  }

  Widget _tarjetaRol(RolPersonalizado rol) {
    final colores = {
      1: const Color(0xFF6B5EFF),
      2: const Color(0xFFFBBF24),
      3: const Color(0xFF34D399),
      4: const Color(0xFF60A5FA),
      5: const Color(0xFFF97336),
    };
    final color = colores[rol.nivel] ?? AppColors.textoTerciario;
    final puedeEditar = _usuarioActual?.tienePermiso(
            Permiso.controlTotal) ??
        false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('N${rol.nivel}',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(rol.nombre,
                              style: const TextStyle(
                                  color: AppColors.textoPrimario,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w600)),
                          if (!rol.esEditable) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.fondoInput,
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: const Text('Sistema',
                                  style: TextStyle(
                                      color: AppColors.textoTerciario,
                                      fontSize: 9)),
                            ),
                          ],
                        ],
                      ),
                      Text(rol.descripcion,
                          style: const TextStyle(
                              color: AppColors.textoTerciario,
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (puedeEditar && rol.esEditable)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textoTerciario, size: 20),
                    color: AppColors.fondoPrincipal,
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
                                  color: Colors.redAccent))),
                    ],
                    onSelected: (v) {
                      if (v == 'editar')
                        _abrirFormularioRol(rol: rol);
                      if (v == 'eliminar')
                        _confirmarEliminarRol(rol);
                    },
                  ),
              ],
            ),
          ),
          Container(
              height: 0.5,
              color: AppColors.fondoInput,
              margin:
                  const EdgeInsets.symmetric(horizontal: 14)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rol.permisos.map((p) {
                final esTotal = p == Permiso.controlTotal;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: esTotal
                        ? const Color(0xFF6B5EFF)
                            .withOpacity(0.2)
                        : AppColors.fondoInput,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(Permiso.nombre(p),
                      style: TextStyle(
                          color: esTotal
                              ? const Color(0xFF6B5EFF)
                              : AppColors.textoSecundario,
                          fontSize: 10)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _cambiarRolUsuario(UsuarioIglesia usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fondoTarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StreamBuilder<List<RolPersonalizado>>(
        stream: _rolesService.getRoles(_iglesiaId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final roles = snapshot.data!;
          return Padding(
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
                        borderRadius:
                            BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cambiar rol de ${usuario.nombreCompleto}',
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...roles.map((rol) {
                  final esActual =
                      rol.nombre == usuario.rolNombre;
                  final puedeAsignar = _usuarioActual!
                          .tienePermiso(Permiso.controlTotal) ||
                      rol.nivel > _usuarioActual!.nivelRol;
                  return GestureDetector(
                    onTap: puedeAsignar
                        ? () async {
                            final error = await _rolesService
                                .cambiarRol(
                              iglesiaId: _iglesiaId!,
                              usuarioId: usuario.uid,
                              nuevoRol: rol,
                              quienCambia: _usuarioActual!,
                              aQuien: usuario,
                            );
                            Navigator.pop(context);
                            if (error != null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(error),
                                backgroundColor:
                                    Colors.redAccent,
                                behavior:
                                    SnackBarBehavior.floating,
                              ));
                            }
                          }
                        : null,
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: esActual
                            ? const Color(0xFF6B5EFF)
                                .withOpacity(0.2)
                            : AppColors.fondoPrincipal,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: esActual
                              ? const Color(0xFF6B5EFF)
                              : puedeAsignar
                                  ? AppColors.fondoInput
                                  : AppColors.fondoInput
                                      .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(rol.nombre,
                                style: TextStyle(
                                    color: puedeAsignar
                                        ? AppColors.textoPrimario
                                        : AppColors.borde,
                                    fontSize: 13)),
                          ),
                          if (esActual)
                            const Icon(Icons.check,
                                color: Color(0xFF6B5EFF),
                                size: 16),
                          if (!puedeAsignar)
                            const Icon(Icons.lock_outline,
                                color: AppColors.borde,
                                size: 14),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _abrirFormularioRol({RolPersonalizado? rol}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoTarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormularioRol(
        iglesiaId: _iglesiaId!,
        rol: rol,
        nivelMinimo: (_usuarioActual?.nivelRol ?? 1) + 1,
        onGuardar: (r) async {
          if (rol == null) {
            await _rolesService.crearRol(_iglesiaId!, r);
          } else {
            await _rolesService.editarRol(
                _iglesiaId!, rol.id!, r);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmarEliminarRol(RolPersonalizado rol) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoTarjeta,
        title: const Text('Eliminar rol',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: Text(
            '¿Eliminar el rol "${rol.nombre}"? Los usuarios con este rol quedarán sin rol asignado.',
            style: const TextStyle(color: AppColors.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textoTerciario)),
          ),
          TextButton(
            onPressed: () {
              _rolesService.eliminarRol(
                  _iglesiaId!, rol.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ---- FORMULARIO ROL ----
class FormularioRol extends StatefulWidget {
  final String iglesiaId;
  final RolPersonalizado? rol;
  final int nivelMinimo;
  final Function(RolPersonalizado) onGuardar;

  const FormularioRol({
    super.key,
    required this.iglesiaId,
    this.rol,
    required this.nivelMinimo,
    required this.onGuardar,
  });

  @override
  State<FormularioRol> createState() => _FormularioRolState();
}

class _FormularioRolState extends State<FormularioRol> {
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  List<String> _permisosSeleccionados = [];
  int _nivel = 3;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.rol != null) {
      _nombre.text = widget.rol!.nombre;
      _descripcion.text = widget.rol!.descripcion;
      _permisosSeleccionados =
          List.from(widget.rol!.permisos);
      _nivel = widget.rol!.nivel;
    } else {
      _nivel = widget.nivelMinimo;
    }
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Text(
              widget.rol == null
                  ? 'Nuevo rol'
                  : 'Editar rol',
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _campo('NOMBRE DEL ROL', _nombre),
            _campo('DESCRIPCIÓN', _descripcion),

            const Text('PERMISOS',
                style: TextStyle(
                    color: AppColors.textoTerciario,
                    fontSize: 11,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ...Permiso.todos
                .where((p) => p != Permiso.controlTotal)
                .map((p) {
              final sel =
                  _permisosSeleccionados.contains(p);
              return CheckboxListTile(
                value: sel,
                activeColor: const Color(0xFF6B5EFF),
                checkColor: AppColors.textoPrimario,
                title: Text(Permiso.nombre(p),
                    style: const TextStyle(
                        color: AppColors.textoPrimario, fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _permisosSeleccionados.add(p);
                  } else {
                    _permisosSeleccionados.remove(p);
                  }
                }),
              );
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5EFF),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(
                        color: AppColors.textoPrimario)
                    : Text(
                        widget.rol == null
                            ? 'Crear rol'
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

  Widget _campo(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textoTerciario,
                fontSize: 11,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fondoPrincipal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fondoInput),
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
          content: Text('El nombre del rol es obligatorio'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final rol = RolPersonalizado(
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      permisos: _permisosSeleccionados,
      nivel: _nivel,
      esEditable: true,
      fechaCreacion: DateTime.now(),
    );
    await widget.onGuardar(rol);
    setState(() => _cargando = false);
  }
}