import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/objetosPerdidos_service.dart';

class AdminObjetosEncontradosPage extends StatefulWidget {
  const AdminObjetosEncontradosPage({super.key});

  @override
  State<AdminObjetosEncontradosPage> createState() =>
      _AdminObjetosEncontradosPageState();
}

class _AdminObjetosEncontradosPageState
    extends State<AdminObjetosEncontradosPage> {
  final ObjetosPerdidosService _objetosService = ObjetosPerdidosService();
  List<dynamic> _objetos = [];
  bool _cargando = true;
  String? _token;
  String? _rol;
  String _filtroEstado = 'TODOS'; // Filtro actual

  @override
  void initState() {
    super.initState();
    _verificarRolYCargar();
  }

  Future<void> _verificarRolYCargar() async {
    final prefs = await SharedPreferences.getInstance();
    _rol = prefs.getString('rol');
    if (_rol != 'tecnico' && _rol != 'jefe') {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No tienes permisos para acceder a esta sección',
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }
    _token = prefs.getString('token');
    await _cargarObjetos();
  }

  Future<void> _cargarObjetos() async {
    setState(() => _cargando = true);
    try {
      final objetos = await _objetosService.obtenerObjetosPerdidos();
      setState(() {
        _objetos = objetos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar objetos: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _aprobarObjeto(int id) async {
    if (_token == null) return;
    try {
      await _objetosService.actualizarEstadoObjetoPerdido(
        id: id,
        estadoId: 'EST_EN_CUSTODIA',
        token: _token!,
      );
      Navigator.of(context).pop('estado_cambiado');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar objeto: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _marcarDevuelto(int id) async {
    if (_token == null) return;
    try {
      await _objetosService.actualizarEstadoObjetoPerdido(
        id: id,
        estadoId: 'EST_DEVUELTO',
        token: _token!,
      );
      Navigator.of(context).pop('estado_cambiado');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como devuelto: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _eliminarObjeto(int id) async {
    if (_token == null) return;
    try {
      final eliminado = await _objetosService.borrarObjetoPerdido(
        id: id,
        token: _token!,
      );
      if (eliminado) {
        await _cargarObjetos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Objeto eliminado correctamente'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo eliminar el objeto'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar objeto: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar objeto'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este objeto perdido? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _eliminarObjeto(id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Color _estadoColor(String? estadoId) {
    switch (estadoId) {
      case 'EST_PENDIENTE':
        return const Color(0xFFFF6B35);
      case 'EST_EN_CUSTODIA':
        return const Color(0xFF6C5CE7);
      case 'EST_RECLAMADO':
        return const Color(0xFFE84393);
      case 'EST_DEVUELTO':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF636E72);
    }
  }

  String _estadoTexto(String? estadoId) {
    switch (estadoId) {
      case 'EST_PENDIENTE':
        return 'Pendiente';
      case 'EST_EN_CUSTODIA':
        return 'En custodia';
      case 'EST_RECLAMADO':
        return 'Reclamado';
      case 'EST_DEVUELTO':
        return 'Devuelto';
      default:
        return 'Desconocido';
    }
  }

  IconData _estadoIcon(String? estadoId) {
    switch (estadoId) {
      case 'EST_PENDIENTE':
        return Icons.schedule_rounded;
      case 'EST_EN_CUSTODIA':
        return Icons.shield_rounded;
      case 'EST_RECLAMADO':
        return Icons.person_search_rounded;
      case 'EST_DEVUELTO':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  int _contarPorEstado(String estado) {
    if (estado == 'TODOS') {
      return _objetos.where((obj) {
        final estadoId = obj['estadoId']?.toString();
        return estadoId == 'EST_PENDIENTE' ||
            estadoId == 'EST_EN_CUSTODIA' ||
            estadoId == 'EST_RECLAMADO' ||
            estadoId == 'EST_DEVUELTO';
      }).length;
    }
    return _objetos
        .where((obj) => obj['estadoId']?.toString() == estado)
        .length;
  }

  Widget _buildFiltroChip(String estado, String label, IconData icon) {
    final isSelected = _filtroEstado == estado;
    final count = _contarPorEstado(estado);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = estado;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color:
            isSelected
                ? Colors.white
                : (estado == 'TODOS'
                    ? const Color(0xFF0066B3)
                    : _estadoColor(estado)),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF2D3436),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.white.withOpacity(0.3)
                      : (estado == 'TODOS'
                              ? const Color(0xFF0066B3)
                              : _estadoColor(estado))
                          .withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : (estado == 'TODOS'
                            ? const Color(0xFF0066B3)
                            : _estadoColor(estado)),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      selectedColor:
          estado == 'TODOS' ? const Color(0xFF0066B3) : _estadoColor(estado),
      backgroundColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isSelected
                  ? Colors.transparent
                  : (estado == 'TODOS'
                          ? const Color(0xFF0066B3)
                          : _estadoColor(estado))
                      .withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String? estadoId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _estadoColor(estadoId),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _estadoColor(estadoId).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_estadoIcon(estadoId), color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            _estadoTexto(estadoId),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? const Color(0xFF636E72)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2D3436)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'No especificada';
    try {
      final partes = fecha.split('T');
      if (partes.isEmpty) return fecha;
      final fechaSolo = partes[0];
      final partesFecha = fechaSolo.split('-');
      if (partesFecha.length == 3) {
        return '${partesFecha[2]}/${partesFecha[1]}/${partesFecha[0]}';
      }
      return fechaSolo;
    } catch (_) {
      return fecha;
    }
  }

  void _mostrarDetalles(Map<String, dynamic> objeto) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  color: Colors.white, // <-- Fondo sólido
                  child: Column(
                    children: [
                      // Handle del modal
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagen del objeto
                              if (objeto['imagen_url'] != null &&
                                  objeto['imagen_url'].toString().isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  height: 180,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(objeto['imagen_url']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              // Header con título y estado
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      objeto['nombre_objeto'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3436),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildEstadoChip(
                                    objeto['estadoId']?.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Usuario que reportó el objeto
                              if (objeto['usuario_reporta_nombre'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Color(0xFF636E72),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Reportado por: ${objeto['usuario_reporta_nombre']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF636E72),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // Descripción
                              if (objeto['descripcion'] != null &&
                                  objeto['descripcion']
                                      .toString()
                                      .isNotEmpty) ...[
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    objeto['descripcion'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF636E72),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Detalles del objeto
                              const Text(
                                'Detalles del objeto',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      Icons.location_on_rounded,
                                      'Lugar encontrado',
                                      objeto['lugar'] ?? 'No especificado',
                                      const Color(0xFFE84393),
                                    ),
                                    const Divider(height: 24),
                                    _buildDetailRow(
                                      Icons.calendar_today_rounded,
                                      'Fecha perdida',
                                      _formatearFecha(objeto['fecha_perdida']),
                                      const Color(0xFF0984E3),
                                    ),
                                    if (objeto['hora_perdida'] != null) ...[
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        Icons.access_time_rounded,
                                        'Hora perdida',
                                        objeto['hora_perdida'],
                                        const Color(0xFF6C5CE7),
                                      ),
                                    ],
                                    if (objeto['laboratorio'] != null) ...[
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        Icons.computer,
                                        'Laboratorio',
                                        objeto['laboratorio'],
                                        const Color(0xFF00B894),
                                      ),
                                    ],
                                    if (objeto['id'] != null) ...[
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        Icons.tag_rounded,
                                        'ID del objeto',
                                        objeto['id'].toString(),
                                        const Color(0xFF636E72),
                                      ),
                                    ],
                                    if (objeto['usuario_reclamante_id'] !=
                                            null ||
                                        objeto['usuarioReclamanteId'] != null ||
                                        objeto['usuario_reclamante_nombre'] !=
                                            null) ...[
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        Icons.person_rounded,
                                        'Usuario reclamante',
                                        objeto['usuario_reclamante_nombre'] ??
                                            objeto['usuario_reclamante_nombre'] ??
                                            'ID: ${objeto['usuario_reclamante_id'] ?? objeto['usuarioReclamanteId']}',
                                        const Color(0xFFE84393),
                                      ),
                                    ],
                                    if (objeto['fecha_creacion'] != null) ...[
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        Icons.schedule_rounded,
                                        'Fecha de registro',
                                        _formatearFecha(
                                          objeto['fecha_creacion'],
                                        ),
                                        const Color(0xFF636E72),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Botón de acción y eliminar
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      objeto['estadoId']?.toString(),
                                      objeto['id'],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed:
                                        () => _confirmarEliminar(objeto['id']),
                                    icon: const Icon(
                                      Icons.delete_forever_rounded,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );

    // Aquí sí puedes usar result
    if (result == 'estado_cambiado') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡El estado se cambió correctamente!'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _cargarObjetos();
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> objetosFiltrados =
        _objetos.where((obj) {
          final estadoId = obj['estadoId']?.toString();
          final estadosValidos =
              estadoId == 'EST_PENDIENTE' ||
              estadoId == 'EST_EN_CUSTODIA' ||
              estadoId == 'EST_RECLAMADO' ||
              estadoId == 'EST_DEVUELTO';

          if (!estadosValidos) return false;

          if (_filtroEstado == 'TODOS') return true;
          return estadoId == _filtroEstado;
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Administrar Objetos',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0066B3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarObjetos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros por estado
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('TODOS', 'Todos', Icons.apps_rounded),
                  const SizedBox(width: 12),
                  _buildFiltroChip(
                    'EST_PENDIENTE',
                    'Pendientes',
                    Icons.schedule_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildFiltroChip(
                    'EST_EN_CUSTODIA',
                    'En custodia',
                    Icons.shield_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildFiltroChip(
                    'EST_RECLAMADO',
                    'Reclamados',
                    Icons.person_search_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildFiltroChip(
                    'EST_DEVUELTO',
                    'Devueltos',
                    Icons.check_circle_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Lista de objetos
          Expanded(
            child:
                _cargando
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0066B3),
                        ),
                      ),
                    )
                    : objetosFiltrados.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtroEstado == 'TODOS'
                                ? 'No hay objetos para administrar'
                                : 'No hay objetos en este estado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los objetos aparecerán aquí cuando estén disponibles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _cargarObjetos,
                      color: const Color(0xFF0066B3),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: objetosFiltrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final obj = objetosFiltrados[index];
                          final String? estadoId = obj['estadoId']?.toString();

                          return GestureDetector(
                            onTap: () => _mostrarDetalles(obj),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header con título y estado
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            obj['nombre_objeto'] ??
                                                'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF2D3436),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildEstadoChip(estadoId),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Descripción resumida
                                    if (obj['descripcion'] != null &&
                                        obj['descripcion']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        obj['descripcion'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 16),

                                    // Información básica
                                    Column(
                                      children: [
                                        _buildInfoRow(
                                          Icons.location_on_rounded,
                                          obj['lugar'] ??
                                              'Ubicación no especificada',
                                          iconColor: const Color(0xFFE84393),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.calendar_today_rounded,
                                          _formatearFecha(obj['fecha_perdida']),
                                          iconColor: const Color(0xFF0984E3),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Indicador de tap para ver más
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.touch_app_rounded,
                                            size: 16,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Toca para ver detalles completos',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
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
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String? estadoId, dynamic id) {
    switch (estadoId) {
      case 'EST_PENDIENTE':
        return ElevatedButton.icon(
          onPressed: () => _aprobarObjeto(id),
          icon: const Icon(Icons.shield_rounded, size: 20),
          label: const Text(
            'Aprobar y poner en custodia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        );

      case 'EST_EN_CUSTODIA':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_rounded,
                color: const Color(0xFF6C5CE7),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'En custodia',
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );

      case 'EST_RECLAMADO':
        return ElevatedButton.icon(
          onPressed: () => _marcarDevuelto(id),
          icon: const Icon(Icons.check_circle_rounded, size: 20),
          label: const Text(
            'Marcar como devuelto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B894),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        );

      case 'EST_DEVUELTO': // <-- Agrega este caso
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00B894).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00B894).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF00B894),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Devuelto',
                style: TextStyle(
                  color: Color(0xFF00B894),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estado desconocido',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
    }
  }
}
