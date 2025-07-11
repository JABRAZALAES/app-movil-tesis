import 'package:flutter/material.dart';

class AppColors {
  // Paleta principal de colores
  static const Color primary = Color(0xFF667eea);
  static const Color primaryDark = Color(0xFF4B73E8);
  static const Color primaryLight = Color(0xFF8B9EF8);
  
  // Colores de fondo
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F7FA);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF2196F3);
  
  // Colores de borde y sombra
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0xFF667eea);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Colores para estados de incidentes
  static Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return warning;
      case 'EN PROCESO':
        return info;
      case 'RESUELTO':
        return success;
      case 'CANCELADO':
        return error;
      default:
        return textSecondary;
    }
  }
  
  // Colores para estados de objetos
  static Color getObjetoEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PERDIDO':
        return warning;
      case 'ENCONTRADO':
        return success;
      case 'ENTREGADO':
        return info;
      case 'TODOS':
        return primary;
      default:
        return textSecondary;
    }
  }
} 