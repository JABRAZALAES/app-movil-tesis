import 'package:flutter/material.dart';
import 'package:recuperacion/IU/CambiarContrase%C3%B1a.dart';
import 'package:recuperacion/IU/recuperacionContrase%C3%B1a.dart';
import '../Services/auth_service.dart';
import 'menu.dart';
import 'package:flutter/services.dart';




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
  final TextEditingController _confirmarContrasenaController = TextEditingController();

  bool _esLogin = true;
  bool _cargando = false;
  String _mensajeError = '';
  bool _mostrarContrasena = false;
  bool _mostrarConfirmarContrasena = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _configurarAnimaciones();
  }

  void _configurarAnimaciones() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _alternarModo() {
    setState(() {
      _esLogin = !_esLogin;
      _mensajeError = '';
      // Limpiar campos al cambiar modo
      _nombreController.clear();
      _correoController.clear();
      _contrasenaController.clear();
      _confirmarContrasenaController.clear();
      _mostrarContrasena = false;
      _mostrarConfirmarContrasena = false;
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
        if (datosLogin == null || datosLogin['usuario'] == null || datosLogin['token'] == null) {
          _mostrarError('Credenciales incorrectas. Verifica tu correo y contraseña.');
          return;
        }

        final usuario = datosLogin['usuario'];
        if (usuario['nombre'] == null || usuario['correo'] == null || usuario['id'] == null) {
          _mostrarError('Error en los datos del usuario. Contacta al administrador.');
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

        final tokenRegistro = datosRegistro['token'] ?? datosRegistro['usuario']?['token'];

        // ignore: unnecessary_null_comparison
        if (datosRegistro == null || datosRegistro['usuario'] == null || 
            datosRegistro['usuario']['id'] == null || tokenRegistro == null) {
          _mostrarError('Error al crear la cuenta. Verifica los datos e intenta nuevamente.');
          return;
        }

        final usuario = datosRegistro['usuario'];
        if (usuario['nombre'] == null || usuario['correo'] == null) {
          _mostrarError('Error en los datos del registro. Contacta al administrador.');
          return;
        }

        await prefs.setString('nombre', usuario['nombre']);
        await prefs.setString('correo', usuario['correo']);
        await prefs.setString('rol', usuario['rol'] ?? 'normal');
        await prefs.setString('user_id', usuario['id'].toString());
        await prefs.setString('token', tokenRegistro);

        _mostrarExitoYRedirigir('¡Cuenta creada exitosamente!');
      }
    } catch (e) {
      String mensajeError = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      
      if (e.toString().contains('Exception:')) {
        mensajeError = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().contains('timeout')) {
        mensajeError = 'Tiempo de espera agotado. Intenta nuevamente.';
      } else if (e.toString().contains('network')) {
        mensajeError = 'Error de red. Verifica tu conexión.';
      }
      
      _mostrarError(mensajeError);
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
    setState(() {
      _cargando = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje, 
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MenuPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
            transitionDuration: const Duration(milliseconds: 600),
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
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 39, 0, 146),
              Color.fromARGB(255, 13, 0, 189),
              Color.fromARGB(255, 130, 128, 255),
            ],
            stops: [0.0, 0.6, 1.0],
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
      ),
    );
  }

  Widget _construirLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          // Logo sin círculo blanco
          Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
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
          const SizedBox(height: 8),
          const Text(
            'ESPE - Santo Domingo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del formulario
              Center(
                child: Text(
                  _esLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _esLogin 
                    ? 'Ingresa tus credenciales para continuar'
                    : 'Completa los datos para registrarte',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              
              // Mensaje de error
              if (_mensajeError.isNotEmpty) _construirMensajeError(),
              
              // Campos del formulario
              if (!_esLogin) _construirCampoNombre(),
              _construirCampoCorreo(),
              const SizedBox(height: 16),
              _construirCampoContrasena(),
              if (!_esLogin) _construirCampoConfirmarContrasena(),
              if (_esLogin) _construirOlvidasteContrasena(),
              const SizedBox(height: 24),
              _construirBotonPrincipal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirMensajeError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: _nombreController,
      style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]")
        ),
      ],
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
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu nombre completo';
        }
        
        String nombreLimpio = value.trim();
        
        if (nombreLimpio.length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        
        // Validar que solo contenga letras válidas para nombres en español
        RegExp nombreValido = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$");
        if (!nombreValido.hasMatch(nombreLimpio)) {
          return 'El nombre solo puede contener letras y espacios';
        }
        
        // Validar que no tenga espacios múltiples consecutivos
        if (nombreLimpio.contains(RegExp(r'\s{2,}'))) {
          return 'No se permiten espacios múltiples consecutivos';
        }
        
        // Validar que no empiece o termine con espacio
        if (nombreLimpio.startsWith(' ') || nombreLimpio.endsWith(' ')) {
          return 'El nombre no puede empezar o terminar con espacio';
        }
        
        // Validar longitud máxima
        if (nombreLimpio.length > 50) {
          return 'El nombre no puede exceder 50 caracteres';
        }
        
        return null;
      },
    ),
  );
}
  Widget _construirCampoCorreo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
          ),
        ),
         validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Ingresa tu correo electrónico';
      }
      if (value.trim() != value) {
        return 'No debe tener espacios al inicio o final';
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
        return 'Ingresa un correo válido';
      }
      return null;
    },
      ),
    );
  }

  Widget _construirCampoContrasena() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            onPressed: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa tu contraseña';
          }
          if (value.length < 6) {
            return 'La contraseña debe tener al menos 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _construirCampoConfirmarContrasena() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              _mostrarConfirmarContrasena ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF667eea),
            ),
            onPressed: () => setState(() => _mostrarConfirmarContrasena = !_mostrarConfirmarContrasena),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Confirma tu contraseña';
          }
          if (value != _contrasenaController.text) {
            return 'Las contraseñas no coinciden';
          }
          return null;
        },
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
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _construirBotonPrincipal() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF4B73E8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _cargando ? null : _manejarEnvio,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _cargando
            ? const SizedBox(
                width: 20,
                height: 20,
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
