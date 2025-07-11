import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/incidentes_service.dart';

class ReporteIncidentePage extends StatefulWidget {
  const ReporteIncidentePage({super.key});

  @override
  State<ReporteIncidentePage> createState() => _IncidenteFormPageState();
}

class _IncidenteFormPageState extends State<ReporteIncidentePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _otroInconvenienteController = TextEditingController();

  String? _laboratorioId;
  int? _computadoraId;
  final String? _estadoId = 'EST_PENDIENTE';
  String? _inconvenienteSeleccionado;
  File? _imagen;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  List<Map<String, dynamic>> _laboratorios = [];
  List<Map<String, dynamic>> _computadoras = [];
  List<Map<String, dynamic>> _inconvenientes = [];

  final _service = IncidentesService();
  String? _token;

  static const Color primaryColor = Color(0xFF667eea);
  static const Color accentColor = Color(0xFF4A90E2);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _cargarTokenYDatos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarTokenYDatos() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) {
      _showSnackBar('Token no encontrado', isError: true);
      return;
    }
    _laboratorios = await _service.obtenerLaboratorios(_token!);
    _inconvenientes = await _service.obtenerInconvenientes(_token!);
    setState(() {});
  }

  Future<void> _cargarComputadoras() async {
    if (_laboratorioId != null && _token != null) {
      _computadoras = await _service.obtenerComputadorasPorLaboratorio(
        _laboratorioId!,
        _token!,
      );
      setState(() {});
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seleccionar imagen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.camera_alt,
                        label: 'Cámara',
                        onTap: () => _seleccionarImagen(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageOption(
                        icon: Icons.photo_library,
                        label: 'Galería',
                        onTap: () => _seleccionarImagen(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imagen = File(pickedFile.path));
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) setState(() => _horaSeleccionada = hora);
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      _showSnackBar('Por favor selecciona fecha y hora', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);
    final hora =
        '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:'
        '${_horaSeleccionada!.minute.toString().padLeft(2, '0')}:00';
    final otroInconveniente =
        _inconvenienteSeleccionado == 'otro'
            ? _otroInconvenienteController.text
            : null;
    final inconvenienteId =
        _inconvenienteSeleccionado != 'otro'
            ? int.tryParse(_inconvenienteSeleccionado!)
            : null;

    try {
      await _service.crearIncidente(
        descripcion: _descripcionController.text,
        fechaReporte: fecha,
        horaReporte: hora,
        laboratorioId: _laboratorioId!,
        computadoraId: _computadoraId,
        estadoId: _estadoId!,
        inconvenienteId: inconvenienteId,
        inconvenientePersonalizado: otroInconveniente,
        imagen: _imagen,
        token: _token!,
      );
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Incidente creado con éxito');
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      prefixIcon:
          icon != null ? Icon(icon, color: primaryColor, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Reportar Incidente',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _token == null ||
                        _laboratorios.isEmpty ||
                        _inconvenientes.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Tipo de inconveniente
                                _buildSection(
                                  title: 'Tipo de Inconveniente',
                                  icon: Icons.bug_report,
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _inconvenienteSeleccionado,
                                        isExpanded: true,
                                        items: [
                                          ..._inconvenientes.map(
                                            (inc) => DropdownMenuItem<String>(
                                              value: inc['id'].toString(),
                                              child: Text(inc['descripcion']),
                                            ),
                                          ),
                                          const DropdownMenuItem<String>(
                                            value: 'otro',
                                            child: Text('Otro (especificar)'),
                                          ),
                                        ],
                                        decoration: _buildInputDecoration(
                                          'Seleccionar tipo',
                                        ),
                                        onChanged: (value) => setState(
                                          () => _inconvenienteSeleccionado =
                                              value,
                                        ),
                                        validator: (value) =>
                                            value == null
                                                ? 'Campo requerido'
                                                : null,
                                      ),
                                      if (_inconvenienteSeleccionado == 'otro')
                                        ...[
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller:
                                                _otroInconvenienteController,
                                            decoration: _buildInputDecoration(
                                              'Especificar inconveniente',
                                              icon: Icons.edit,
                                            ),
                                            validator: (value) =>
                                                value!.isEmpty
                                                    ? 'Por favor especifica el inconveniente'
                                                    : null,
                                          ),
                                        ],
                                    ],
                                  ),
                                ),

                                // Descripción
                                _buildSection(
                                  title: 'Descripción del Problema',
                                  icon: Icons.description,
                                  child: TextFormField(
                                    controller: _descripcionController,
                                    maxLines: 4,
                                    decoration: _buildInputDecoration(
                                      'Describe detalladamente el problema',
                                    ),
                                    validator: (value) =>
                                        value!.isEmpty
                                            ? 'Campo requerido'
                                            : null,
                                  ),
                                ),

                                // Ubicación
                                _buildSection(
                                  title: 'Ubicación',
                                  icon: Icons.location_on,
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _laboratorioId,
                                        isExpanded: true,
                                        items: _laboratorios
                                            .map(
                                              (lab) => DropdownMenuItem<
                                                  String>(
                                                value: lab['nombre'],
                                                child: Text(
                                                  lab['nombre'] ?? 'Sin nombre',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        decoration: _buildInputDecoration(
                                          'Laboratorio',
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _laboratorioId = value;
                                            _computadoraId = null;
                                            _computadoras = [];
                                          });
                                          _cargarComputadoras();
                                        },
                                        validator: (value) =>
                                            value == null
                                                ? 'Campo requerido'
                                                : null,
                                      ),
                                      if (_computadoras.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<int>(
                                          value: _computadoraId,
                                          isExpanded: true,
                                          items: _computadoras
                                              .map(
                                                (comp) =>
                                                    DropdownMenuItem<int>(
                                                      value: comp['id'] as int,
                                                      child: Text(
                                                        comp['nombre'],
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                          decoration: _buildInputDecoration(
                                            'Computadora',
                                          ),
                                          onChanged: (value) => setState(
                                            () => _computadoraId = value,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Fecha y Hora
                                _buildSection(
                                  title: 'Fecha y Hora',
                                  icon: Icons.schedule,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: _seleccionarFecha,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                              color: Colors.grey[50],
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    color: primaryColor,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _fechaSeleccionada != null
                                                      ? DateFormat('dd/MM/yyyy')
                                                          .format(
                                                              _fechaSeleccionada!)
                                                      : '',
                                                  style: TextStyle(
                                                    color: _fechaSeleccionada !=
                                                            null
                                                        ? textPrimary
                                                        : textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: _seleccionarHora,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                              color: Colors.grey[50],
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.access_time,
                                                    color: primaryColor,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _horaSeleccionada != null
                                                      ? _horaSeleccionada!
                                                          .format(context)
                                                      : '',
                                                  style: TextStyle(
                                                    color: _horaSeleccionada !=
                                                            null
                                                        ? textPrimary
                                                        : textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Imagen
                                _buildSection(
                                  title: 'Evidencia Fotográfica',
                                  icon: Icons.camera_alt,
                                  child: Column(
                                    children: [
                                      if (_imagen == null)
                                        GestureDetector(
                                          onTap: _mostrarOpcionesImagen,
                                          child: Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: primaryColor
                                                  .withOpacity(0.05),
                                              border: Border.all(
                                                color: primaryColor
                                                    .withOpacity(0.3),
                                                style: BorderStyle.solid,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_a_photo,
                                                    size: 32,
                                                    color: primaryColor,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Agregar Imagen',
                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                _imagen!,
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () => setState(
                                                    () => _imagen = null),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[600],
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Botón de envío
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, accentColor],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : _enviarFormulario,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.send,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Enviar Reporte',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                     'Enviando reporte...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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