import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow100/core/services/solo_planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'stores and clears the loaded route name with today selection',
    () async {
      final service = SoloPlannerService();

      await service.setSelected('mount-1', true);
      await service.setSelected('mount-2', true);
      await service.setAllTodaySelected([
        'mount-2',
        'mount-1',
      ], loadedRouteName: 'Farm du soir');

      expect(await service.selectedTodayItemIds({'mount-1', 'mount-2'}), {
        'mount-1',
        'mount-2',
      });
      expect(await service.loadedRouteName(), 'Farm du soir');

      await service.setTodaySelected('mount-1', false);

      expect(await service.loadedRouteName(), isNull);
    },
  );

  test(
    'removing wishlist items also removes them from today selection',
    () async {
      final service = SoloPlannerService();

      await service.setSelected('mount-1', true);
      await service.setSelected('mount-2', true);
      await service.setAllTodaySelected([
        'mount-1',
        'mount-2',
      ], loadedRouteName: 'Farm du soir');

      await service.clearSelected(['mount-1']);

      expect(await service.selectedItemIds(), {'mount-2'});
      expect(await service.selectedTodayItemIds({'mount-2'}), {'mount-2'});
      expect(await service.loadedRouteName(), isNull);
    },
  );
}
