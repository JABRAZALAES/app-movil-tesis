import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/objetosPerdidos_service.dart';

class ObjetosPerdidosPage extends StatefulWidget {
  const ObjetosPerdidosPage({super.key});

  @override
  State<ObjetosPerdidosPage> createState() => _ObjetosPerdidosPageState();
}

class _ObjetosPerdidosPageState extends State<ObjetosPerdidosPage>
    with TickerProviderStateMixin {
  final ObjetosPerdidosService _service = ObjetosPerdidosService();
  List<dynamic> _objetosDisponibles = [];
  List<dynamic> _misObjetos = [];
  List<Map<String, dynamic>> _laboratorios = [];
  bool _isLoading = false;
  String _error = '';
  String? _userId;
  final String _baseUrl = 'http://10.3.1.112:3000/';
  late TabController _tabController;

  static const Color primaryColor = Color.fromARGB(255, 0, 33, 182);
  static const Color secondaryColor = Color.fromARGB(255, 1, 5, 223);
  static const Color accentColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF6C5CE7);
  static const Color surfaceColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarObjetos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _obtenerNombreLaboratorio(dynamic objeto) {
    final labId = objeto['laboratorio_id']?.toString();
    final lab = _laboratorios.firstWhere(
      (l) => l['id'].toString() == labId,
      orElse: () => {},
    );
    print('Buscando labId: $labId en $_laboratorios. Resultado: $lab');
    return lab.isNotEmpty
        ? (lab['nombre'] ?? 'Laboratorio desconocido')
        : 'Laboratorio desconocido';
  }

  Future<void> _cargarObjetos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      // 1. Obtener periodo académico activo
      final periodo = await _service.obtenerPeriodoActivo(token!);
      if (periodo == null) {
        setState(() {
          _error = 'No hay periodo académico activo';
          _isLoading = false;
        });
        return;
      }
      final idPeriodoActual = periodo['id'].toString();
      _laboratorios = await _service.obtenerLaboratorios(token);

      // 2. Obtener objetos aprobados
      final objetos = await _service.obtenerObjetosAprobados();
      // Cargar laboratorios

      // 3. Filtrar disponibles: solo en custodia y del periodo actual
      final disponibles =
          objetos
              .where(
                (obj) =>
                    obj['estadoId'] == 'EST_EN_CUSTODIA' &&
                    obj['periodo_academico_id']?.toString() ==
                        idPeriodoActual &&
                    (obj['usuario_reclamante_id'] == null ||
                        obj['usuario_reclamante_id'].toString().isEmpty),
              )
              .toList();

      // 4. Filtrar mis objetos: en custodia o reclamados, del periodo actual, y reclamados por mí
      final misObjetos =
          objetos
              .where(
                (obj) =>
                    obj['usuario_reclamante_id']?.toString() == _userId &&
                    obj['periodo_academico_id']?.toString() ==
                        idPeriodoActual &&
                    (obj['estadoId'] == 'EST_EN_CUSTODIA' ||
                        obj['estadoId'] == 'EST_RECLAMADO'),
              )
              .toList();

      setState(() {
        _objetosDisponibles = disponibles;
        _misObjetos = misObjetos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los objetos: $e';
        _isLoading = false;
      });
    }
    print(_objetosDisponibles.map((o) => o['laboratorio_id']).toList());
    print(_laboratorios);
  }
