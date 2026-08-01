import 'package:flutter/material.dart';

/// Accent violet-albăstrui, ales să se potrivească cu degradeul din
/// iconița aplicației (albastru→violet) — vezi `assets/icon/`.
const Color kAccentColor = Color(0xFF5B5FEF);

/// Roșu folosit exclusiv pentru butoanele de acțiune care merită să „sară
/// în ochi" (scanare talon, sugerează intervale, verifică pe site-ul
/// oficial, scanează date din PDF) — cerut explicit de utilizator, ca
/// alternativă vizuală la stilul violet implicit al butoanelor. Nu folosi
/// pentru alte butoane fără cerere explicită, ca să nu devalorizeze
/// semnalul vizual.
const Color kAttentionColor = Color(0xFFE13B3B);

/// Culori distincte per tab din barele de navigare de jos
/// (`AppBottomNavBar`) — cerut explicit de utilizator ("fă butoanele de
/// jos... colorate"), în loc de o singură culoare neutră (`onSurface`)
/// pentru toate taburile. Tabul Acasă folosește `kAccentColor` (identitatea
/// vizuală a aplicației); restul au culori tematice legate de conținutul
/// tabului (mașini=portocaliu, casă=verde, costuri=turcoaz, setări=gri
/// albăstrui neutru — intenționat mai discret, nu e un tab de conținut).
const Color kNavGarageColor = Color(0xFFE8871E);
const Color kNavHouseColor = Color(0xFF2E9E5B);
const Color kNavCostsColor = Color(0xFF0EA5A5);
const Color kNavSettingsColor = Color(0xFF64748B);

/// Aceleași culori tematice, refolosite pentru taburile din
/// `vehicle_detail_screen.dart` (Info/Service/Documente/Componente) —
/// Info reia `kAccentColor` la fel ca tabul Acasă, Service/Documente/
/// Componente au propriile culori, distincte de cele de mai sus (nu se
/// suprapun pe același ecran, deci nu contează consistența 1:1 cu taburile
/// principale).
const Color kNavServiceColor = Color(0xFFE8871E);
const Color kNavDocumentsColor = Color(0xFF0EA5A5);
const Color kNavComponentsColor = Color(0xFF2E9E5B);

const String _fontFamily = 'Plus Jakarta Sans';

/// Elevație care variază cu starea butonului — cerut explicit de utilizator
/// ("să arate ca și cum le apas, atunci când le apas"): butonul "plutește"
/// implicit (elevație mai mare) și "se lasă în jos" vizual când e apăsat
/// (elevație aproape 0) — efectul de adâncime 3D clasic Material, dincolo
/// de simplul feedback de culoare/ripple pe care Flutter îl dă oricum.
WidgetStateProperty<double> get _pressedElevation => WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return 0;
      if (states.contains(WidgetState.pressed)) return 1;
      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 6;
      return 4;
    });

const Color _lightBackground = Color(0xFFFAFAFC);
const Color _darkBackground = Color(0xFF17171C);

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  var colorScheme = ColorScheme.fromSeed(
    seedColor: kAccentColor,
    brightness: brightness,
  );
  colorScheme = colorScheme.copyWith(
    surface: isDark ? _darkBackground : _lightBackground,
  );

  final textTheme = _buildTextTheme(colorScheme);
  final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.6);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    fontFamily: _fontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      // Aspect "3D" cerut explicit de utilizator (umbre elevate, stil
      // Material clasic) — cardurile plutesc deasupra fundalului în loc să
      // fie plate cu doar un contur subțire. Fără `side`/border aici:
      // umbra singură dă adâncimea, un contur suplimentar peste umbră arăta
      // aglomerat.
      elevation: isDark ? 6 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.18),
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        elevation: _pressedElevation,
        shadowColor: WidgetStatePropertyAll(
          isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.25),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: _pressedElevation,
        shadowColor: WidgetStatePropertyAll(
          isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.25),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        textStyle: textTheme.labelLarge,
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // Elevația veche (fixă, 1) abia se vedea și nu avea nicio stare
      // separată de apăsare — butonul "+ mașină" arăta plat și neschimbat
      // la apăsare. `highlightElevation` mai mică decât `elevation` dă
      // exact efectul de "se lasă în jos" cerut.
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 2,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      side: BorderSide.none,
      labelStyle: textTheme.labelMedium,
      backgroundColor: colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      space: 1,
      thickness: 1,
    ),
  );
}

TextTheme _buildTextTheme(ColorScheme colorScheme) {
  final muted = colorScheme.onSurfaceVariant;
  return TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: colorScheme.onSurface),
    displayMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: colorScheme.onSurface),
    displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: colorScheme.onSurface),
    headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: colorScheme.onSurface),
    headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: colorScheme.onSurface),
    headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: colorScheme.onSurface),
    titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.2, color: colorScheme.onSurface),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: colorScheme.onSurface),
    titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface),
    bodyLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: colorScheme.onSurface),
    bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: colorScheme.onSurface),
    bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: muted),
    labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
    labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colorScheme.onSurface),
    labelSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: muted),
  );
}
