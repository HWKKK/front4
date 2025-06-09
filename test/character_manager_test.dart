import 'package:flutter_test/flutter_test.dart';
import 'package:nompangs/services/character_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CharacterManager is a singleton', () {
    final first = CharacterManager.instance;
    final second = CharacterManager.instance;
    expect(identical(first, second), isTrue);
  });
}
