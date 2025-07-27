import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/objetosPerdidos_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ReporteObjetoPage extends StatefulWidget {
  final String? token;
  const ReporteObjetoPage({super.key, this.token});

  @override
  State<ReporteObjetoPage> createState() => _ReporteObjetoPageState();
}

class _ReporteObjetoPageState extends State<ReporteObjetoPage>
    with TickerProviderStateMixin {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  final ObjetosPerdidosService _objetosService = ObjetosPerdidosService();

  String? _tokenFinal;
  bool _isLoading = false;

  // Laboratorios
  List<Map<String, dynamic>> _laboratorios = [];
  String? _laboratorioSeleccionado;

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color primaryColor = Color.fromARGB(255, 0, 33, 182);
  static const Color accentColor = Color.fromARGB(255, 11, 0, 172);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  // ignore: unused_field
  static const Color textSecondary = Color(0xFF64748B);

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
    _obtenerToken();
    _cargarLaboratorios();
    _animationController.forward();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _obtenerToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      setState(() {
        _tokenFinal = widget.token;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final tokenPrefs = prefs.getString('token');
      setState(() {
        _tokenFinal = tokenPrefs;
      });
    }
  }

  Future<void> _cargarLaboratorios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? widget.token;
    if (token != null && token.isNotEmpty) {
      try {
        final labs = await _objetosService.obtenerLaboratorios(token);
        setState(() {
          _laboratorios = List<Map<String, dynamic>>.from(labs);
        });
      } catch (e) {
        _mostrarError('Error al cargar laboratorios: $e');
      }
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (selectedImage != null) {
        setState(() {
          _imagen = File(selectedImage.path);
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
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

  bool _validarFormulario() {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Por favor, ingresa el nombre del objeto que encontraste');
      return false;
    }
    if (_descripcionController.text.trim().isEmpty) {
      _mostrarError('Por favor, describe el objeto que encontraste');
      return false;
    }
    if (_ubicacionController.text.trim().isEmpty) {
      _mostrarError('Por favor, indica dónde encontraste el objeto');
      return false;
    }
    if (_laboratorioSeleccionado == null || _laboratorioSeleccionado!.isEmpty) {
      _mostrarError('Por favor, selecciona un laboratorio');
      return false;
    }
    return true;
  }

  Future<void> _enviarReporte() async {
    if (!_validarFormulario()) return;

    if (_tokenFinal == null || _tokenFinal!.isEmpty) {
      _mostrarError('Token de autenticación no válido');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _objetosService.crearObjetoPerdido(
        nombreObjeto: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        lugar: _ubicacionController.text.trim(),
        laboratorio: _laboratorioSeleccionado!, // Este es el ID como String
        estadoId: 'EST_PENDIENTE',
        imagen: _imagen,
        token: _tokenFinal!,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: '¡Reporte enviado!',
          desc: 'Debes entregar el objeto a la jefatura de laboratorios para completar el proceso.',
          btnOkText: 'Entendido',
          btnOkOnPress: () {
            _limpiarFormulario();
            Navigator.of(context).pop();
          },
          btnOkColor: primaryColor,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          customHeader: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 50,
            ),
          ),
          headerAnimationLoop: false,
          dialogBackgroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          descTextStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ).show();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al enviar el reporte: $e');
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _ubicacionController.clear();
    setState(() {
      _imagen = null;
      _laboratorioSeleccionado = null;
    });
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: Colors.black),
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
                    'Reportar Objeto Perdido',
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSection(
                          title: 'Nombre del Objeto',
                          icon: Icons.label,
                          child: TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration('¿Qué objeto encontraste?'),
                            enabled: !_isLoading,
                          ),
                        ),
                        _buildSection(
                          title: 'Descripción',
                          icon: Icons.description,
                          child: TextFormField(
                            controller: _descripcionController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration('Describe el objeto que encontraste (color, tamaño, marca, etc.)'),
                            enabled: !_isLoading,
                          ),
                        ),
                        _buildSection(
                          title: '¿Dónde lo encontraste?',
                          icon: Icons.location_on,
                          child: TextFormField(
                            controller: _ubicacionController,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration('Ubicación específica donde encontraste el objeto'),
                            enabled: !_isLoading,
                          ),
                        ),
                        _buildSection(
                          title: 'Laboratorio',
                          icon: Icons.science,
                          child: DropdownButtonFormField<String>(
                            value: _laboratorioSeleccionado,
                            items: _laboratorios
                                .map((lab) => DropdownMenuItem<String>(
                                      value: lab['id'].toString(),
                                      child: Text(lab['nombre'] ?? 'Sin nombre', style: const TextStyle(color: Colors.black)),
                                    ))
                                .toList(),
                            onChanged: _isLoading ? null : (value) {
                              setState(() {
                                _laboratorioSeleccionado = value;
                              });
                            },
                            decoration: _inputDecoration('Selecciona un laboratorio'),
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                          ),
                        ),
                        _buildSection(
                          title: 'Foto del Objeto ',
                          icon: Icons.camera_alt,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _mostrarOpcionesFoto,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: _isLoading ? Colors.grey.shade100 : Colors.white,
                              ),
                              child: _imagen == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: _isLoading ? Colors.grey.shade400 : Colors.grey.shade500,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para agregar foto del objeto encontrado (opcional)',
                                          style: TextStyle(
                                            color: _isLoading ? Colors.grey.shade400 : Colors.grey.shade500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            _imagen!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        if (!_isLoading)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _imagen = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                            onPressed: _isLoading ? null : _enviarReporte,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
          if (_isLoading)
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