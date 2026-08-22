import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place to resolve the API base URL per platform.
///
/// - Android emulator cannot reach the host machine via `localhost`; it must
///   use the special alias `10.0.2.2`.
/// - iOS simulator and desktop/web builds can use `localhost` directly.
/// - A physical device needs your machine's LAN IP (e.g. 192.168.x.x) —
///   override with `--dart-define=API_BASE_URL=http://<your-ip>:3000`.
class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
