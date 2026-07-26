import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow100/core/widgets/scrolling_notice_banner.dart';

void main() {
  testWidgets('scrolling notice banner fits mobile width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(416, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 416,
            child: ScrollingNoticeBanner(
              message:
                  'ATTENTION : verification manuelle de localisation des items toujours en cours',
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
