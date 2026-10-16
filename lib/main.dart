import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Basic error reporting. Errors are logged locally only; vocabulary content
  // is never sent anywhere.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  // The bundled fonts' licenses appear on the system license page.
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Vazirmatn', 'assets/fonts/OFL-Vazirmatn.txt'),
      ('Literata', 'assets/fonts/OFL-Literata.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(file));
    }
  });

  runApp(const ProviderScope(child: AiWortBoxApp()));
}
