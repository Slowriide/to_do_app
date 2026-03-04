import 'package:flutter/material.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';

const String recoveredStartupMessage =
    'The app detected an incomplete backup import and recovered reminders.';
const String staleClearedStartupMessage =
    'A previous import attempt was detected. Reminder state was verified.';

class StartupRecoverySnackHost extends StatefulWidget {
  final ImportRecoveryResult result;
  final Widget child;

  const StartupRecoverySnackHost({
    super.key,
    required this.result,
    required this.child,
  });

  @override
  State<StartupRecoverySnackHost> createState() =>
      _StartupRecoverySnackHostState();
}

class _StartupRecoverySnackHostState extends State<StartupRecoverySnackHost> {
  bool _didShowStartupSnack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didShowStartupSnack) return;

      String? message;
      if (widget.result == ImportRecoveryResult.recovered) {
        message = recoveredStartupMessage;
      } else if (widget.result == ImportRecoveryResult.staleCleared) {
        message = staleClearedStartupMessage;
      }
      if (message == null) return;

      _didShowStartupSnack = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
