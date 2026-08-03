import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow100/core/services/auth_remember_me_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and clears remembered auth email', () async {
    final service = AuthRememberMeService();

    expect((await service.load()).rememberMe, isFalse);
    expect((await service.load()).email, isNull);

    await service.saveEmail(' user@example.com ');
    final rememberedInfo = await service.load();

    expect(rememberedInfo.rememberMe, isTrue);
    expect(rememberedInfo.email, 'user@example.com');

    await service.clear();
    final clearedInfo = await service.load();

    expect(clearedInfo.rememberMe, isFalse);
    expect(clearedInfo.email, isNull);
  });
}
