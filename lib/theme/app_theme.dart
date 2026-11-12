import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1B5E20);      // Dark Farm Green
  static const Color primaryLight = Color(0xFF4CAF50); // Leaf Green
  static const Color accent = Color(0xFF2E7D32);       // Medium Green
  static const Color background = Color(0xFFF7FBF7);   // Farm White
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);

  static const Color expenseRed = Color(0xFFD32F2F);
  static const Color incomeGreen = Color(0xFF2E7D32);
  static const Color investmentBlue = Color(0xFF0288D1);
  static const Color warningOrange = Color(0xFFF57C00);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

class AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint circlePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, circlePaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.45, borderPaint);

    // Goat Silhouette
    final Paint whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path goatPath = Path();
    goatPath.moveTo(w * 0.42, h * 0.22);
    goatPath.quadraticBezierTo(w * 0.28, h * 0.18, w * 0.22, h * 0.32);
    goatPath.quadraticBezierTo(w * 0.30, h * 0.32, w * 0.38, h * 0.35);
    goatPath.lineTo(w * 0.24, h * 0.58);
    goatPath.lineTo(w * 0.30, h * 0.65);
    goatPath.lineTo(w * 0.38, h * 0.56);
    goatPath.lineTo(w * 0.36, h * 0.72);
    goatPath.lineTo(w * 0.44, h * 0.60);
    goatPath.lineTo(w * 0.48, h * 0.68);
    goatPath.lineTo(w * 0.48, h * 0.30);
    goatPath.close();
    canvas.drawPath(goatPath, whiteFill);

    // Fish Silhouette
    final Paint fishPaint = Paint()
      ..color = const Color(0xFFC8E6C9)
      ..style = PaintingStyle.fill;

    final Path fishPath = Path();
    fishPath.moveTo(w * 0.52, h * 0.48);
    fishPath.quadraticBezierTo(w * 0.70, h * 0.28, w * 0.88, h * 0.50);
    fishPath.lineTo(w * 0.94, h * 0.40);
    fishPath.lineTo(w * 0.90, h * 0.50);
    fishPath.lineTo(w * 0.94, h * 0.60);
    fishPath.lineTo(w * 0.88, h * 0.50);
    fishPath.quadraticBezierTo(w * 0.70, h * 0.72, w * 0.52, h * 0.48);
    fishPath.close();
    canvas.drawPath(fishPath, fishPaint);

    final Paint fishEye = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(w * 0.60, h * 0.48), w * 0.03, fishEye);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FarmLogoWidget extends StatelessWidget {
  final double size;
  const FarmLogoWidget({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppLogoPainter(),
      ),
    );
  }
}

