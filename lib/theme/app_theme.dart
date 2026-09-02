import 'package:flutter/material.dart';

/// Design tokens ported from the Broadsheet design system used for the
/// original SupMag prototype (see project/_ds/*/styles.css).
class AppColors {
  AppColors._();

  static const bg = Color(0xFFF3F2F2);
  static const surface = Color(0xFFEAE9E9);
  static const text = Color(0xFF201E1D);
  static const divider = Color(0x29201E1D);

  static const accent = Color(0xFF0088B0);
  static const accent100 = Color(0xFFE9F8FF);
  static const accent200 = Color(0xFFCBEEFF);
  static const accent300 = Color(0xFF99E0FF);
  static const accent500 = Color(0xFF38A6CF);
  static const accent600 = Color(0xFF1186AC);
  static const accent700 = Color(0xFF006786);
  static const accent800 = Color(0xFF004961);
  static const accent900 = Color(0xFF0A303E);

  static const accent2 = Color(0xFFD6006C);
  static const accent2_100 = Color(0xFFFFF1F4);
  static const accent2_200 = Color(0xFFFFDEE6);
  static const accent2_500 = Color(0xFFFF458E);
  static const accent2_700 = Color(0xFFAA0B56);
  static const accent2_800 = Color(0xFF790E3D);

  static const neutral100 = Color(0xFFF8F4F4);
  static const neutral200 = Color(0xFFEAE7E7);
  static const neutral300 = Color(0xFFD7D3D3);
  static const neutral400 = Color(0xFFBAB6B6);
  static const neutral500 = Color(0xFF9B9797);
  static const neutral600 = Color(0xFF7D7979);
  static const neutral700 = Color(0xFF605D5D);
  static const neutral800 = Color(0xFF444141);
  static const neutral900 = Color(0xFF2D2B2B);
}

class AppRadius {
  AppRadius._();
  static const sm = BorderRadius.all(Radius.circular(1));
  static const md = BorderRadius.all(Radius.circular(2));
  static const lg = BorderRadius.all(Radius.circular(4));
}

class AppShadows {
  AppShadows._();
  static const sm = [
    BoxShadow(color: Color(0x242D2B2B), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x382D2B2B), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

const _headingFamily = 'Source Serif 4';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme
        .apply(
          fontFamily: _headingFamily,
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: _headingFamily,
            fontWeight: FontWeight.w700,
            fontSize: 40,
            height: 1.05,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
          headlineMedium: const TextStyle(
            fontFamily: _headingFamily,
            fontWeight: FontWeight.w600,
            fontSize: 19,
            color: AppColors.text,
          ),
          titleLarge: const TextStyle(
            fontFamily: _headingFamily,
            fontWeight: FontWeight.w700,
            fontSize: 27,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.text),
          labelSmall: TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.bg,
        error: AppColors.accent2_700,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      cardColor: Colors.white,
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.neutral700,
        ),
        dataTextStyle: const TextStyle(fontSize: 13, color: AppColors.text),
        dividerThickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    );
  }
}

/// FCFA formatting helper mirroring the prototype's `fmt()` (thousands
/// separated with narrow spaces, no decimals).
String fmtFcfa(num n) {
  final rounded = n.round();
  final s = rounded.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return (rounded < 0 ? '-' : '') + buf.toString();
}
