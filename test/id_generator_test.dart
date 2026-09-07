import 'package:dafter/core/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates unique non-empty IDs', () {
    final ids = List.generate(1000, (_) => IdGenerator.generate());

    expect(ids.every((id) => id.isNotEmpty), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });
}
