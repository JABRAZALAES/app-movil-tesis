import 'dart:convert';
import 'package:http/http.dart' as http;

class SesionBloqueadaException implements Exception {
  final String message;
  SesionBloqueadaException([this.message = "Sesión iniciada en otro dispositivo"]);
  @override
  String toString() => message;
}

class AuthService {
  final String baseUrl = 'http://192.168.1.56:3000/api/usuarios';


Future<Map<String, dynamic>> register({
  required String nombre,
  required String correo,
  required String contrasena,
  required String tipoUsuario, // <-- Agrega esto
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'tipo_usuario': tipoUsuario, // <-- Agrega esto
    }),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Error al registrar usuario');
  }
}

Future<Map<String, dynamic>> login({
  required String correo,
  required String contrasena,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
  );

  final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (error['message']?.toString().contains('Sesión iniciada en otro dispositivo') == true) {
    throw SesionBloqueadaException();
  } else {
    throw Exception(error['message'] ?? 'Error al iniciar sesión');
  }
}

Future<Map<String, dynamic>> getUsuarioActual(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
 
if (response.statusCode == 200) {
 
  return jsonDecode(response.body);
} else if (
  error['message']?.toString().contains('Sesión iniciada en otro dispositivo') == true ||
  error['message']?.toString().contains('UID no encontrado') == true ||
  error['message']?.toString().contains('Sesión inválida') == true || // <-- Agrega esto
  error['message']?.toString().contains('cerrada en otro dispositivo') == true // <-- Y esto
) {
 
  throw SesionBloqueadaException();
} else {
  
  throw Exception(error['message'] ?? 'Error al obtener usuario actual');
}
}

  Future<Map<String, dynamic>> recuperarContrasena({
    required String correo,
  }) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.56:3000/api/auth/recuperar-contrasena'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al recuperar contraseña');
    }
  }

  Future<Map<String, dynamic>> cambiarContrasena({
    required String token,
    required String nuevaContrasena,
  }) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.56:3000/api/auth/cambiar-contrasena'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nuevaContrasena': nuevaContrasena}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al cambiar contraseña');
    }
  }
Future<String?> obtenerTipoUsuarioPorCorreo(String correo, String token) async {
  final url = Uri.parse('http://192.168.1.56:3000/api/auth/tipo-usuario?correo=$correo');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['tipo_usuario'] as String?;
  }
  return null;
}
    Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.56:3000/api/usuarios/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cerrar sesión');
    }
  }
}
