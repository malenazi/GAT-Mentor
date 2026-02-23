import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _capitalizeLevel(String level) {
    if (level.isEmpty) return level;
    return level[0].toUpperCase() + level.substring(1);
  }

  String _settingsPath() {
    final location = GoRouterState.of(context).matchedLocation;
    return location.startsWith('/admin')
        ? '/admin/profile/settings'
        : '/profile/settings';
  }

  Future<void> _confirmLogout() async {
    final s = S.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(s.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await SecureStorage.clearAll();
      ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: state.isLoading && state.user == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.user == null
              ? _buildError(state.error!)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildProfileHeader(state),
                      const SizedBox(height: 24),
                      _buildStatsRow(state),
                      const SizedBox(height: 20),
                      _buildStreakCard(state),
                      const SizedBox(height: 20),
                      _buildSettingsList(state),
                      const SizedBox(height: 28),
                      _buildLogoutButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(String message) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(profileProvider.notifier).loadProfile(),
              child: Text(s.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Header
  // ---------------------------------------------------------------------------

  Widget _buildProfileHeader(ProfileState state) {
    final user = state.user;
    final name = user?.fullName ?? 'User';
    final email = user?.email ?? '';

    return Column(
      children: [
        // Avatar circle with initials
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _getInitials(name),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Row
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(ProfileState state) {
    final s = S.of(context);
    final user = state.user;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: s.level,
            value: _capitalizeLevel(user?.level ?? 'N/A'),
            icon: Icons.star_outline,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: s.daysActive,
            value: '${state.daysActive}',
            icon: Icons.calendar_today_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: s.questions,
            value: '${state.totalQuestionsDone}',
            icon: Icons.quiz_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Streak Card
  // ---------------------------------------------------------------------------

  Widget _buildStreakCard(ProfileState state) {
    final s = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 28,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.currentStreak,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.streak} day${state.streak == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings List
  // ---------------------------------------------------------------------------

  Widget _buildSettingsList(ProfileState state) {
    final s = S.of(context);
    final user = state.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.studySettings,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.go(_settingsPath()),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(s.editAll),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary, size: 22),
            title: Text(s.language, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            subtitle: Text(s.isAr ? s.arabic : s.english, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
            onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.book_outlined,
                title: s.studyPlan,
                subtitle: '${s.focus}: ${_capitalizeLevel(user?.studyFocus ?? 'Both')}',
                onTap: () => context.go(_settingsPath()),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.event_outlined,
                title: s.examDate,
                subtitle: user?.examDate ?? s.notSet,
                onTap: () => context.go(_settingsPath()),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: s.dailyMinutes,
                subtitle: '${user?.dailyMinutes ?? 45} minutes',
                onTap: () => context.go(_settingsPath()),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.flag_outlined,
                title: s.targetScore,
                subtitle: '${user?.targetScore ?? 70}%',
                onTap: () => context.go(_settingsPath()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Logout Button
  // ---------------------------------------------------------------------------

  Widget _buildLogoutButton() {
    final s = S.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(s.logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Card Widget
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Tile Widget
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.primary,
      ),
      onTap: onTap,
    );
  }
}
