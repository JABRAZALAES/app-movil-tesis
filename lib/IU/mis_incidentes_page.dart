import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/incidentes_service.dart';

class MisIncidentesPage extends StatefulWidget {
  const MisIncidentesPage({super.key});

  @override
  State<MisIncidentesPage> createState() => _MisIncidentesPageState();
}

class _MisIncidentesPageState extends State<MisIncidentesPage> {
  final IncidentesService _service = IncidentesService();
  List<dynamic> _incidentes = [];
  List<Map<String, dynamic>> _inconvenientes = [];
  bool _isLoading = true;
  String? _error;
  String? _token;

  static const Color primaryColor = Color.fromARGB(255, 0, 33, 182);
  static const String baseUrl =
      'http://192.168.1.56:3000/'; // Cambia por tu IP si es necesario

  @override
  void initState() {
    super.initState();
    _cargarTokenYIncidentes();
  }

  Future<void> _cargarTokenYIncidentes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        setState(() {
          _error = 'Token no encontrado';
          _isLoading = false;
        });
        return;
      }

      // Cargar inconvenientes
      _inconvenientes = await _service.obtenerInconvenientes(_token!);

      final incidentes = await _service.obtenerMisIncidentes(_token!);

      // Ordenar incidentes del más nuevo al más viejo
      final incidentesOrdenados = List.from(incidentes);
      incidentesOrdenados.sort((a, b) {
        final fechaA = a['fechaReporte'] ?? a['fecha_reporte'] ?? '';
        final fechaB = b['fechaReporte'] ?? b['fecha_reporte'] ?? '';

        if (fechaA.isEmpty && fechaB.isEmpty) return 0;
        if (fechaA.isEmpty) return 1; // Los incidentes sin fecha van al final
        if (fechaB.isEmpty) return -1;

        try {
          final dateA = DateTime.parse(fechaA);
          final dateB = DateTime.parse(fechaB);
          return dateB.compareTo(
            dateA,
          ); // Orden descendente (más nuevo primero)
        } catch (e) {
          // Si hay error al parsear fechas, mantener el orden original
          return 0;
        }
      });

      setState(() {
        _incidentes = incidentesOrdenados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar incidentes: $e';
        _isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String estadoId) {
    switch (estadoId) {
      case 'EST_RESUELTO':
        return Colors.green;
      case 'EST_PENDIENTE':
        return Colors.orange;
      case 'EST_ANULADO':
        return Colors.redAccent;
      case 'EST_DEVUELTO':
        return Colors.red;
      case 'EST_EN_CUSTODIA':
        return Colors.blue;
      case 'EST_ESCALADO':
        return Colors.purple;
      case 'EST_RECLAMADO':
        return Colors.amber;
      case 'EST_MANTENIMIENTO': // <-- Agrega este caso
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estadoId) {
    switch (estadoId) {
      case 'EST_RESUELTO':
        return Icons.check_circle;
      case 'EST_PENDIENTE':
        return Icons.access_time;
      case 'EST_ANULADO':
      case 'EST_DEVUELTO':
        return Icons.cancel;
      case 'EST_EN_CUSTODIA':
        return Icons.security;
      case 'EST_ESCALADO':
        return Icons.trending_up;
      case 'EST_RECLAMADO':
        return Icons.assignment_return;
      case 'EST_MANTENIMIENTO': // <-- Agrega este caso
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  String _getEstadoNombre(String estadoId) {
    switch (estadoId) {
      case 'EST_RESUELTO':
        return 'Resuelto';
      case 'EST_PENDIENTE':
        return 'Pendiente';
      case 'EST_ANULADO':
        return 'Anulado';
      case 'EST_DEVUELTO':
        return 'Devuelto';
      case 'EST_EN_CUSTODIA':
        return 'En custodia';
      case 'EST_ESCALADO':
        return 'Escalado';
      case 'EST_RECLAMADO':
        return 'Reclamado';
      case 'EST_MANTENIMIENTO': // <-- Agrega este caso
        return 'Mantenimiento';
      default:
        return 'Desconocido';
    }
  }

  Map<String, int> _getResumenEstados() {
    final resumen = <String, int>{};
    for (final incidente in _incidentes) {
      final estadoId = incidente['estadoId'] ?? 'EST_PENDIENTE';
      resumen[estadoId] = (resumen[estadoId] ?? 0) + 1;
    }
    return resumen;
  }

  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  String _formatearHora(String horaStr) {
    try {
      final partes = horaStr.split(':');
      final hora = int.parse(partes[0]);
      final minuto = partes[1];
      final periodo = hora >= 12 ? 'PM' : 'AM';
      final hora12 = hora == 0 ? 12 : (hora > 12 ? hora - 12 : hora);
      return '$hora12:$minuto $periodo';
    } catch (e) {
      return horaStr;
    }
  }

  // Busca la descripción del inconveniente por su ID
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
      // ignore: unnecessary_null_comparison
      if (inc != null) {
        return inc['descripcion'] ?? 'Sin inconveniente';
      }
    }
    return 'Sin inconveniente';
  }

  void _mostrarDetalleIncidente(BuildContext context, dynamic incidente) {
    // --- NUEVO: Prepara la URL de la imagen ---
    String? urlFoto = incidente['urlFoto'];
    if (urlFoto != null && urlFoto.trim().isNotEmpty) {
      urlFoto = urlFoto.trim();
      if (!urlFoto.startsWith('http')) {
        if (urlFoto.startsWith('/')) {
          urlFoto = urlFoto.substring(1);
        }
        urlFoto = baseUrl + urlFoto;
      }
    } else {
      urlFoto = null;
    }

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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bug_report,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detalle del Incidente',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  'ID: ${incidente['id']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Estado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(
                                  incidente['estadoId'] ?? 'EST_PENDIENTE',
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getEstadoColor(
                                    incidente['estadoId'] ?? 'EST_PENDIENTE',
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getEstadoIcon(
                                      incidente['estadoId'] ?? 'EST_PENDIENTE',
                                    ),
                                    size: 16,
                                    color: _getEstadoColor(
                                      incidente['estadoId'] ?? 'EST_PENDIENTE',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getEstadoNombre(
                                      incidente['estadoId'] ?? 'EST_PENDIENTE',
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      color: _getEstadoColor(
                                        incidente['estadoId'] ??
                                            'EST_PENDIENTE',
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Descripción
                            _buildDetailSection(
                              'Descripción',
                              incidente['descripcion'] ?? 'Sin descripción',
                              Icons.description,
                            ),
                            const SizedBox(height: 16),

                            // Inconveniente
                            _buildDetailSection(
                              'Inconveniente',
                              _obtenerDescripcionInconveniente(incidente),
                              Icons.report_problem,
                            ),
                            const SizedBox(height: 16),

                            // Laboratorio
                            _buildDetailSection(
                              'Laboratorio',
                              (incidente['laboratorio_id'] ?? 'No especificado')
                                  .toString(),
                              Icons.science,
                            ),
                            const SizedBox(height: 16),

                            // USUARIO QUE REPORTÓ
                            if (incidente['usuario_reporta_nombre'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reportado por: ${incidente['usuario_reporta_nombre']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // USUARIO QUE RECLAMÓ
                            if (incidente['usuario_reclamante_nombre'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reclamado por: ${incidente['usuario_reclamante_nombre']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (incidente['detalle_resolucion'] != null &&
                                incidente['detalle_resolucion']
                                    .toString()
                                    .isNotEmpty)
                              _buildDetailSection(
                                (incidente['estadoId'] == 'EST_ANULADO')
                                    ? 'Motivo de anulación'
                                    : 'Detalle de resolución',
                                incidente['detalle_resolucion'],
                                Icons.info_outline,
                              ),
                            if (incidente['detalle_resolucion'] != null &&
                                incidente['detalle_resolucion']
                                    .toString()
                                    .isNotEmpty)
                              const SizedBox(height: 16),

                            // Computadora (si existe)
                            if (incidente['computadora'] != null)
                              Column(
                                children: [
                                  _buildDetailSection(
                                    'Computadora',
                                    incidente['computadora'],
                                    Icons.computer,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // Fecha y Hora
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailSection(
                                    'Fecha',
                                    _formatearFecha(
                                      incidente['fecha_reporte'] ?? '',
                                    ),
                                    Icons.calendar_today,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailSection(
                                    'Hora',
                                    _formatearHora(
                                      incidente['hora_reporte'] ?? '',
                                    ),
                                    Icons.access_time,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Imagen (si existe)
                            if (urlFoto != null && urlFoto.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Evidencia Fotográfica',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      urlFoto,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                'No se pudo cargar la imagen',
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
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

  Widget _buildDetailSection(String titulo, String contenido, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(contenido, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildIncidenteCard(dynamic incidente) {
    final estadoId = incidente['estadoId'] ?? 'EST_PENDIENTE';
    final descripcion = incidente['descripcion'] ?? 'Sin descripción';
final laboratorio = (incidente['laboratorio_id'] ?? 'Laboratorio desconocido').toString();
    final fechaReporte = incidente['fecha_reporte'] ?? '';
    final horaReporte = incidente['hora_reporte'] ?? '';

    // Prepara la URL de la imagen para el icono de cámara
    String? urlFoto = incidente['urlFoto'];
    if (urlFoto != null && urlFoto.trim().isNotEmpty) {
      urlFoto = urlFoto.trim();
      if (!urlFoto.startsWith('http')) {
        {
          urlFoto = urlFoto.substring(1);
        }
        urlFoto = baseUrl + urlFoto;
      }
    } else {
      urlFoto = null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleIncidente(context, incidente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bug_report,
                      color: Colors.white,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          laboratorio,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estadoId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getEstadoColor(estadoId),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEstadoIcon(estadoId),
                          size: 12,
                          color: _getEstadoColor(estadoId),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getEstadoNombre(estadoId),
                          style: TextStyle(
                            color: _getEstadoColor(estadoId),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  descripcion,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatearFecha(fechaReporte)} • ${_formatearHora(horaReporte)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (urlFoto != null && urlFoto.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        size: 12,
                        color: Colors.green,
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    final resumen = _getResumenEstados();
    final totalIncidentes = _incidentes.length;
    final aprobados = resumen['EST_RESUELTO'] ?? 0;
    final pendientes = resumen['EST_PENDIENTE'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Resumen de Incidentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tarjetas de resumen
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                  'Total',
                  totalIncidentes.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenItem(
                  'Aprobados',
                  aprobados.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenItem(
                  'Pendientes',
                  pendientes.toString(),
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mis Incidentes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _token == null || _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cargarTokenYIncidentes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
              : _incidentes.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: primaryColor,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tienes incidentes reportados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando reportes incidentes aparecerán aquí',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _cargarTokenYIncidentes,
                child: Column(
                  children: [
                    _buildResumenCard(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _incidentes.length,
                        itemBuilder: (context, index) {
                          return _buildIncidenteCard(_incidentes[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
