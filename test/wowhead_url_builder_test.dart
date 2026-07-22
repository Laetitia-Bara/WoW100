import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/core/services/wowhead_url_builder.dart';

void main() {
  test('localizes Wowhead achievement URLs to French', () {
    expect(
      WowheadUrlBuilder.localizeUrl('https://www.wowhead.com/achievement=6601'),
      'https://www.wowhead.com/fr/achievement=6601',
    );
  });

  test('keeps existing Wowhead URL suffix while replacing locale', () {
    expect(
      WowheadUrlBuilder.localizeUrl(
        'https://www.wowhead.com/de/achievement=6601?foo=bar',
      ),
      'https://www.wowhead.com/fr/achievement=6601?foo=bar',
    );
    expect(
      WowheadUrlBuilder.localizeUrl('https://fr.wowhead.com/achievement=6601'),
      'https://www.wowhead.com/fr/achievement=6601',
    );
  });
}
