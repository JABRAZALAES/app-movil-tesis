
            import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reporte_novedad_page.dart';
import 'reporte_objeto_page.dart';
import 'mis_incidentes_page.dart';
import 'objetos_perdidos_page.dart';
import 'perfil.dart';
import '../Services/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late List<Animation<double>> _buttonAnimations;
  final AuthService _authService = AuthService();
  String _nombreUsuario = 'Usuario';
  bool _modalSesionBloqueadaMostrado = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cargarNombreUsuario();
    _validarSesion();

    // Validar sesión cada 10 segundos (opción 1)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _validarSesion();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 + (index * 0.1),
            0.6 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }
    void _mostrarAdvertenciaExpiracion(int minutosRestantes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Atención!'),
        content: Text(
          'Tu sesión expirará en $minutosRestantes minutos. '
          'Por favor, vuelve a iniciar sesión para evitar perder tu trabajo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
int _minutosRestantesToken(String token) {
  try {
    final expirationDate = JwtDecoder.getExpirationDate(token);
    final now = DateTime.now();
    final difference = expirationDate.difference(now);
    return difference.inMinutes;
  } catch (_) {
    return 0;
  }
}
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validarSesion();
    }
  }

  // Puedes reutilizar este método en otras pantallas protegidas
Future<void> _validarSesion() async {
  print('Validando sesión...');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  print('Token actual en la app: $token');
  if (token == null) return;
  try {
    // ADVERTENCIA SI QUEDAN 5 MINUTOS O MENOS
    final minutosRestantes = _minutosRestantesToken(token);
    if (minutosRestantes > 0 && minutosRestantes <= 5) {
      _mostrarAdvertenciaExpiracion(minutosRestantes);
    }

    await _authService.getUsuarioActual(token);
    print('Sesión válida');
  } on SesionBloqueadaException {
    print('¡Sesión bloqueada detectada!');
    _mostrarPantallaSesionBloqueada();
  } catch (e) {
    print('Otro error: $e');
  }
}
  void _mostrarPantallaSesionBloqueada() {
    if (_modalSesionBloqueadaMostrado) return;
    _modalSesionBloqueadaMostrado = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.8),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 60),
                  const SizedBox(height: 24),
                  const Text(
                    'Sesión bloqueada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu sesión ha sido iniciada en otro dispositivo.\nDebes volver a iniciar sesión.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () async {
                      await _cerrarSesion();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      _modalSesionBloqueadaMostrado = false;
    });
  }

