import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow100/data/models/wow_character.dart';
import 'package:wow100/features/auth/presentation/pages/character_selection_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('recognizes Herboriste as Herboristerie in profession overview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CharacterSelectionPage(
          showAds: false,
          characters: [
            WowCharacter(
              name: 'Sacrix',
              level: 11,
              realm: 'Khaz Modan',
              race: 'Humain',
              characterClass: 'Paladin',
              faction: 'Alliance',
              realmSlug: 'khaz-modan',
              professions: ['Herboriste'],
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('1/14'), findsOneWidget);
  });

  testWidgets('displays character professions in French', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CharacterSelectionPage(
          showAds: false,
          characters: [
            WowCharacter(
              name: 'Sacrix',
              level: 90,
              realm: 'Khaz Modan',
              race: 'Humain',
              characterClass: 'Paladin',
              faction: 'Alliance',
              realmSlug: 'khaz-modan',
              professions: ['Alchemy', 'Mining'],
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Humain'), findsOneWidget);
    expect(find.text('Alchimie • Minage'), findsOneWidget);
  });
}
