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

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _buttonAnimations; 

  String _nombreUsuario = 'Usuario';

  @override
  void initState() {
    super.initState();

    _cargarNombreUsuario();

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

  Future<void> _cargarNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Usuario';
    setState(() {
      _nombreUsuario = nombre;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Logo Section
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: Tween<double>(begin: 0.9, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.0,
                            0.3,
                            curve: Curves.easeOut,
                          ),
                        ),
                      )
                      .value,
                  child: Container(
                    width: screenSize.width,
                    height: screenSize.height * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/ITIN.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Title Section
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(
                            0.3,
                            0.5,
                            curve: Curves.easeIn,
                          ),
                        ),
                      )
                      .value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: const Text(
                      'REPORTE DE INCIDENTES Y PÉRDIDAS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Botones principales
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
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
                      'Reportar Objeto Perdido',
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
                      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('rol')),
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
                                    icon: const Icon(Icons.admin_panel_settings, size: 20),
                                    label: const Text(
                                     
                                        'Administrar Incidentes',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0066B3),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _playHapticFeedback();
                                      Navigator.pushNamed(context, '/adminIncidentes');
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
                                    
                                        'Administrar Objetos Encontrados',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14),
                                      
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0066B3),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _playHapticFeedback();
                                      Navigator.pushNamed(context, '/adminObjetosEncontrados');
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
                    opacity: Tween<double>(begin: 0.0, end: 1.0)
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            radius: 24,
                            child: const Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.black54,
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
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                  opacity: Tween<double>(begin: 0.0, end: 1.0)
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
                  child: Platform.isIOS
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

  void _playHapticFeedback() {
    HapticFeedback.lightImpact();
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
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Platform.isIOS
                            ? CupertinoIcons.chevron_right
                            : Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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