Future<void> _cerrarSesion() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  try {
    if (token != null) {
      await _authService.logout(token);
    }
  } catch (_) {}
  await prefs.clear();
  if (mounted) {
    // Cierra todos los modales antes de navegar
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const PerfilPage(), // O LoginPage si tienes una
      ),
      (route) => false,
    );
  }
  _modalSesionBloqueadaMostrado = false;
}

  Future<void> _cargarNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Usuario';
    setState(() {
      _nombreUsuario = nombre;
    });
  }

  void _playHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - Moderno y elegante
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    20 *
                        (1 -
                            Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(
                                      0.0,
                                      0.4,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                )
                                .value),
                  ),
                  child: Opacity(
                    opacity:
                        Tween<double>(begin: 0.0, end: 1.0)
                            .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.0,
                                  0.4,
                                  curve: Curves.easeIn,
                                ),
                              ),
                            )
                            .value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 0, 33, 182),
                            Color.fromARGB(255, 0, 47, 255),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Icono y título principal
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.security,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gestión de Novedades',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ESPE - Santo Domingo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Mensaje de bienvenida
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.waving_hand,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '¡Bienvenido, $_nombreUsuario!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Botones principales
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Título de sección
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity:
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(
                                        0.4,
                                        0.6,
                                        curve: Curves.easeIn,
                                      ),
                                    ),
                                  )
                                  .value,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              '¿Qué necesitas hacer?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedButton(
                      context,
                      'Reportar Incidente',
                      Icons.report_problem_outlined,
                      () {
                        _playHapticFeedback();
                        Navigator.push(
                          context,
                          _buildPageRoute(const ReporteIncidentePage()),
                        );
                      },
                      _buttonAnimations[0],
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedButton(
                      context,
                      'Reportar Objeto Encontrado',
                      Icons.search_outlined,
                      () {
                        _playHapticFeedback();
                        Navigator.push(
                          context,
                          _buildPageRoute(const ReporteObjetoPage()),
                        );
                      },
                      _buttonAnimations[1],
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedButton(
                      context,
                      'Mis Incidentes',
                      Icons.list_alt_outlined,
                      () {
                        _playHapticFeedback();
                        Navigator.push(
                          context,
                          _buildPageRoute(const MisIncidentesPage()),
                        );
                      },
                      _buttonAnimations[2],
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedButton(
                      context,
                      'Objetos Perdidos',
                      Icons.inventory_2_outlined,
                      () {
                        _playHapticFeedback();
                        Navigator.push(
                          context,
                          _buildPageRoute(const ObjetosPerdidosPage()),
                        );
                      },
                      _buttonAnimations[3],
                    ),

                    // Botones de administración solo para TECNICO o JEFE
                    FutureBuilder<String?>(
                      future: SharedPreferences.getInstance().then(
                        (prefs) => prefs.getString('rol'),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final rol = snapshot.data?.toLowerCase();
                        if (rol == 'tecnico' || rol == 'jefe') {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                // Botón Administrar Incidentes
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.admin_panel_settings,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Administrar Incidentes',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        0,
                                        33,
                                        182,
                                      ),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _playHapticFeedback();
                                      Navigator.pushNamed(
                                        context,
                                        '/adminIncidentes',
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Botón Administrar Objetos Encontrados
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.search, size: 20),
                                    label: const Text(
                                      'Adm. Objetos Perdidos',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0021B6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _playHapticFeedback();
                                      Navigator.pushNamed(
                                        context,
                                        '/adminObjetosEncontrados',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // User Section con nombre dinámico
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    10 *
                        (1 -
                            Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(
                                      0.6,
                                      0.8,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                )
                                .value),
                  ),
                  child: Opacity(
                    opacity:
                        Tween<double>(begin: 0.0, end: 1.0)
                            .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.6,
                                  0.8,
                                  curve: Curves.easeIn,
                                ),
                              ),
                            )
                            .value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFF8FAFF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 0, 33, 182),
                                  Color.fromARGB(255, 0, 33, 182),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: Icon(
                                Icons.person,
                                size: 24,
                                color: const Color.fromARGB(255, 0, 33, 182),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nombreUsuario,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Usuario activo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Bottom Navigation adaptativo
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      Tween<double>(begin: 0.0, end: 1.0)
                          .animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(
                                0.7,
                                0.9,
                                curve: Curves.easeIn,
                              ),
                            ),
                          )
                          .value,
                  child:
                      Platform.isIOS
                          ? _buildCupertinoTabBar()
                          : _buildMaterialBottomNav(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8FAFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 0, 33, 182),
                                Color.fromARGB(255, 0, 33, 182),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getButtonDescription(text),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.chevron_right
                                : Icons.arrow_forward_ios,
                            size: 16,
                            color: const Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getButtonDescription(String buttonText) {
    switch (buttonText) {
      case 'Reportar Incidente':
        return 'Notifica un problema o incidente';
      case 'Reportar Objeto Encontrado':
        return 'Notifica un objeto perdido';
      case 'Mis Incidentes':
        return 'Revisa tus reportes anteriores';
      case 'Objetos Perdidos':
        return 'Explora objetos encontrados';
      default:
        return '';
    }
  }

  PageRoute _buildPageRoute(Widget page) {
    return Platform.isIOS
        ? CupertinoPageRoute(builder: (context) => page)
        : MaterialPageRoute(builder: (context) => page);
  }

  Widget _buildMaterialBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                _playHapticFeedback();
              },
              icon: const Icon(Icons.home, size: 24, color: Colors.black),
              label: const Text(
                'Inicio',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilPage()),
                );
              },
              icon: const Icon(
                Icons.person_outline,
                size: 24,
                color: Colors.black54,
              ),
              label: const Text(
                'Perfil',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoTabBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _playHapticFeedback();
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.home, color: Colors.black),
                  SizedBox(height: 2),
                  Text(
                    'Inicio',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _playHapticFeedback();
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const PerfilPage()),
                );
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.person, color: Colors.black54),
                  SizedBox(height: 2),
                  Text(
                    'Perfil',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}