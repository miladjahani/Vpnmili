import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/mili_home_shell.dart';
import 'ui/mili_i18n.dart';
import 'ui/setup_wizard.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MiliLocale.init();
  final state = AppState();
  await state.init();
  runApp(MiliApp(state: state));
}

class MiliApp extends StatelessWidget {
  final AppState state;
  const MiliApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          state.themeColor,
          state.themeMode,
          MiliLocale.code,
        ]),
        builder: (context, _) => MaterialApp(
          title: 'MiliConfig',
          debugShowCheckedModeBanner: false,
          builder: (context, child) => Directionality(
            textDirection: MiliLocale.direction,
            child: SafeArea(
              top: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          theme: buildTheme(Brightness.light, state.themeColor.value),
          darkTheme: buildTheme(Brightness.dark, state.themeColor.value),
          themeMode: state.themeMode.value,
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Opens SetupWizard on first launch (with Skip option), then the Bettbox MiliHomeShell.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final needsSetup = AppScope.of(context).needsSetup;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: needsSetup
          ? const SetupWizard(key: ValueKey('setup'))
          : const MiliHomeShell(key: ValueKey('home')),
    );
  }
}
