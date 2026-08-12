import 'package:flutter/material.dart';
import '../services/iglesia_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _iglesiaService = IglesiaService();
  final _authService = AuthService();
  bool _creando = true;
  bool _cargando = false;

  final _nombreIglesia = TextEditingController();
  final _ciudad = TextEditingController();
  final _pais = TextEditingController();
  final _codigo = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        actions: [
          TextButton(
            onPressed: () async {
              await _authService.cerrarSesion();
              if (!mounted) return;
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomeScreen()));
            },
            child: const Text('Salir',
                style: TextStyle(
                    color: AppColors.textoSecundario)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bordeActivo),
                ),
                child: const Icon(Icons.church,
                    color: AppColors.textoPrimario, size: 26),
              ),
              const SizedBox(height: 20),
              const Text('Bienvenido a Esdra',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                  'Crea tu iglesia o únete a una existente con un código de invitación.',
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 14,
                      height: 1.5)),
              const SizedBox(height: 32),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borde),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _tab('Crear iglesia', _creando,
                        () => setState(() => _creando = true)),
                    _tab('Unirse con código', !_creando,
                        () => setState(() => _creando = false)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _creando ? _formCrear() : _formUnirse(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String texto, bool activo, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: activo
                ? AppColors.textoPrimario
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo
                  ? AppColors.fondoPrincipal
                  : AppColors.textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {String hint = ''}) {
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
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textoTerciario),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _formCrear() {
    return Column(
      children: [
        _campo('NOMBRE DE LA IGLESIA', _nombreIglesia,
            hint: 'Ej: Centro de Fe Internacional'),
        _campo('CIUDAD', _ciudad,
            hint: 'Ej: Caracas'),
        _campo('PAÍS', _pais, hint: 'Ej: Venezuela'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.textoSecundario, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Al crear la iglesia serás el Super Admin con control total.',
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargando ? null : _crearIglesia,
            child: _cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.fondoPrincipal,
                        strokeWidth: 2))
                : const Text('Crear mi iglesia',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _formUnirse() {
    return Column(
      children: [
        const Text(
          'Ingresa el código de 6 dígitos que te dio tu pastor o administrador.',
          style: TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fondoTarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.bordeActivo),
          ),
          child: TextField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 22),
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                  color: AppColors.textoTerciario,
                  fontSize: 32,
                  letterSpacing: 10),
            ),
            maxLength: 6,
            buildCounter: (_, {required currentLength,
                required isFocused, maxLength}) =>
                null,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargando ? null : _unirse,
            child: _cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.fondoPrincipal,
                        strokeWidth: 2))
                : const Text('Unirme a la iglesia',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _crearIglesia() async {
    if (_nombreIglesia.text.isEmpty ||
        _ciudad.text.isEmpty ||
        _pais.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final error = await _iglesiaService.crearIglesia(
      nombre: _nombreIglesia.text.trim(),
      ciudad: _ciudad.text.trim(),
      pais: _pais.text.trim(),
    );
    setState(() => _cargando = false);
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(
              builder: (_) => const HomeScreen()));
    }
  }

  Future<void> _unirse() async {
    if (_codigo.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener 6 caracteres'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    final error =
        await _iglesiaService.usarCodigo(_codigo.text.trim());
    setState(() => _cargando = false);
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(
              builder: (_) => const HomeScreen()));
    }
  }
}