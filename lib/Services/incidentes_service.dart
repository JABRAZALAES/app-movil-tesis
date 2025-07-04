import 'dart:io';

import 'apiclient.dart';

class IncidentesService {
  final ApiClient _apiClient = ApiClient();
  String get baseUrl => _apiClient.baseUrl;

Future<Map<String, dynamic>> crearIncidente({
  required String descripcion,
  required String fechaReporte,
  required String horaReporte,
  required String laboratorioId, // <-- String si usas nombre
  int? computadoraId,
  required String estadoId,
  int? inconvenienteId,
  String? inconvenientePersonalizado,
  File? imagen,
  required String token,
}) async {
   try {
    final headers = {'Authorization': 'Bearer $token'};

    final data = {
      'descripcion': descripcion,
      'fechaReporte': fechaReporte,
      'horaReporte': horaReporte,
      'laboratorio_id': laboratorioId,
      if (computadoraId != null) 'computadora_id': computadoraId,
      'estadoId': estadoId,
      if (inconvenienteId != null) 'inconveniente_id': inconvenienteId,
      if (inconvenientePersonalizado != null && inconvenientePersonalizado.isNotEmpty)
        'inconveniente_personalizado': inconvenientePersonalizado,
    };
   

 
    if (imagen != null) {
      return await _apiClient.postWithImage(
        'incidentes',
        data,
        imagen,
        customHeaders: headers,
      );
    } else {
      return await _apiClient.post(
        'incidentes',
        data,
        customHeaders: headers,
      );
    }
  } catch (e) {
    throw Exception('Error al crear incidente: $e');
  }
}


  // Método para obtener los incidentes del usuario autenticado
  Future<List<dynamic>> obtenerMisIncidentes(String token) async {
    try {
      final headers = {'Authorization': 'Bearer $token'};
      final response = await _apiClient.get(
        'incidentes/mios',
        customHeaders: headers,
      );
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List;
      } else if (response is List) {
        return response;
      } else {
        throw Exception('Respuesta inesperada del servidor: $response');
      }
    } catch (e) {
      throw Exception('Error al obtener tus incidentes: $e');
    }
  }

  // Método para obtener todos los incidentes (solo admin/tecnico/jefe)
  Future<List<dynamic>> obtenerIncidentes(String token) async {
    try {
      final headers = {'Authorization': 'Bearer $token'};
      final response = await _apiClient.get(
        'incidentes',
        customHeaders: headers,
      );
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List;
      } else if (response is List) {
        return response;
      } else {
        throw Exception('Respuesta inesperada del servidor: $response');
      }
    } catch (e) {
      throw Exception('Error al obtener todos los incidentes: $e');
    }
  }

  // Método para actualizar el estado de un incidente (solo admin/tecnico/jefe)
Future<void> actualizarEstadoIncidente({
  required int incidenteId,
  required String estadoId,
  required String token,
  String? detalleResolucion,
}) async {
  try {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final data = {
      'estadoId': estadoId,
      if (detalleResolucion != null && detalleResolucion.isNotEmpty)
        'detalle_resolucion': detalleResolucion,
    };
    await _apiClient.patch('incidentes/$incidenteId/estado', data, customHeaders: headers);
  } catch (e) {
    throw Exception('Error al actualizar estado: $e');
  }
}

  Future<void> borrarIncidente({
    required int incidenteId,
    required String token,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    await _apiClient.delete('incidentes/$incidenteId', customHeaders: headers);
  }
    // ...dentro de la clase IncidentesService...
Future<List<Map<String, dynamic>>> obtenerLaboratorios(String token) async {
  final headers = {'Authorization': 'Bearer $token'};
  final response = await _apiClient.get('laboratorios', customHeaders: headers);
  if (response is List) {
    // ignore: unnecessary_cast
    return (response as List)
        .asMap()
        .entries
        .where((e) => e.value != null) // Filtra nulos
        .map((e) => {
              'id': (e.key + 1).toString(), // Siempre String
              'nombre': (e.value ?? 'Sin nombre').toString(),
            })
        .toList();
  } else if (response is Map<String, dynamic> && response.containsKey('data')) {
    return List<Map<String, dynamic>>.from(response['data'])
        .where((lab) => lab['id'] != null && lab['nombre'] != null)
        .map((lab) => {
              'id': lab['id'].toString(),
              'nombre': lab['nombre'].toString(),
            })
        .toList();
  } else {
    throw Exception('Error al obtener laboratorios');
  }
}
  
Future<List<Map<String, dynamic>>> obtenerComputadorasPorLaboratorio(String laboratorioId, String token) async {
  final headers = {'Authorization': 'Bearer $token'};
  final response = await _apiClient.get(
    'computadoras?laboratorio_id=$laboratorioId',
    customHeaders: headers,
  );
  if (response is List) {
    return List<Map<String, dynamic>>.from(response);
  } else if (response is Map<String, dynamic> && response.containsKey('data')) {
    return List<Map<String, dynamic>>.from(response['data']);
  } else {
    throw Exception('Error al obtener computadoras');
  }



}
  Future<List<Map<String, dynamic>>> obtenerInconvenientes(String token) async {
    final headers = {'Authorization': 'Bearer $token'};
    final response = await _apiClient.get('inconvenientes', customHeaders: headers);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else if (response is Map<String, dynamic> && response.containsKey('data')) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception('Error al obtener inconvenientes');
    }
  }


  // ...existing code...
} // <-- asegúrate de que todo esté dentro de la clase
