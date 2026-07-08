import 'package:flutter/material.dart';

import '../../data/models/wow_expansion.dart';

class ExpansionTagColors {
  const ExpansionTagColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

class ExpansionPalette {
  static const ExpansionTagColors fallback = ExpansionTagColors(
    background: Color(0xFF334155),
    foreground: Color(0xFFE2E8F0),
  );

  static ExpansionTagColors tagColors(WowExpansion expansion) {
    return switch (expansion) {
      WowExpansion.vanilla => const ExpansionTagColors(
        background: Color(0xFF423D2F),
        foreground: Color(0xFFF3E8C8),
      ),
      WowExpansion.tbc => const ExpansionTagColors(
        background: Color(0xFF14534A),
        foreground: Color(0xFF99F6E4),
      ),
      WowExpansion.wrath => const ExpansionTagColors(
        background: Color(0xFF164E63),
        foreground: Color(0xFFBAE6FD),
      ),
      WowExpansion.cataclysm => const ExpansionTagColors(
        background: Color(0xFF7F1D1D),
        foreground: Color(0xFFFCA5A5),
      ),
      WowExpansion.mop => const ExpansionTagColors(
        background: Color(0xFF365314),
        foreground: Color(0xFFD9F99D),
      ),
      WowExpansion.wod => const ExpansionTagColors(
        background: Color(0xFF7C2D12),
        foreground: Color(0xFFFED7AA),
      ),
      WowExpansion.legion => const ExpansionTagColors(
        background: Color(0xFF3F6212),
        foreground: Color(0xFFBEF264),
      ),
      WowExpansion.bfa => const ExpansionTagColors(
        background: Color(0xFF374151),
        foreground: Color(0xFFE5E7EB),
      ),
      WowExpansion.shadowlands => const ExpansionTagColors(
        background: Color(0xFF1E293B),
        foreground: Color(0xFFCBD5E1),
      ),
      WowExpansion.dragonflight => const ExpansionTagColors(
        background: Color(0xFF3730A3),
        foreground: Color(0xFFC7D2FE),
      ),
      WowExpansion.warWithin => const ExpansionTagColors(
        background: Color(0xFF7C2D12),
        foreground: Color(0xFFFDBA74),
      ),
      WowExpansion.midnight => const ExpansionTagColors(
        background: Color(0xFF312E81),
        foreground: Color(0xFFC4B5FD),
      ),
      _ => fallback,
    };
  }
}
