import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/tokens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.eco, size: 80, color: BrandColors.primary),
              const SizedBox(height: Spacing.lg),
              const Text(
                'Welcome to Durvaeco',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: FontSizes.headline, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.xxl),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
