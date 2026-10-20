import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// The UI language. Persian is the only shipped UI locale in the MVP;
/// English strings exist so localization can be extended later.
const appLocale = Locale('fa');

class AiWortBoxApp extends StatefulWidget {
  const AiWortBoxApp({
    super.key,
    this.initialLocation = AppRoutes.today,
    this.locale = appLocale,
  });

  final String initialLocation;

  /// The UI locale; tests also run the English (LTR) strings.
  final Locale locale;

  @override
  State<AiWortBoxApp> createState() => _AiWortBoxAppState();
}

class _AiWortBoxAppState extends State<AiWortBoxApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.productName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: widget.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
