import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/incidentes_service.dart';

// Colores y estilos armonizados con admin_ObjetosEncontrados.dart
class AppColors {
  static const Color primary = Color(0xFF0066B3);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color error = Color(0xFFdc3545);
  static const Color success = Color(0xFF00B894); // Verde armónico
  static const Color warning = Color(0xFFFF6B35); // Naranja armónico
  static const Color info = Color(0xFF6C5CE7); // Púrpura armónico
  static const Color secondary = Color(0xFFE84393); // Rosa armónico
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF6C757D);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x0F000000);
}

class AdminIncidentesPage extends StatefulWidget {
  const AdminIncidentesPage({super.key});

  @override
  State<AdminIncidentesPage> createState() => _AdminIncidentesPageState();
}

class _AdminIncidentesPageState extends State<AdminIncidentesPage> {
  static const String _baseUrl = 'http://192.168.1.14:3000/';
  final IncidentesService _incidentesService = IncidentesService();
  List<dynamic> _incidentes = [];
  List<Map<String, dynamic>> _inconvenientes = [];
  bool _cargando = true;
  String? _token;
  String? _rol;
  String _filtroEstado = 'TODOS';

  @override
  void initState() {
    super.initState();
    _verificarRolYcargar();
  }

  Future<void> _borrarIncidente(int id) async {
    try {
      if (_token == null) throw Exception('No hay token de usuario');

      await _incidentesService.borrarIncidente(incidenteId: id, token: _token!);

      setState(() {
        _incidentes.removeWhere((incidente) => incidente['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incidente eliminado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _verificarRolYcargar() async {
    final prefs = await SharedPreferences.getInstance();
    _rol = prefs.getString('rol')?.toLowerCase();

    if (_rol != 'tecnico' && _rol != 'jefe' && _rol != 'admin') {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No tienes permisos para acceder a esta sección',
            ),
            backgroundColor: AppColors.error,
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
    await _cargarIncidentes();
    await _cargarInconvenientes();
  }

  Future<void> _cargarIncidentes() async {
    if (!mounted) return;

    setState(() => _cargando = true);
    try {
      if (_token == null) {
        throw Exception('Token no encontrado');
      }

      final incidentes = await _incidentesService.obtenerIncidentes(_token!);

      if (mounted) {
        setState(() {
          _incidentes = incidentes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar incidentes: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cargarInconvenientes() async {
    if (_token == null) return;
    try {
      final inconvenientes = await _incidentesService.obtenerInconvenientes(
        _token!,
      );
      setState(() {
        _inconvenientes = List<Map<String, dynamic>>.from(inconvenientes);
      });
    } catch (e) {
      setState(() {
        _inconvenientes = [];
      });
    }
  }

  String _obtenerDescripcionInconveniente(dynamic incidente) {
    if (incidente['inconveniente_personalizado'] != null &&
        incidente['inconveniente_personalizado'].toString().isNotEmpty) {
      return incidente['inconveniente_personalizado'];
    }
    final id = incidente['inconveniente_id'];
    if (id != null) {
      final inc = _inconvenientes.firstWhere(
        (e) => e['id'].toString() == id.toString(),
        orElse: () => <String, dynamic>{},
      );
      if (inc.isNotEmpty && inc['descripcion'] != null) {
        return inc['descripcion'];
      }
    }
    return 'Sin inconveniente';
  }

  // MÉTODO MODIFICADO: Cambiar estado de incidente con detalle de resolución
  Future<void> _cambiarEstado(int incidenteId, String nuevoEstado) async {
    if (_token == null) return;

    String? detalleResolucion;

    // Estados que requieren detalle
    final requiereDetalle = [
      'EST_APROBADO',
      'EST_ANULADO',
      'EST_DEVUELTO',
      'EST_ESCALADO',
    ];

    if (requiereDetalle.contains(nuevoEstado)) {
      detalleResolucion = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          String label = 'Detalle de resolución';
          if (nuevoEstado == 'EST_ANULADO') label = 'Motivo de anulación';
          if (nuevoEstado == 'EST_APROBADO') label = 'Detalle de aprobación';
          if (nuevoEstado == 'EST_DEVUELTO') label = 'Detalle de devolución';
          if (nuevoEstado == 'EST_ESCALADO') label = 'Motivo de escalado';

          return AlertDialog(
            title: Text(label),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ingrese $label...',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(context, controller.text.trim());
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
      if (detalleResolucion == null || detalleResolucion.isEmpty) return;
    }

    try {
      await _incidentesService.actualizarEstadoIncidente(
        incidenteId: incidenteId,
        estadoId: nuevoEstado,
        token: _token!,
        detalleResolucion: detalleResolucion,
      );
      await _cargarIncidentes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Estado actualizado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getEstadoColor(String? estadoId) {
    switch (estadoId) {
      case 'EST_APROBADO':
        return AppColors.success;
      case 'EST_PENDIENTE':
        return AppColors.warning;
      case 'EST_ANULADO':
        return AppColors.error;

      case 'EST_EN_CUSTODIA':
        return AppColors.info;
      case 'EST_ESCALADO':
        return AppColors.secondary;
      case 'EST_MANTENIMIENTO': // <-- Agrega esto
        return AppColors.info;

      default:
        return AppColors.textLight;
    }
  }

  IconData _getEstadoIcon(String? estadoId) {
    switch (estadoId) {
      case 'EST_APROBADO':
        return Icons.check_circle_rounded;
      case 'EST_PENDIENTE':
        return Icons.schedule_rounded;
      case 'EST_ANULADO':
        return Icons.cancel_rounded;

      case 'EST_EN_CUSTODIA':
        return Icons.shield_rounded;
      case 'EST_ESCALADO':
        return Icons.trending_up_rounded;
      case 'EST_MANTENIMIENTO': // <-- Agrega esto
        return Icons.build;

      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getEstadoTexto(String? estadoId) {
    switch (estadoId) {
      case 'EST_APROBADO':
        return 'Aprobado';
      case 'EST_PENDIENTE':
        return 'Pendiente';
      case 'EST_ANULADO':
        return 'Anulado';
      case 'EST_EN_CUSTODIA':
        return 'En custodia';
      case 'EST_ESCALADO':
        return 'Escalado';
      case 'EST_MANTENIMIENTO': // <-- Agrega esto
        return 'Mantenimiento';

      default:
        return 'Desconocido';
    }
  }

  List<dynamic> get _incidentesFiltrados {
    if (_filtroEstado == 'TODOS') return _incidentes;
    return _incidentes.where((incidente) {
      final estado = (incidente['estadoId'] ?? '').toString().toUpperCase();
      return estado == _filtroEstado;
    }).toList();
  }

  Widget _buildFiltros() {
    return Container(
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
              'EST_APROBADO',
              'Aprobados',
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 12),
            _buildFiltroChip('EST_ANULADO', 'Anulados', Icons.cancel_rounded),
            const SizedBox(width: 12),
            _buildFiltroChip(
              'EST_ESCALADO',
              'Escalados',
              Icons.trending_up_rounded,
            ),
            const SizedBox(width: 12),
            _buildFiltroChip('EST_MANTENIMIENTO', 'Mantenimiento', Icons.build),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String etiqueta, IconData icon) {
    final isSelected = _filtroEstado == valor;
    final count =
        _incidentes.where((inc) {
          final estado = (inc['estadoId'] ?? '').toString().toUpperCase();
          if (valor == 'TODOS') {
            return [
              'EST_PENDIENTE',
              'EST_APROBADO',
              'EST_ANULADO',
              'EST_ESCALADO',
              'EST_MANTENIMIENTO'
                  'EST_DEVUELTO',
              'EST_RECLAMADO',
            ].contains(estado);
          }
          return estado == valor;
        }).length;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = valor;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : _getEstadoColor(valor),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
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
                      : _getEstadoColor(valor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isSelected ? Colors.white : _getEstadoColor(valor),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      selectedColor: _getEstadoColor(valor),
      backgroundColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isSelected
                  ? Colors.transparent
                  : _getEstadoColor(valor).withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String? estadoId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getEstadoColor(estadoId),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getEstadoColor(estadoId).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getEstadoIcon(estadoId), color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            _getEstadoTexto(estadoId),
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

  Widget _buildDetailSection(String titulo, String contenido, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textLight.withOpacity(0.15)),
          ),
          child: Text(
            contenido,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidenteCard(dynamic incidente) {
    final estadoId = (incidente['estadoId'] ?? '').toString().toUpperCase();
    final descripcion = incidente['descripcion'] ?? 'Sin descripción';
    final laboratorio = incidente['laboratorio'] ?? 'Laboratorio desconocido';
    final fechaReporte =
        (incidente['fechaReporte'] ?? incidente['fecha_reporte'] ?? '')
            .toString();
    final horaReporte =
        (incidente['horaReporte'] ?? incidente['hora_reporte'] ?? '')
            .toString();

    String fechaFormateada =
        fechaReporte.length >= 10
            ? fechaReporte.substring(0, 10)
            : fechaReporte;
    String horaFormateada =
        horaReporte.length >= 5 ? horaReporte.substring(0, 5) : horaReporte;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.cardBackground,
        child: InkWell(
          onTap: () => _mostrarDetalleIncidente(context, incidente),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono, título y estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bug_report,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _obtenerDescripcionInconveniente(incidente),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            laboratorio,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildEstadoChip(estadoId),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Eliminar incidente'),
                                  content: const Text(
                                    '¿Estás seguro de que deseas eliminar este incidente?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            await _borrarIncidente(incidente['id']);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.error.withOpacity(0.7),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (descripcion.isNotEmpty &&
                    descripcion != 'Sin descripción') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      descripcion,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$fechaFormateada • $horaFormateada',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleIncidente(BuildContext context, dynamic incidente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final estadoId =
                  (incidente['estadoId'] ?? '').toString().toUpperCase();

              // Imagen
              String? urlFoto = incidente['urlFoto'];
              if (urlFoto != null && urlFoto.trim().isNotEmpty) {
                urlFoto = urlFoto.trim();
                if (!urlFoto.startsWith('http')) {
                  if (urlFoto.startsWith('/')) {
                    urlFoto = urlFoto.substring(1);
                  }
                  urlFoto = _baseUrl + urlFoto;
                }
              } else {
                urlFoto = null;
              }

              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.bug_report,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _obtenerDescripcionInconveniente(incidente),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${incidente['id']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 22),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estadoId).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getEstadoColor(estadoId).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getEstadoIcon(estadoId),
                              color: _getEstadoColor(estadoId),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estado Actual',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getEstadoColor(
                                        estadoId,
                                      ).withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getEstadoTexto(estadoId),
                                    style: TextStyle(
                                      color: _getEstadoColor(estadoId),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'EST_PENDIENTE',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: AppColors.warning,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Marcar como Pendiente',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'EST_APROBADO',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Marcar como Aprobado',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'EST_ANULADO',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            color: AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Anular Incidente',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'EST_ESCALADO',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            color: AppColors.secondary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Escalar Incidente',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'EST_MANTENIMIENTO',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.build,
                                            color: AppColors.success,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'En Mantenimiento',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                              onSelected: (valor) {
                                Navigator.of(context).pop();
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () {
                                    _cambiarEstado(incidente['id'], valor);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (incidente['usuario_reporta_nombre'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reportado por: ${incidente['usuario_reporta_nombre']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (incidente['usuario_reclamante_nombre'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reclamado por: ${incidente['usuario_reclamante_nombre']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection(
                              'Descripción',
                              incidente['descripcion'] ?? 'Sin descripción',
                              Icons.description,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailSection(
                                    'Laboratorio',
                                    incidente['laboratorio'] ??
                                        'No especificado',
                                    Icons.science,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailSection(
                                    'Usuario',
                                    incidente['usuario'] ?? 'Desconocido',
                                    Icons.person,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailSection(
                                    'Fecha',
                                    (incidente['fechaReporte'] ??
                                            incidente['fecha_reporte'] ??
                                            '')
                                        .toString()
                                        .substring(0, 10),
                                    Icons.calendar_today,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailSection(
                                    'Hora',
                                    (incidente['horaReporte'] ??
                                            incidente['hora_reporte'] ??
                                            '')
                                        .toString()
                                        .substring(0, 5),
                                    Icons.access_time,
                                  ),
                                ),
                              ],
                            ),
                            if (incidente['detalle_resolucion'] != null &&
                                incidente['detalle_resolucion']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildDetailSection(
                                estadoId == 'EST_ANULADO'
                                    ? 'Motivo de Anulación'
                                    : 'Detalle de Resolución',
                                incidente['detalle_resolucion'],
                                estadoId == 'EST_ANULADO'
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                              ),
                            ],
                            if (urlFoto != null && urlFoto.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.photo_camera,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Evidencia Fotográfica',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        maxHeight: 250,
                                      ),
                                      child: Image.network(
                                        urlFoto,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return SizedBox(
                                            height: 180,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primary,
                                                strokeWidth: 2,
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 180,
                                            decoration: BoxDecoration(
                                              color: AppColors.textLight
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: AppColors.textLight,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'No se pudo cargar la imagen',
                                                  style: TextStyle(
                                                    color: AppColors.textLight,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Incidentes (Técnico/Jefe/Admin)',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
        ),
      ),
      body:
          _cargando
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : Column(
                children: [
                  _buildFiltros(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _cargarIncidentes,
                      color: AppColors.primary,
                      child:
                          _incidentesFiltrados.isEmpty
                              ? const Center(
                                child: Text(
                                  'No hay incidentes para mostrar.',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _incidentesFiltrados.length,
                                itemBuilder: (context, index) {
                                  return _buildIncidenteCard(
                                    _incidentesFiltrados[index],
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
    );
  }
}
