import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bilingual Persian (RTL) + English (LTR) controller aligned with Bettbox's language settings.
/// Defaults to English until [init] runs in `main()` (keeping widget tests deterministic),
/// and defaults to Persian (`fa`) on first launch on device unless the user selects English.
class MiliLocale {
  static const _prefKey = 'mili_lang';
  static final ValueNotifier<String> code = ValueNotifier<String>('en');

  static bool get isFa => code.value == 'fa';
  static TextDirection get direction =>
      isFa ? TextDirection.rtl : TextDirection.ltr;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'en' || saved == 'fa') {
        code.value = saved!;
      } else {
        code.value = 'fa';
      }
    } catch (_) {
      code.value = 'fa';
    }
  }

  static Future<void> toggle() => setLang(isFa ? 'en' : 'fa');

  static Future<void> setLang(String lang) async {
    if (lang != 'fa' && lang != 'en') return;
    code.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, lang);
    } catch (_) {}
  }

  /// Shorthand bilingual helper: returns Persian when `fa`, English when `en`.
  static String t(String fa, String en) => isFa ? fa : en;
}
