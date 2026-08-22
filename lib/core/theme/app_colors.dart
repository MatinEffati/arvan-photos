import 'package:flutter/material.dart';

class AppColors {
  // --- Seed Color ---
  static const Color seed = Color(0xFF8C5610);

  // --- M3 ColorScheme Colors (Light) ---
  static const Color primary = Color(0xFF8C5610);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFF3E3); // Using user's #FFF3E3
  static const Color onPrimaryContainer = Color(0xFF2D1600);
  
  static const Color secondary = Color(0xFF715A41);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFCDDBF);
  static const Color onSecondaryContainer = Color(0xFF281806);
  
  static const Color tertiary = Color(0xFF556346);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFD8E9C4);
  static const Color onTertiaryContainer = Color(0xFF131F09);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF201B17);
  static const Color surfaceVariant = Color(0xFFF1E0D1);
  static const Color onSurfaceVariant = Color(0xFF50453A);
  
  static const Color outline = Color(0xFF827568);
  static const Color outlineVariant = Color(0xFFD4C4B5);

  // --- M3 ColorScheme Colors (Dark) ---
  static const Color primaryDark = Color(0xFFFFB95B);
  static const Color onPrimaryDark = Color(0xFF4B2800);
  static const Color primaryContainerDark = Color(0xFF6B3E00);
  static const Color onPrimaryContainerDark = Color(0xFFFFDDB5);
  
  static const Color secondaryDark = Color(0xFFDEBFA0);
  static const Color onSecondaryDark = Color(0xFF3F2D17);
  static const Color secondaryContainerDark = Color(0xFF58432B);
  static const Color onSecondaryContainerDark = Color(0xFFFCDDBF);
  
  static const Color tertiaryDark = Color(0xFFBDCDAA);
  static const Color onTertiaryDark = Color(0xFF28341B);
  static const Color tertiaryContainerDark = Color(0xFF3E4B30);
  static const Color onTertiaryContainerDark = Color(0xFFD8E9C4);
  
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);
  
  static const Color surfaceDark = Color(0xFF201B17);
  static const Color onSurfaceDark = Color(0xFFEDE0D8);
  static const Color surfaceVariantDark = Color(0xFF50453A);
  static const Color onSurfaceVariantDark = Color(0xFFD4C4B5);
  
  static const Color outlineDark = Color(0xFF9C8F81);
  static const Color outlineVariantDark = Color(0xFF50453A);

  // --- Google Photos Specific Aliases (User Requested) ---
  static const Color layoutSegmentBackground = Color(0xFFFDECDC);
  static const Color layoutSelectedCard = Color(0xFFFFF3E3);
  static const Color layoutIconMuted = Color(0xFF5B4D40);
  static const Color layoutLabelMuted = Color(0xFF6C5A4E);
  static const Color surfaceMain = Color(0xFFFFFFFF);

  // --- Legacy / Original Google Colors (Kept as requested) ---
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  
  // Backward compatibility aliases for existing code
  static const Color background = surfaceMain;
  static const Color onBackground = Color(0xFF202124);

  // --- Shared / Utility Colors ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFE8EAED);
  static const Color grey300 = Color(0xFFDADCE0);
  static const Color grey400 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9AA0A6);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF5F6368);
  static const Color grey750 = Color(0xFF444444);
  static const Color grey800 = Color(0xFF3C4043);
  static const Color grey900 = Color(0xFF202124);

  // --- Semantic UI Colors (Found in existing widgets) ---
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = grey700;
  static const Color textBrown = Color(0xFF5B4636);
  static const Color divider = grey400;
  static const Color dividerLight = Color(0xFFE6E6E6);
  
  static const Color accentBrown = Color(0xFF6B5022);
  static const Color alertRed = Color(0xFFC0574D);
  static const Color bannerBackground = Color(0xFFF4F0ED);
  static const Color shieldBlue = Color(0xFF194D79);
  
  static const Color chipBackground = grey800;
  static const Color inactiveTrack = Color(0xFFDCDCDC);
  static const Color helpIconBackground = Color(0xFFF1F3F4);
  
  // Specific Google Photos Peach theme variants (Aliased to user-requested names)
  static const Color peachLight = layoutSegmentBackground;
  static const Color peachDark = layoutIconMuted;
  static const Color peachSelected = layoutSelectedCard;

  // --- ColorSchemes ---
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: onPrimaryDark,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    secondary: secondaryDark,
    onSecondary: onSecondaryDark,
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: onSecondaryContainerDark,
    tertiary: tertiaryDark,
    onTertiary: onTertiaryDark,
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: onTertiaryContainerDark,
    error: errorDark,
    onError: onErrorDark,
    errorContainer: errorContainerDark,
    onErrorContainer: onErrorContainerDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceVariant: surfaceVariantDark,
    onSurfaceVariant: onSurfaceVariantDark,
    outline: outlineDark,
    outlineVariant: outlineVariantDark,
  );
}
