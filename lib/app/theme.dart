import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/design/tokens.dart';
import '../core/design/typography.dart';

/// Light and dark themes built from the design tokens in `core/design`.
///
/// Light: warm cream surfaces, navy structure and type, the yellow box as
/// the brand accent. Dark: deep navy surfaces, cream type, the yellow box as
/// the primary action color. Mint is reserved for assistance and success.
abstract final class AppTheme {
  static ThemeData light() => _build(_lightScheme, AppColors.light);

  static ThemeData dark() => _build(_darkScheme, AppColors.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.navy800,
    onPrimary: Color(0xFFFFF8E8),
    primaryContainer: AppPalette.navy100,
    onPrimaryContainer: AppPalette.navy900,
    secondary: AppPalette.boxYellow,
    onSecondary: AppPalette.navy900,
    secondaryContainer: AppPalette.highlighter,
    onSecondaryContainer: AppPalette.navy900,
    tertiary: AppPalette.mintInk,
    onTertiary: Colors.white,
    tertiaryContainer: AppPalette.mintTint,
    onTertiaryContainer: AppPalette.mintDeep,
    error: AppPalette.red,
    onError: Colors.white,
    errorContainer: AppPalette.redTint,
    onErrorContainer: AppPalette.redDeep,
    surface: AppPalette.cream,
    onSurface: AppPalette.navy900,
    onSurfaceVariant: AppPalette.slate,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppPalette.paper,
    surfaceContainer: Color(0xFFF8F2E6),
    surfaceContainerHigh: AppPalette.creamDeep,
    surfaceContainerHighest: Color(0xFFEFE7D7),
    outline: AppPalette.creamOutline,
    outlineVariant: AppPalette.creamLine,
    shadow: Color(0x2915213B),
    scrim: Color(0x9915213B),
    inverseSurface: AppPalette.navy900,
    onInverseSurface: AppPalette.cream,
    inversePrimary: AppPalette.boxYellow,
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.boxYellowBright,
    onPrimary: AppPalette.navy900,
    primaryContainer: AppPalette.navy700,
    onPrimaryContainer: AppPalette.navy50,
    secondary: AppPalette.boxYellowBright,
    onSecondary: AppPalette.navy900,
    secondaryContainer: AppPalette.yellowDeep,
    onSecondaryContainer: AppPalette.yellowPale,
    tertiary: AppPalette.mintBright,
    onTertiary: Color(0xFF0A2E26),
    tertiaryContainer: AppPalette.mintNight,
    onTertiaryContainer: AppPalette.mintPale,
    error: AppPalette.redSoft,
    onError: AppPalette.redNight,
    errorContainer: AppPalette.redNight,
    onErrorContainer: AppPalette.redPale,
    surface: AppPalette.navy950,
    onSurface: Color(0xFFF4EFE3),
    onSurfaceVariant: AppPalette.slateLight,
    surfaceContainerLowest: Color(0xFF0A101D),
    surfaceContainerLow: Color(0xFF141D31),
    surfaceContainer: Color(0xFF172036),
    surfaceContainerHigh: Color(0xFF1B263F),
    surfaceContainerHighest: Color(0xFF212D49),
    outline: AppPalette.slateOutline,
    outlineVariant: AppPalette.navy600,
    shadow: Color(0x66000000),
    scrim: Color(0xB3000000),
    inverseSurface: Color(0xFFF4EFE3),
    onInverseSurface: AppPalette.navy900,
    inversePrimary: AppPalette.navy800,
    surfaceTint: Colors.transparent,
  );

  static ThemeData _build(ColorScheme scheme, AppColors colors) {
    final text = AppTypography.textTheme(
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    const buttonSize = Size(64, AppTouch.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpace.xl,
      vertical: AppSpace.md,
    );
    final cardSide = BorderSide(color: scheme.outlineVariant);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [colors],
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.uiFallback,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppBorder.hairline,
        space: AppBorder.hairline,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.flat,
        centerTitle: false,
        titleSpacing: AppSpace.gutter,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.box,
        indicatorShape: const StadiumBorder(),
        elevation: AppElevation.flat,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIconSize.md,
            color: states.contains(WidgetState.selected)
                ? colors.onBox
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: cardSide,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppTouch.minTarget, AppTouch.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          shape: buttonShape,
          foregroundColor: scheme.brightness == Brightness.light
              ? scheme.primary
              : scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppTouch.minTarget, AppTouch.minTarget),
          foregroundColor: scheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.box,
        foregroundColor: colors.onBox,
        elevation: AppElevation.floating,
        focusElevation: AppElevation.floating,
        hoverElevation: AppElevation.overlay,
        highlightElevation: AppElevation.overlay,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        extendedTextStyle: text.labelLarge!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(AppTouch.minTarget, AppTouch.minTarget),
          selectedBackgroundColor: colors.box,
          selectedForegroundColor: colors.onBox,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md + AppSpace.xxs,
        ),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        disabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, AppBorder.focus),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, AppBorder.focus),
        labelStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall,
        helperMaxLines: 3,
        errorStyle: text.bodySmall!.copyWith(color: scheme.error),
        errorMaxLines: 3,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(AppElevation.flat),
        backgroundColor: WidgetStatePropertyAll(colors.inputFill),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
        constraints: const BoxConstraints(minHeight: AppTouch.buttonHeight),
        textStyle: WidgetStatePropertyAll(text.bodyLarge),
        hintStyle: WidgetStatePropertyAll(
          text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpace.md,
        minTileHeight: AppTouch.minTarget,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: scheme.onSurface,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.xl,
        ),
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.overlay,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        // Fixed, so a confirmation never floats over the form's buttons.
        behavior: SnackBarBehavior.fixed,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: colors.box,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.brightness == Brightness.light
            ? scheme.primary
            : colors.box,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: colors.box.withValues(alpha: 0.45),
        selectionHandleColor: scheme.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
