import 'dart:io';
import 'apiclient.dart';

class ObjetosPerdidosService {
  final ApiClient _apiClient = ApiClient();

  // Crear objeto perdido
  Future<Map<String, dynamic>> crearObjetoPerdido({
    required String nombreObjeto,
    required String descripcion,
    required String lugar,
    required String laboratorio,
    required String
    estadoId, // Usa String para IDs textuales como 'EST_PENDIENTE'
    File? imagen,
    required String token,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};

    final data = {
      'nombre_objeto': nombreObjeto,
      'descripcion': descripcion,
      'lugar': lugar,
      'laboratorio': laboratorio,
      'estadoId': estadoId,
    };

    if (imagen != null) {
      return await _apiClient.postWithImage(
        'objetos-perdidos',
        data,
        imagen,
        customHeaders: headers,
      );
    } else {
      return await _apiClient.post(
        'objetos-perdidos',
        data,
        customHeaders: headers,
      );
    }
  }

  // Obtener todos los objetos perdidos
  Future<List<dynamic>> obtenerObjetosPerdidos() async {
    final response = await _apiClient.get('objetos-perdidos');
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'] as List;
    }
    return [];
  }

  // Obtener objetos perdidos con estado aprobado
  Future<List<dynamic>> obtenerObjetosAprobados() async {
    final response = await _apiClient.get('objetos-perdidos');
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      // Incluye los objetos en custodia (aprobados) y reclamados/devueltos para el seguimiento
      return (response['data'] as List)
          .where(
            (obj) =>
                obj['estadoId'] == 'EST_EN_CUSTODIA' ||
                obj['estadoId'] == 'EST_RECLAMADO' ||
                obj['estadoId'] == 'EST_DEVUELTO',
          )
          .toList();
    }
    return [];
  }

  // Reclamar objeto perdido
  Future<Map<String, dynamic>> reclamarObjeto({
    required int id,
    required String token,
    required String estadoId,
    required String usuarioReclamanteId,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final data = {
      'estadoId': estadoId,
      'usuarioReclamanteId': usuarioReclamanteId,
    };

    return await _apiClient.post(
      'objetos-perdidos/$id/reclamar',
      data,
      customHeaders: headers,
    );
  }

  // Cambiar estado de objeto perdido (solo admin/tecnico/jefe)
  Future<Map<String, dynamic>> actualizarEstadoObjetoPerdido({
    required int id,
    required String estadoId, // Usa String para IDs textuales
    required String token,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final data = {'estadoId': estadoId};
    return await _apiClient.patch(
      'objetos-perdidos/$id/estado',
      data,
      customHeaders: headers,
    );
  }

  // Obtener laboratorios
Future<List<Map<String, dynamic>>> obtenerLaboratorios(String token) async {
  final headers = {'Authorization': 'Bearer $token'};
  final response = await _apiClient.get(
    'laboratorios',
    customHeaders: headers,
  );
  if (response is List) {
    // Si el backend responde directamente una lista de laboratorios
    return List<Map<String, dynamic>>.from(response);
  } else if (response is Map<String, dynamic> &&
      response.containsKey('data')) {
    // Si el backend responde { data: [...] }
    return List<Map<String, dynamic>>.from(response['data']);
  }
  return [];
}
  // Método para borrar un objeto perdido
  // ...existing code...

  Future<bool> borrarObjetoPerdido({
    required int id,
    required String token,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await _apiClient.delete(
      'objetos-perdidos/$id', // <-- AJUSTA AQUÍ LA RUTA
      customHeaders: headers,
    );

    if (response is Map<String, dynamic> &&
        response['message'] == 'Objeto perdido borrado correctamente') {
      return true;
    }
    return false;
  }


Future<Map<String, dynamic>> guardarEvidenciaEntrega({
  required int id,
  required String token,
  required String observaciones,
  required String evidenciaUrl,
}) async {
  final headers = {'Authorization': 'Bearer $token'};
  final data = {
    'evidenciaUrl': evidenciaUrl,
    'observaciones': observaciones,
  };

  return await _apiClient.post(
    'objetos-perdidos/$id/evidencia',
    data,
    customHeaders: headers,
  );
}

Future<Map<String, dynamic>> subirEvidenciaEntrega({
  required int id,
  required String token,
  required File imagen,
  required String observaciones,
}) async {
  final headers = {'Authorization': 'Bearer $token'};
  return await _apiClient.postWithImage(
    'objetos-perdidos/$id/evidencia',
    {'observaciones': observaciones},
    imagen,
    customHeaders: headers,
    // No necesitas imageFieldName porque tu método ya usa 'urlFoto'
  );
}


}
