import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Generates collision-resistant local IDs without relying on wall-clock time.
///
/// This is intentionally dependency-free because IDs are used by the offline
/// database and may be generated multiple times in the same microsecond.
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random.secure();

  static String generate() {
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
