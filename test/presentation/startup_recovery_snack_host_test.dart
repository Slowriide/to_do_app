import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/presentation/startup_recovery_snack_host.dart';

Widget _hostApp(ImportRecoveryResult result) {
  return MaterialApp(
    home: Scaffold(
      body: StartupRecoverySnackHost(
        result: result,
        child: const SizedBox.shrink(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'recovered shows one startup snackbar and does not show a second one',
    (tester) async {
      await tester.pumpWidget(_hostApp(ImportRecoveryResult.recovered));
      await tester.pump();

      expect(find.text(recoveredStartupMessage), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(find.text(recoveredStartupMessage), findsNothing);

      await tester.pump();
      expect(find.text(recoveredStartupMessage), findsNothing);
    },
  );

  testWidgets(
    'staleCleared shows one startup snackbar and does not show a second one',
    (tester) async {
      await tester.pumpWidget(_hostApp(ImportRecoveryResult.staleCleared));
      await tester.pump();

      expect(find.text(staleClearedStartupMessage), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(find.text(staleClearedStartupMessage), findsNothing);

      await tester.pump();
      expect(find.text(staleClearedStartupMessage), findsNothing);
    },
  );

  testWidgets('none does not show startup snackbar', (tester) async {
    await tester.pumpWidget(_hostApp(ImportRecoveryResult.none));
    await tester.pump();

    expect(find.text(recoveredStartupMessage), findsNothing);
    expect(find.text(staleClearedStartupMessage), findsNothing);
  });
}
