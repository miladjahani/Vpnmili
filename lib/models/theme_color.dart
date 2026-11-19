import 'dart:ui' show Color;

/// Calm, refined, high-contrast opaque palettes inspired by Bettbox Material You.
/// Zero harsh neon glare — engineered for comfortable long-term readability.
enum ThemeColor {
  neon(
    'Sage Mint',
    Color(0xFF34D399),
    accent: Color(0xFF6EE7B7),
    darkBg: Color(0xFF111418),
    darkSurface: Color(0xFF171B21),
    darkCard: Color(0xFF1E232B),
  ),
  ocean(
    'Bettbox Blue',
    Color(0xFF5B9BFF),
    accent: Color(0xFF93C5FD),
    darkBg: Color(0xFF111318),
    darkSurface: Color(0xFF171A22),
    darkCard: Color(0xFF1E222D),
  ),
  emerald(
    'Deep Teal',
    Color(0xFF2DD4BF),
    accent: Color(0xFF5EEAD4),
    darkBg: Color(0xFF101517),
    darkSurface: Color(0xFF161D20),
    darkCard: Color(0xFF1D262A),
  ),
  violet(
    'Soft Lavender',
    Color(0xFFA78BFA),
    accent: Color(0xFFC4B5FD),
    darkBg: Color(0xFF13121A),
    darkSurface: Color(0xFF1A1824),
    darkCard: Color(0xFF222030),
  ),
  amber(
    'Warm Amber',
    Color(0xFFFBBF24),
    accent: Color(0xFFFDE68A),
    darkBg: Color(0xFF161411),
    darkSurface: Color(0xFF1E1B17),
    darkCard: Color(0xFF27231D),
  ),
  rose(
    'Soft Coral',
    Color(0xFFFB7185),
    accent: Color(0xFFFDA4AF),
    darkBg: Color(0xFF171215),
    darkSurface: Color(0xFF20181C),
    darkCard: Color(0xFF291F24),
  ),
  slate(
    'Graphite Slate',
    Color(0xFF94A3B8),
    accent: Color(0xFFCBD5E1),
    darkBg: Color(0xFF111317),
    darkSurface: Color(0xFF181B20),
    darkCard: Color(0xFF20242B),
  );

  final String label;
  final Color seed;
  final Color accent;
  final Color darkBg;
  final Color darkSurface;
  final Color darkCard;

  const ThemeColor(
    this.label,
    this.seed, {
    required this.accent,
    required this.darkBg,
    required this.darkSurface,
    required this.darkCard,
  });

  /// Maps legacy theme names cleanly to the refined v2.0.0 palettes.
  static ThemeColor fromName(String? name) {
    if (name == null) return ThemeColor.ocean;
    for (final c in ThemeColor.values) {
      if (c.name == name) return c;
    }
    return switch (name) {
      'green' => ThemeColor.neon,
      'teal' => ThemeColor.emerald,
      'cyan' || 'blue' => ThemeColor.ocean,
      'purple' => ThemeColor.violet,
      'orange' => ThemeColor.amber,
      'pink' => ThemeColor.rose,
      'daylight' => ThemeColor.neon,
      _ => ThemeColor.ocean,
    };
  }
}
