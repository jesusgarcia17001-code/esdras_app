import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/iglesia_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _iglesiaService = IglesiaService();
  bool _mostrarLogin = true;
  bool _cargando = false;

  final _nombreReg = TextEditingController();
  final _emailLogin = TextEditingController();
  final _passLogin = TextEditingController();
  final _emailReg = TextEditingController();
  final _passReg = TextEditingController();
  final _passRegConfirm = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureRegConfirm = true;

  void _mostrarError(String mensaje) {
    // Errores técnicos (más largos, con detalles de código) se muestran
    // en un diálogo que no desaparece solo, para poder leerlos con calma
    // o mandarlos como captura de pantalla.
    if (mensaje.length > 60) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.fondoTarjeta,
          title: const Text('Detalle del error',
              style: TextStyle(color: AppColors.textoPrimario)),
          content: SelectableText(mensaje,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navegarSegunEstado() async {
    final usuario = await _iglesiaService.getUsuario();
    if (!mounted) return;
    final iglesiaId = usuario?.iglesiaId;
    if (iglesiaId == null || iglesiaId.isEmpty) {
      FirestoreService.iglesiaIdActual = null;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => SetupScreen()));
    } else {
      FirestoreService.iglesiaIdActual = iglesiaId;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  Future<void> _login() async {
    if (_emailLogin.text.isEmpty || _passLogin.text.isEmpty) {
      _mostrarError('Completa todos los campos');
      return;
    }
    setState(() => _cargando = true);
    final error = await _authService.login(
      email: _emailLogin.text.trim(),
      password: _passLogin.text.trim(),
    );
    setState(() => _cargando = false);
    if (error != null) {
      _mostrarError(error);
    } else {
      await _navegarSegunEstado();
    }
  }

  Future<void> _registrar() async {
    if (_nombreReg.text.isEmpty ||
        _emailReg.text.isEmpty ||
        _passReg.text.isEmpty) {
      _mostrarError('Completa todos los campos');
      return;
    }
    if (_passReg.text.length < 6) {
      _mostrarError('La contraseña debe tener mínimo 6 caracteres');
      return;
    }
    if (_passReg.text != _passRegConfirm.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }
    setState(() => _cargando = true);
    try {
      final error = await _authService.registrar(
        nombreCompleto: _nombreReg.text.trim(),
        email: _emailReg.text.trim(),
        password: _passReg.text.trim(),
      );
      if (!mounted) return;
      setState(() => _cargando = false);
      if (error != null) {
        _mostrarError(error);
      } else {
        await _navegarSegunEstado();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarError('Error inesperado');
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _cargando = true);
    final error = await _authService.loginConGoogle();
    setState(() => _cargando = false);
    if (error != null && error != 'Cancelado') {
      _mostrarError(error);
    } else if (error == null) {
      await _navegarSegunEstado();
    }
  }

  Future<void> _recuperarPassword() async {
    final emailCtrl =
        TextEditingController(text: _emailLogin.text.trim());
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjeta,
        title: const Text('Recuperar contraseña',
            style: TextStyle(color: AppColors.textoPrimario)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escribe tu correo y te enviaremos un enlace '
              'para restablecer tu contraseña.',
              style: TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.fondoInput,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borde),
              ),
              child: TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: AppColors.textoPrimario, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  hintStyle:
                      TextStyle(color: AppColors.textoTerciario),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (enviar != true || !mounted) return;
    if (emailCtrl.text.trim().isEmpty) {
      _mostrarError('Escribe tu correo electrónico');
      return;
    }
    setState(() => _cargando = true);
    final error =
        await _authService.recuperarPassword(emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _cargando = false);
    if (error != null) {
      _mostrarError(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Te enviamos un enlace para restablecer tu contraseña'),
          backgroundColor: AppColors.exito,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bordeActivo),
                ),
                child: const Icon(Icons.church,
                    color: AppColors.textoPrimario, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Esdra',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Gestión de tu congregación',
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 14)),
              const SizedBox(height: 40),

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
                    _tab('Iniciar sesión', _mostrarLogin, () {
                      setState(() => _mostrarLogin = true);
                    }),
                    _tab('Registrarse', !_mostrarLogin, () {
                      setState(() => _mostrarLogin = false);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _mostrarLogin ? _formLogin() : _formRegistro(),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 0.5,
                          color: AppColors.borde)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o',
                        style: TextStyle(
                            color: AppColors.textoTerciario,
                            fontSize: 12)),
                  ),
                  Expanded(
                      child: Container(
                          height: 0.5,
                          color: AppColors.borde)),
                ],
              ),
              const SizedBox(height: 20),

              // Google
              GestureDetector(
                onTap: _cargando ? null : _loginGoogle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.fondoTarjeta,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.bordeActivo),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('G',
                              style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Continuar con Google',
                          style: TextStyle(
                              color: AppColors.textoPrimario,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
      {bool password = false,
      TextInputType tipo = TextInputType.text,
      bool obscure = false,
      VoidCallback? onToggleObscure}) {
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
            obscureText: password ? obscure : false,
            keyboardType: tipo,
            style: const TextStyle(
                color: AppColors.textoPrimario, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              suffixIcon: password
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textoTerciario,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _formLogin() {
    return Column(
      children: [
        _campo('CORREO ELECTRÓNICO', _emailLogin,
            tipo: TextInputType.emailAddress),
        _campo('CONTRASEÑA', _passLogin,
            password: true,
            obscure: _obscureLogin,
            onToggleObscure: () =>
                setState(() => _obscureLogin = !_obscureLogin)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _cargando ? null : _recuperarPassword,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('¿Olvidaste tu contraseña?',
                style: TextStyle(
                    color: AppColors.acento,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargando ? null : _login,
            child: _cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.acentoTexto,
                        strokeWidth: 2))
                : const Text('Iniciar sesión',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _formRegistro() {
    return Column(
      children: [
        _campo('NOMBRE COMPLETO', _nombreReg),
        _campo('CORREO ELECTRÓNICO', _emailReg,
            tipo: TextInputType.emailAddress),
        _campo('CONTRASEÑA', _passReg,
            password: true,
            obscure: _obscureReg,
            onToggleObscure: () =>
                setState(() => _obscureReg = !_obscureReg)),
        _campo('CONFIRMAR CONTRASEÑA', _passRegConfirm,
            password: true,
            obscure: _obscureRegConfirm,
            onToggleObscure: () => setState(
                () => _obscureRegConfirm = !_obscureRegConfirm)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargando ? null : _registrar,
            child: _cargando
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.acentoTexto,
                        strokeWidth: 2))
                : const Text('Crear cuenta',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}