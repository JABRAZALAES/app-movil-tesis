import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import '../Services/auth_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final AuthService _authService = AuthService();
  String _nombre = 'Nombre no disponible';
  String _correo = 'Correo no disponible';
  String _tipoUsuario = 'Tipo de usuario no disponible';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    String? tipo = prefs.getString('tipo_usuario');
    final correo = prefs.getString('correo');
    final token = prefs.getString('token');
    // Si no hay tipo_usuario, intenta obtenerlo del backend protegido
    if ((tipo == null || tipo.isEmpty) && correo != null && correo.isNotEmpty && token != null && token.isNotEmpty) {
      try {
        final correoLimpio = correo.trim().toLowerCase();
        tipo = await _authService.obtenerTipoUsuarioPorCorreo(correoLimpio, token);
        if (tipo != null && tipo.isNotEmpty) {
          await prefs.setString('tipo_usuario', tipo);
        }
      } catch (e) {
        // Puedes mostrar un mensaje de error si lo deseas
      }
    }
    setState(() {
      _nombre = prefs.getString('nombre') ?? 'Nombre no disponible';
      _correo = correo ?? 'Correo no disponible';
      _tipoUsuario = (tipo != null && tipo.isNotEmpty)
          ? tipo
          : 'No definido. Contacte al administrador.';
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 33, 182),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar simple
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color.fromARGB(255, 6, 36, 170),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 30),

            // Información principal
            Text(
              _nombre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              _correo,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Tipo de usuario
            _buildInfoTile(Icons.person_outline, 'Tipo de usuario', _tipoUsuario),

            // Lista de información
            _buildInfoTile(Icons.domain, 'Institución', 'ESPE'),
            _buildInfoTile(Icons.location_on_outlined, 'Campus', 'Santo Domingo, Luz de America'),
            _buildInfoTile(Icons.security, 'Estado', 'Activo'),

            const SizedBox(height: 50),

            // Botón simple de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(255, 3, 31, 156),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}