Future<void> _reclamarObjeto(dynamic objeto) async {
  try {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      // Solo aquí usa SnackBar
      _showSnackBar('No se pudo identificar el usuario.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final response = await _service.reclamarObjeto(
      id: objeto['id'],
      estadoId: 'EST_RECLAMADO',
      usuarioReclamanteId: userId,
      token: token,
    );

    final mensaje = response['message']?.toString().toLowerCase() ?? '';
    final esExito = mensaje.contains('exitosamente');

    // Solo muestra el AlertDialog, no el SnackBar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esExito ? '¡Objeto reclamado!' : 'Error'),
        content: Text(
          esExito 
            ? '${response['message'] ?? 'Objeto reclamado exitosamente.'}\n\n⏰ Importante: Tienes 1 hora para retirar el objeto de la Jefatura de Laboratorios.'
            : response['message'] ?? 'No se pudo reclamar el objeto.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (esExito) {
      await _cargarObjetos();
    }
  } catch (e) {
    // Solo muestra el AlertDialog de error
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error!'),
          ],
        ),
        content: Text(
          'Ocurrió un error al reclamar el objeto.\n${e.toString()}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError
                ? errorColor
                : isSuccess
                ? accentColor
                : secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildResumenCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Disponibles',
              _objetosDisponibles.length.toString(),
              Icons.search,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Mis Objetos',
              _misObjetos.length.toString(),
              Icons.person,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDisponiblesTab() {
    return RefreshIndicator(
      onRefresh: _cargarObjetos,
      color: primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildResumenCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.search, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Objetos disponibles',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'Objetos aprobados listos para reclamar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_objetosDisponibles.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No hay objetos disponibles',
                subtitle:
                    'Por el momento no hay objetos perdidos\naprobados para reclamar.',
                color: infoColor,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ObjetoPerdidoCard(
                      objeto: _objetosDisponibles[index],
                      laboratorioNombre: _obtenerNombreLaboratorio(
                        _objetosDisponibles[index],
                      ),
                      onReclamar:
                          () => _reclamarObjeto(_objetosDisponibles[index]),
                      tipoCard: TipoCard.disponible,
                      baseUrl: _baseUrl,
                    ),
                  ),
                  childCount: _objetosDisponibles.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildMisObjetosTab() {
    return RefreshIndicator(
      onRefresh: _cargarObjetos,
      color: primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildResumenCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis objetos reclamados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Seguimiento de objetos que has reclamado',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_misObjetos.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No has reclamado objetos',
                subtitle:
                    'Cuando reclames un objeto aparecerá\naquí con su estado actual.',
                color: warningColor,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ObjetoPerdidoCard(
                      objeto: _misObjetos[index],
                      tipoCard: TipoCard.mio,
                      baseUrl: _baseUrl,
                    ),
                  ),
                  childCount: _misObjetos.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.search, color: Colors.white),
            SizedBox(width: 8),
            Text('Objetos Perdidos'),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Disponibles'),
            Tab(icon: Icon(Icons.person_outline), text: 'Mis Objetos'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Cargando objetos...',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
              : _error.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Error al cargar',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: errorColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _cargarObjetos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [_buildDisponiblesTab(), _buildMisObjetosTab()],
              ),
    );
  }
}

// --- Widget mejorado para mostrar cada objeto perdido ---
enum TipoCard { disponible, mio }

class ObjetoPerdidoCard extends StatelessWidget {
  final dynamic objeto;
  final VoidCallback? onReclamar;
  final String? laboratorioNombre;
  final TipoCard tipoCard;
  final String baseUrl;

  const ObjetoPerdidoCard({
    super.key,
    required this.objeto,
    this.onReclamar,
    required this.tipoCard,
    required this.baseUrl,
    this.laboratorioNombre,
  });

