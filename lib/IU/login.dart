import 'package:flutter/material.dart';
import 'package:recuperacion/IU/CambiarContrase%C3%B1a.dart';
import 'package:recuperacion/IU/recuperacionContrase%C3%B1a.dart';
import '../Services/auth_service.dart';
import 'menu.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  bool _esLogin = true;
  bool _cargando = false;
  String _mensajeError = '';
  bool _mostrarContrasena = false;
  bool _mostrarConfirmarContrasena = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _configurarAnimaciones();
  }

  void _configurarAnimaciones() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _backgroundController.repeat();
  }

  void _alternarModo() {
    setState(() {
      _esLogin = !_esLogin;
      _mensajeError = '';
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _manejarEnvio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensajeError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_esLogin) {
        final datosLogin = await _authService.login(
          correo: _correoController.text.trim(),
          contrasena: _contrasenaController.text,
        );

        // ignore: unnecessary_null_comparison
        if (datosLogin == null ||
            datosLogin['usuario'] == null ||
            datosLogin['token'] == null) {
          _mostrarError('Usuario o contraseña incorrectos');
          setState(() => _cargando = false);
          return;
        }

        final usuario = datosLogin['usuario'];
        if (usuario['nombre'] == null ||
            usuario['correo'] == null ||
            usuario['id'] == null) {
          _mostrarError('Error en los datos del usuario');
          setState(() => _cargando = false);
          return;
        }

        await prefs.setString('nombre', usuario['nombre']);
        await prefs.setString('token', datosLogin['token']);
        await prefs.setString('correo', usuario['correo']);
        await prefs.setString('rol', usuario['rol'] ?? 'normal');
        await prefs.setString('user_id', usuario['id'].toString());
        // Verifica si requiere cambio de contraseña
        if (datosLogin['requiereCambioContrasena'] == true) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => const CambiarContrasenaPage(),
            ),
          );
          return;
        }

        _mostrarExitoYRedirigir('¡Bienvenido!');
      } else {
        final datosRegistro = await _authService.register(
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          contrasena: _contrasenaController.text,
        );

        // Imprime la respuesta para depuración
        print('Respuesta registro: $datosRegistro');

        // Acepta el token en la raíz o dentro de usuario
        final tokenRegistro =
            datosRegistro['token'] ?? datosRegistro['usuario']?['token'];

        // ignore: unnecessary_null_comparison
        if (datosRegistro == null ||
            datosRegistro['usuario'] == null ||
            datosRegistro['usuario']['id'] == null ||
            tokenRegistro == null) {
          _mostrarError('Error al registrar el usuario');
          setState(() => _cargando = false);
          return;
        }

        final usuario = datosRegistro['usuario'];
        if (usuario['nombre'] == null || usuario['correo'] == null) {
          _mostrarError('Error en los datos del registro');
          setState(() => _cargando = false);
          return;
        }

        await prefs.setString('nombre', usuario['nombre']);
        await prefs.setString('correo', usuario['correo']);
        await prefs.setString('rol', usuario['rol'] ?? 'normal');
        await prefs.setString('user_id', usuario['id'].toString());
        await prefs.setString('token', tokenRegistro);

        _mostrarExitoYRedirigir('¡Registro exitoso! Bienvenido');
      }
    } catch (e) {
      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _cargando = false;
      _mensajeError = mensaje;
    });
    _scaleController.reset();
    _scaleController.forward();
  }

  void _mostrarExitoYRedirigir(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const MenuPage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF667eea),
                    const Color(0xFF4B73E8),
                    (_backgroundAnimation.value + 0.3) % 1.0,
                  )!,
                  Color.lerp(
                    const Color(0xFF4B73E8),
                    const Color(0xFF667eea),
                    (_backgroundAnimation.value + 0.7) % 1.0,
                  )!,
                  const Color(0xFF3b5998),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _construirLogo(),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _construirFormulario(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _construirBotonAlternar(),
                      const SizedBox(height: 20),
                      _construirIndicadorSecuridad(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _construirLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión de Novedades',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                _esLogin ? 'Ingresa tus credenciales' : 'Crear Cuenta',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _esLogin ? '' : '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              if (_mensajeError.isNotEmpty) _construirMensajeError(),
              if (!_esLogin) _construirCampoNombre(),
              _construirCampoCorreo(),
              const SizedBox(height: 20),
              _construirCampoContrasena(),
              if (_esLogin) _construirOlvidasteContrasena(),
              if (!_esLogin) _construirCampoConfirmarContrasena(),
              const SizedBox(height: 32),
              _construirBotonPrincipal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirMensajeError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mensajeError,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCampoNombre() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 60,
        child: TextFormField(
          controller: _nombreController,
          style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF667eea),
              size: 24,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
        ),
      ),
    );
  }

  Widget _construirCampoCorreo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 60,
        child: TextFormField(
          controller: _correoController,
          style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF667eea),
              size: 24,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Ingresa tu correo';
            if (!value.contains('@')) return 'Correo inválido';
            return null;
          },
        ),
      ),
    );
  }

  Widget _construirCampoContrasena() {
    return SizedBox(
      height: 60,
      child: TextFormField(
        controller: _contrasenaController,
        obscureText: !_mostrarContrasena,
        style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xFF667eea),
            size: 24,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _mostrarContrasena ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF667eea),
            ),
            onPressed:
                () => setState(() => _mostrarContrasena = !_mostrarContrasena),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
        ),
        validator:
            (value) =>
                value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
      ),
    );
  }

  Widget _construirOlvidasteContrasena() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecuperacionContrasenaPage(),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _construirCampoConfirmarContrasena() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 60,
        child: TextFormField(
          controller: _confirmarContrasenaController,
          obscureText: !_mostrarConfirmarContrasena,
          style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF667eea),
              size: 24,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarConfirmarContrasena
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF667eea),
              ),
              onPressed:
                  () => setState(
                    () =>
                        _mostrarConfirmarContrasena =
                            !_mostrarConfirmarContrasena,
                  ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
          ),
          validator:
              (value) =>
                  value == _contrasenaController.text
                      ? null
                      : 'Las contraseñas no coinciden',
        ),
      ),
    );
  }

  Widget _construirBotonPrincipal() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF4B73E8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _cargando ? null : _manejarEnvio,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _cargando
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : Text(
                  _esLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
      ),
    );
  }

  Widget _construirBotonAlternar() {
    return TextButton(
      onPressed: _alternarModo,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(
              text: _esLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
            ),
            TextSpan(
              text: _esLogin ? 'Regístrate' : 'Inicia sesión',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirIndicadorSecuridad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Text(
            'Conexión segura y encriptada',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
