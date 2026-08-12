import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/iglesia_service.dart';
import '../theme/app_theme.dart';
import 'miembros_screen.dart';
import 'grupos_screen.dart';
import 'login_screen.dart';
import 'academia_screen.dart';
import 'redes_screen.dart';
import 'reportes_screen.dart';
import 'roles_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _iglesiaService = IglesiaService();
  Map<String, dynamic>? _usuario;
  Map<String, dynamic>? _iglesia;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final u = await _firestoreService.getUsuarioActual();
    setState(() => _usuario = u);
    if (u?['iglesiaId'] != null) {
      final ig =
          await _iglesiaService.getIglesia(u!['iglesiaId']);
      setState(() => _iglesia = ig);
    }
  }

  Future<void> _cerrarSesion() async {
    await _authService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: _paginaActual == 0
          ? _dashboard()
          : _paginaActual == 1
              ? const MiembrosScreen()
              : _paginaActual == 2
                  ? const GruposScreen()
                  : const ReportesScreen(),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _dashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _encabezado(),
            const SizedBox(height: 24),
            _tarjetaPrincipal(),
            const SizedBox(height: 12),
            _estadisticas(),
            const SizedBox(height: 28),
            _tituloSeccion('MÓDULOS'),
            const SizedBox(height: 12),
            _modulosGrid(),
            const SizedBox(height: 28),
            _tituloSeccion('ACCIONES RÁPIDAS'),
            const SizedBox(height: 12),
            _accionesRapidas(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _iglesia?['nombre'] ?? 'Mi iglesia',
              style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 12,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              _usuario?['nombreCompleto'] ?? 'Bienvenido',
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            // Botón de roles
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RolesScreen())),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: const Icon(Icons.manage_accounts,
                    color: AppColors.textoSecundario, size: 18),
              ),
            ),
            // Botón cerrar sesión
            GestureDetector(
              onTap: _cerrarSesion,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: const Icon(Icons.logout,
                    color: AppColors.textoSecundario, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaPrincipal() {
    return StreamBuilder<int>(
      stream: _firestoreService.contarMiembros(),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total de miembros',
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('$total',
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const SizedBox(height: 4),
              const Text('en tu congregación',
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.acentoSuave,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.bordeActivo),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        color: AppColors.exito, size: 8),
                    SizedBox(width: 6),
                    Text('Activo',
                        style: TextStyle(
                            color: AppColors.textoPrimario,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _estadisticas() {
    return Row(
      children: [
        _statCard('Grupos', _firestoreService.contarGrupos()),
        const SizedBox(width: 8),
        _statCard('Líderes', _firestoreService.contarLideres()),
        const SizedBox(width: 8),
        _statCardFijo('Academia', '0'),
      ],
    );
  }

  Widget _statCard(String label, Stream<int> stream) {
    return Expanded(
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(
              children: [
                Text('${snapshot.data ?? 0}',
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCardFijo(String label, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoTarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          children: [
            Text(valor,
                style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(titulo,
        style: const TextStyle(
            color: AppColors.textoTerciario,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600));
  }

  Widget _modulosGrid() {
    final modulos = [
      {
        'nombre': 'Miembros',
        'icono': Icons.people,
        'screen': const MiembrosScreen(),
      },
      {
        'nombre': 'Grupos',
        'icono': Icons.home_work,
        'screen': const GruposScreen(),
      },
      {
        'nombre': 'Redes',
        'icono': Icons.hub,
        'screen': const RedesScreen(),
      },
      {
        'nombre': 'Academia',
        'icono': Icons.school,
        'screen': const AcademiaScreen(),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: modulos.map((m) {
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => m['screen'] as Widget)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.acentoSuave,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.bordeActivo),
                  ),
                  child: Icon(m['icono'] as IconData,
                      color: AppColors.textoPrimario, size: 18),
                ),
                const Spacer(),
                Text(m['nombre'] as String,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _accionesRapidas() {
    final acciones = [
      {
        'texto': 'Registrar nuevo miembro',
        'icono': Icons.person_add_outlined,
        'screen': const MiembrosScreen(),
      },
      {
        'texto': 'Crear grupo pequeño',
        'icono': Icons.home_work_outlined,
        'screen': const GruposScreen(),
      },
      {
        'texto': 'Gestionar roles',
        'icono': Icons.manage_accounts_outlined,
        'screen': const RolesScreen(),
      },
    ];

    return Column(
      children: acciones.map((a) {
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => a['screen'] as Widget)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fondoTarjeta,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                Icon(a['icono'] as IconData,
                    color: AppColors.textoSecundario, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(a['texto'] as String,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 13)),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textoTerciario, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fondoSecundario,
        border: Border(
            top: BorderSide(color: AppColors.borde)),
      ),
      child: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: (i) => setState(() => _paginaActual = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.textoPrimario,
        unselectedItemColor: AppColors.textoTerciario,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Miembros'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_work_outlined),
              label: 'Grupos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reportes'),
        ],
      ),
    );
  }
}