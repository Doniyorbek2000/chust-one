import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle displayLarge(Color color) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.25,
      );

  static TextStyle displayMedium(Color color) => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.3,
      );

  static TextStyle headlineLarge(Color color) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  static TextStyle headlineMedium(Color color) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.35,
      );

  static TextStyle titleLarge(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  static TextStyle titleMedium(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle labelLarge(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );
}