  static const Color primaryColor = Color(0xFF0066B3);
  static const Color secondaryColor = Color(0xFF4A90D9);
  static const Color accentColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF6C5CE7);

  Color _estadoColor(String? estadoId) {
    switch (estadoId) {
      case 'EST_PENDIENTE':
        return warningColor;
      case 'EST_EN_CUSTODIA':
        return infoColor;
      case 'EST_RECLAMADO':
        return secondaryColor;
      case 'EST_DEVUELTO':
        return accentColor;
      default:
        return const Color(0xFF6B7280);
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
        return Icons.schedule;
      case 'EST_EN_CUSTODIA':
        return Icons.security;
      case 'EST_RECLAMADO':
        return Icons.person_search;
      case 'EST_DEVUELTO':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _estadoDescripcion(String? estadoId) {
    switch (estadoId) {
      case 'EST_RECLAMADO':
        return 'Esperando validación del administrador';
      case 'EST_DEVUELTO':
        return 'Objeto devuelto exitosamente';
      default:
        return '';
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';
    try {
      final date = DateTime.tryParse(fecha.toString());
      if (date == null) return fecha.toString();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  void _mostrarDetalles(BuildContext context) {
    // Prepara la URL de la imagen
    String? urlFoto = objeto['urlFoto'];
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
    print('URL final de la imagen: $urlFoto');

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
                            child: Icon(
                              _estadoIcon(objeto['estadoId']),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  objeto['nombre_objeto'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  'ID: ${objeto['id']}',
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
                                color: _estadoColor(
                                  objeto['estadoId'],
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _estadoColor(objeto['estadoId']),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _estadoIcon(objeto['estadoId']),
                                    size: 16,
                                    color: _estadoColor(objeto['estadoId']),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _estadoTexto(
                                      objeto['estadoId'],
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      color: _estadoColor(objeto['estadoId']),
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
                              objeto['descripcion'] ?? 'Sin descripción',
                              Icons.description,
                            ),
                            const SizedBox(height: 16),

                            // Lugar
                            _buildDetailSection(
                              'Lugar',
                              objeto['lugar'] ?? 'Sin ubicación',
                              Icons.location_on,
                            ),
                            const SizedBox(height: 16),

                            // Laboratorio
                            _buildDetailSection(
                              'Laboratorio',
                              laboratorioNombre ?? 'Laboratorio desconocido',
                              Icons.science,
                            ),
                            const SizedBox(height: 16),

                            // Estado
                            _buildDetailSection(
                              'Estado',
                              _estadoTexto(objeto['estadoId']),
                              _estadoIcon(objeto['estadoId']),
                            ),
                            if (_estadoDescripcion(
                              objeto['estadoId'],
                            ).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 16,
                                ),
                                child: Text(
                                  _estadoDescripcion(objeto['estadoId']),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),

                            // Fecha
                            _buildDetailSection(
                              'Fecha de pérdida',
                              _formatearFecha(objeto['fecha_perdida']),
                              Icons.calendar_today,
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

  @override
  Widget build(BuildContext context) {
    final estadoId = objeto['estadoId']?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _mostrarDetalles(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _estadoColor(estadoId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _estadoIcon(estadoId),
                      color: _estadoColor(estadoId),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      objeto['nombre_objeto'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _estadoColor(estadoId),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _estadoTexto(estadoId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Descripción
              if (objeto['descripcion'] != null &&
                  objeto['descripcion'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    objeto['descripcion'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Información adicional
              _buildInfoRow(
                Icons.location_on,
                objeto['lugar'] ?? 'Sin ubicación',
                primaryColor,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                _formatearFecha(objeto['fecha_perdida']),
                const Color(0xFF6B7280),
              ),

              if (objeto['laboratorio'] != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.science,
                  'Lab: ${objeto['laboratorio']}',
                  infoColor,
                ),
              ],
              if (laboratorioNombre != null &&
                  laboratorioNombre!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.business, laboratorioNombre!, infoColor),
              ],
              const SizedBox(height: 20),

              // Botón de acción o estado
              if (tipoCard == TipoCard.disponible &&
                  estadoId == 'EST_EN_CUSTODIA')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReclamar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Reclamar objeto',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              if (tipoCard == TipoCard.mio)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _estadoColor(estadoId).withOpacity(0.1),
                        _estadoColor(estadoId).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _estadoColor(estadoId).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _estadoIcon(estadoId),
                            color: _estadoColor(estadoId),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _estadoTexto(estadoId),
                            style: TextStyle(
                              color: _estadoColor(estadoId),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (_estadoDescripcion(estadoId).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _estadoDescripcion(estadoId),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
