import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../state/session.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Session>().restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Session session = context.watch<Session>();
    final String? error = session.restoreError;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 96),
              const SizedBox(height: 16),
              Text('Stock Risk Engine', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Live portfolio risk monitoring', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              if (error == null)
                const CircularProgressIndicator()
              else ...[
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Server: ${ApiConfig.baseUrl}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: session.restoring ? null : session.restore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                TextButton(
                  onPressed: session.forgetStoredLogin,
                  child: const Text('Log in again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
