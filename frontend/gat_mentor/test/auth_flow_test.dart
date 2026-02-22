import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gat_mentor/features/auth/presentation/screens/login_screen.dart';
import 'package:gat_mentor/features/auth/presentation/screens/register_screen.dart';
import 'package:gat_mentor/features/auth/presentation/providers/auth_provider.dart';
import 'package:gat_mentor/core/constants/app_colors.dart';

void main() {
  group('LoginScreen widget tests', () {
    testWidgets('renders login form correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check all UI elements are present
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue your GAT preparation'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });

    testWidgets('validates empty email', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign In without entering anything
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially the visibility icon should be "visibility_outlined" (password hidden)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap the visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Now it should show "visibility_off_outlined" (password visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('RegisterScreen widget tests', () {
    testWidgets('renders register form correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets); // title + button
    });

    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the button (not the title)
      final buttons = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(buttons);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });
  });
}
