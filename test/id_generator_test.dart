import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/utils/id_generator.dart';

void main() {
  test('IdGenerator.next returns unique, increasing ids', () {
    final ids = List<int>.generate(2000, (_) => IdGenerator.next());

    for (var i = 1; i < ids.length; i++) {
      expect(ids[i], greaterThan(ids[i - 1]));
    }

    expect(ids.toSet().length, ids.length);
  });
}
