import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
        );
    // Navigation is handled automatically by GoRouter redirect.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final s = S.of(context);

    // Listen for errors to show SnackBar feedback.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Language Toggle ----------------------------------------
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () =>
                          ref.read(localeProvider.notifier).toggleLocale(),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(s.switchLanguage),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),

                  // ---- Branding -------------------------------------------
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.createAccount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // ---- Full Name Field ------------------------------------
                  TextFormField(
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: s.fullName,
                      hintText: s.fullNameHint,
                      prefixIcon: const Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return s.pleaseEnterName;
                      }
                      if (value.trim().length < 2) {
                        return s.nameMinLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---- Email Field ----------------------------------------
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: s.email,
                      hintText: s.emailHint,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return s.pleaseEnterEmail;
                      }
                      if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$')
                          .hasMatch(value.trim())) {
                        return s.pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---- Password Field -------------------------------------
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: s.password,
                      hintText: s.passwordHint,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.pleaseEnterAPassword;
                      }
                      if (value.length < 6) {
                        return s.passwordMinLength;
                      }
                      return null;
                    },
                  ),
                  // ---- Password Strength & Requirements ----------------------
                  if (_passwordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _PasswordStrengthBar(
                          password: _passwordController.text),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      s.passwordRequirements,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---- Register Button ------------------------------------
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          authState.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.createAccount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- Login Link -----------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.alreadyHaveAccount,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          s.login,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// Password Strength Bar
// ==========================================================================

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final strength = _calculateStrength(password);
    final label = _strengthLabel(strength, s);
    final color = _strengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < strength ? color : const Color(0xFFE2E8F0),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  int _calculateStrength(String pw) {
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 6) score++;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(pw) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) {
      score++;
    }
    return score;
  }

  String _strengthLabel(int strength, S s) {
    switch (strength) {
      case 0:
        return s.tooShort;
      case 1:
        return s.weak;
      case 2:
        return s.fair;
      case 3:
        return s.good;
      case 4:
        return s.strong;
      default:
        return '';
    }
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }
}
