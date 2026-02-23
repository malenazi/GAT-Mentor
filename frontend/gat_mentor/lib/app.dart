import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/locale_provider.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class GatMentorApp extends ConsumerWidget {
  const GatMentorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'GAT Mentor',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _SessionExpiredListener(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Listens to 401 events from the API interceptor and shows a
/// "Session Expired" dialog, then logs the user out.
class _SessionExpiredListener extends ConsumerStatefulWidget {
  final Widget child;
  const _SessionExpiredListener({required this.child});

  @override
  ConsumerState<_SessionExpiredListener> createState() =>
      _SessionExpiredListenerState();
}

class _SessionExpiredListenerState
    extends ConsumerState<_SessionExpiredListener> {
  late final StreamSubscription<void> _sub;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _sub = sessionExpiredController.stream.listen((_) => _onExpired());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onExpired() {
    if (_dialogShown || !mounted) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_clock, size: 40, color: Colors.orange),
        title: const Text('Session Expired'),
        content: const Text(
            'Your session has expired. Please log in again.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogShown = false;
              SecureStorage.clearAll();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
