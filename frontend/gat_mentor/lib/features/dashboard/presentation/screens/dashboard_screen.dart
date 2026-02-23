import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Set<int> _expandedTopics = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  // ---- Helpers ------------------------------------------------------------

  Color _topicColor(String name) {
    switch (name.toLowerCase()) {
      case 'verbal':
        return AppColors.primary;
      case 'quantitative':
        return AppColors.secondary;
      case 'analytical':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _topicIcon(String name) {
    switch (name.toLowerCase()) {
      case 'verbal':
        return Icons.menu_book_outlined;
      case 'quantitative':
        return Icons.calculate_outlined;
      case 'analytical':
        return Icons.psychology_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(dashboardProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(dashboardProvider.notifier).loadDashboard(),
                  child: CustomScrollView(
                    slivers: [
                      // Gradient header
                      _buildGradientHeader(state),
                      // Main content
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 960),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryCards(state, isTablet),
                                  const SizedBox(height: 24),
                                  _buildTopicPerformanceSection(state),
                                  const SizedBox(height: 24),
                                  _buildFocusSection(state),
                                  const SizedBox(height: 24),
                                  _buildMasteryMapSection(state),
                                  const SizedBox(height: 24),
                                  _buildAccuracyTrendChart(state),
                                  const SizedBox(height: 20),
                                  _buildPracticeWeakButton(),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // =========================================================================
  // Gradient Header
  // =========================================================================

  Widget _buildGradientHeader(DashboardState state) {
    final s = S.of(context);
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.yourDashboard,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMotivationalMessage(state),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Streak badge
                    if (state.streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department,
                                    color: Colors.orangeAccent, size: 22)
                                .animate(
                                    onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(
                                    duration: 1500.ms,
                                    color: Colors.yellow.withOpacity(0.4)),
                            const SizedBox(width: 6),
                            Text(
                              '${state.streak}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.elasticOut),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMotivationalMessage(DashboardState state) {
    final s = S.of(context);
    if (state.totalQuestionsDone == 0) {
      return s.startFirstPractice;
    }
    if (state.overallAccuracy >= 80) {
      return s.amazingWork;
    }
    if (state.overallAccuracy >= 60) {
      return s.greatProgress;
    }
    if (state.streak >= 3) {
      return '${state.streak}${s.dontBreakStreak}';
    }
    return s.everyQuestionMatters;
  }

  // =========================================================================
  // Error
  // =========================================================================

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(dashboardProvider.notifier).loadDashboard(),
              child: Text(s.retry),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Summary Cards (6 cards, responsive grid)
  // =========================================================================

  Widget _buildSummaryCards(DashboardState state, bool isTablet) {
    final s = S.of(context);
    final studyHours = state.totalStudyMinutes ~/ 60;
    final studyMins = state.totalStudyMinutes % 60;
    final studyTimeStr = studyHours > 0 ? '${studyHours}h ${studyMins}m' : '${studyMins}m';

    final cards = [
      _SummaryCardData(
        icon: Icons.quiz_outlined,
        label: s.questions,
        value: '${state.totalQuestionsDone}',
        color: AppColors.primary,
      ),
      _SummaryCardData(
        icon: Icons.gps_fixed,
        label: s.accuracy,
        value: '${state.overallAccuracy.toStringAsFixed(1)}%',
        color: AppColors.success,
      ),
      _SummaryCardData(
        icon: Icons.timer_outlined,
        label: s.avgTime,
        value: '${state.avgTime.toStringAsFixed(1)}s',
        color: AppColors.warning,
      ),
      _SummaryCardData(
        icon: Icons.local_fire_department_outlined,
        label: s.streak,
        value: '${state.streak} ${s.days}',
        color: AppColors.error,
      ),
      _SummaryCardData(
        icon: Icons.school_outlined,
        label: s.studyTime,
        value: studyTimeStr,
        color: AppColors.secondary,
      ),
      _SummaryCardData(
        icon: Icons.emoji_events_outlined,
        label: s.bestStreak,
        value: '${state.longestStreak} ${s.days}',
        color: const Color(0xFFD97706),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.8 : 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _SummaryCard(data: cards[index])
            .animate()
            .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 60 * index))
            .slideY(
                begin: 0.08,
                end: 0,
                duration: 400.ms,
                delay: Duration(milliseconds: 60 * index),
                curve: Curves.easeOut);
      },
    );
  }

  // =========================================================================
  // Topic Performance Cards
  // =========================================================================

  Widget _buildTopicPerformanceSection(DashboardState state) {
    final s = S.of(context);
    final topics = state.topicPerformances;
    if (topics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.topicPerformance,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s.topicPerformanceDesc,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.03, end: 0, duration: 400.ms),
        const SizedBox(height: 14),
        ...List.generate(topics.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTopicCard(topics[index])
                .animate()
                .fadeIn(
                    duration: 450.ms,
                    delay: Duration(milliseconds: 100 + 150 * index))
                .slideX(
                    begin: 0.05,
                    end: 0,
                    duration: 450.ms,
                    delay: Duration(milliseconds: 100 + 150 * index),
                    curve: Curves.easeOut),
          );
        }),
      ],
    );
  }

  Widget _buildTopicCard(TopicPerformance topic) {
    final s = S.of(context);
    final color = _topicColor(topic.topicName);
    final icon = _topicIcon(topic.topicName);
    final masteryPercent = (topic.mastery * 100).clamp(0, 100).toDouble();
    final accuracyPercent = (topic.accuracy * 100).clamp(0, 100).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored left accent
          Container(
            width: 5,
            height: 170,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + name + circular indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          topic.topicName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 30,
                        lineWidth: 6,
                        percent: topic.mastery.clamp(0.0, 1.0),
                        center: Text(
                          '${masteryPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        progressColor: color,
                        backgroundColor: color.withOpacity(0.12),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stats chips row
                  Row(
                    children: [
                      _StatChip(
                        label: s.accuracy,
                        value: '${accuracyPercent.toStringAsFixed(0)}%',
                        color: accuracyPercent >= 60
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: s.questions,
                        value: '${topic.totalAttempts}',
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: s.mastered,
                        value: '${topic.masteredCount}/${topic.conceptCount}',
                        color: topic.masteredCount == topic.conceptCount
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Concept mini-bars
                  _buildConceptMiniBars(topic.concepts, color),
                  const SizedBox(height: 12),

                  // Practice button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.go('/practice'),
                      icon: Icon(Icons.play_arrow_rounded,
                          size: 18, color: color),
                      label: Text(
                        '${s.practice} ${topic.topicName}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        backgroundColor: color.withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptMiniBars(
      List<Map<String, dynamic>> concepts, Color topicColor) {
    if (concepts.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.concepts,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(concepts.length, (i) {
            final mastery =
                (concepts[i]['mastery'] ?? 0).toDouble().clamp(0.0, 1.0);
            final barColor = AppColors.getMasteryColor(mastery);
            final name = concepts[i]['name'] as String? ?? '';

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: i < concepts.length - 1 ? 4 : 0),
                child: Tooltip(
                  message:
                      '$name: ${(mastery * 100).toStringAsFixed(0)}%',
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: max(mastery, 0.03),
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name.length > 6
                            ? '${name.substring(0, 5)}..'
                            : name,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textHint,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // =========================================================================
  // Focus Recommendations
  // =========================================================================

  Widget _buildFocusSection(DashboardState state) {
    final s = S.of(context);
    final recommendations = state.focusRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.gps_fixed,
                  size: 20, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.whatToFocus,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s.focusDesc,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.03, end: 0, duration: 400.ms),
        const SizedBox(height: 14),
        if (recommendations.isEmpty)
          _buildCongratulationsCard()
        else
          ...List.generate(recommendations.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRecommendationCard(recommendations[index])
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 100 + 120 * index))
                  .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 400.ms,
                      delay: Duration(milliseconds: 100 + 120 * index),
                      curve: Curves.easeOut),
            );
          }),
      ],
    );
  }

  Widget _buildCongratulationsCard() {
    final s = S.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.08),
            AppColors.success.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              size: 32, color: AppColors.success),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.onFire,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.allConceptsGreat,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: 500.ms,
        curve: Curves.easeOut);
  }

  Widget _buildRecommendationCard(FocusRecommendation rec) {
    final s = S.of(context);
    final concept = rec.concept;
    final mastery = (concept['mastery'] ?? 0).toDouble().clamp(0.0, 1.0);
    final accuracy = (concept['accuracy'] ?? 0).toDouble().clamp(0.0, 1.0);
    final attempts = (concept['total_attempts'] ?? 0) as int;
    final conceptName =
        concept['concept_name'] as String? ?? concept['name'] as String? ?? '';
    final topicName = concept['topic_name'] as String? ?? '';
    final borderColor = rec.priority == 'high' ? AppColors.error : AppColors.warning;
    final masteryColor = AppColors.getMasteryColor(mastery);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority accent
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic badge + concept name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _topicColor(topicName).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          topicName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _topicColor(topicName),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conceptName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Mastery',
                          value:
                              '${(mastery * 100).toStringAsFixed(0)}%',
                          color: masteryColor),
                      const SizedBox(width: 16),
                      _MiniStat(
                          label: s.accuracy,
                          value:
                              '${(accuracy * 100).toStringAsFixed(0)}%',
                          color: accuracy >= 0.6
                              ? AppColors.success
                              : AppColors.error),
                      const SizedBox(width: 16),
                      _MiniStat(
                          label: 'Attempts',
                          value: '$attempts',
                          color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recommendation message
                  Text(
                    rec.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Mastery Map (Expandable with Bar Charts)
  // =========================================================================

  Widget _buildMasteryMapSection(DashboardState state) {
    final s = S.of(context);
    if (state.masteryMap.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.map_outlined,
                  size: 20, color: AppColors.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.masteryMap,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s.masteryMapDesc,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.03, end: 0, duration: 400.ms),
        const SizedBox(height: 14),
        ...List.generate(state.masteryMap.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildExpandableTopicCard(state.masteryMap[index], index)
                .animate()
                .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 80 * index))
                .slideY(
                    begin: 0.04,
                    end: 0,
                    duration: 400.ms,
                    delay: Duration(milliseconds: 80 * index),
                    curve: Curves.easeOut),
          );
        }),
      ],
    );
  }

  Widget _buildExpandableTopicCard(
      Map<String, dynamic> topic, int topicIndex) {
    final topicName = topic['topic_name'] as String? ?? 'Topic';
    final concepts = (topic['concepts'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final color = _topicColor(topicName);
    final icon = _topicIcon(topicName);
    final isExpanded = _expandedTopics.contains(topicIndex);

    // Compute average mastery for the header
    double avgMastery = 0;
    if (concepts.isNotEmpty) {
      avgMastery = concepts
              .map((c) => (c['mastery'] ?? 0).toDouble())
              .reduce((a, b) => a + b) /
          concepts.length;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (tappable)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTopics.remove(topicIndex);
                } else {
                  _expandedTopics.add(topicIndex);
                }
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topicName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    '${(avgMastery * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getMasteryColor(avgMastery),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        // Bar chart
                        if (concepts.isNotEmpty)
                          _buildConceptBarChart(concepts, color),
                        const SizedBox(height: 14),
                        // Concept detail rows
                        ...concepts.map((concept) =>
                            _buildConceptRow(concept)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptBarChart(
      List<Map<String, dynamic>> concepts, Color topicColor) {
    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final name = concepts[groupIndex]['name'] as String? ?? '';
                return BarTooltipItem(
                  '$name\n${rod.toY.toStringAsFixed(0)}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= concepts.length) {
                    return const SizedBox.shrink();
                  }
                  final name =
                      concepts[idx]['name'] as String? ?? '';
                  final short =
                      name.length > 5 ? '${name.substring(0, 4)}..' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textHint),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textHint.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(concepts.length, (i) {
            final mastery =
                (concepts[i]['mastery'] ?? 0).toDouble().clamp(0.0, 1.0);
            final barColor = AppColors.getMasteryColor(mastery);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (mastery * 100).clamp(0, 100),
                  color: barColor,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: barColor.withOpacity(0.08),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildConceptRow(Map<String, dynamic> concept) {
    final name = concept['name'] as String? ?? '';
    final mastery = (concept['mastery'] ?? 0).toDouble().clamp(0.0, 1.0);
    final accuracy = (concept['accuracy'] ?? 0).toDouble().clamp(0.0, 1.0);
    final attempts = (concept['total_attempts'] ?? 0) as int;
    final color = AppColors.getMasteryColor(mastery);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(mastery * 100).toStringAsFixed(0)}%  |  '
                'Acc: ${(accuracy * 100).toStringAsFixed(0)}%  |  '
                '$attempts Q',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 7,
            percent: mastery,
            backgroundColor: color.withOpacity(0.12),
            progressColor: color,
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 600,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Accuracy Trend Chart
  // =========================================================================

  Widget _buildAccuracyTrendChart(DashboardState state) {
    final s = S.of(context);
    if (state.trends.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (var i = 0; i < state.trends.length; i++) {
      final accuracy = (state.trends[i]['accuracy'] ?? 0).toDouble();
      // Backend returns 0-1 range, convert to percentage
      final pct = accuracy <= 1.0 ? accuracy * 100 : accuracy;
      spots.add(FlSpot(i.toDouble(), pct.clamp(0, 100)));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.accuracyTrend,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        s.accuracyTrendDesc,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.textHint.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= state.trends.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr =
                              state.trends[idx]['date'] as String? ?? '';
                          final shortDate = dateStr.length >= 5
                              ? dateStr.substring(dateStr.length - 5)
                              : dateStr;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              shortDate,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: AppColors.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(
            begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  // =========================================================================
  // Practice Weak Topics Button
  // =========================================================================

  Widget _buildPracticeWeakButton() {
    final s = S.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/practice'),
        icon: const Icon(Icons.fitness_center),
        label: Text(
          s.practiceWeakTopics,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ===========================================================================
// Private Widgets
// ===========================================================================

class _SummaryCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, size: 18, color: data.color),
            ),
            const Spacer(),
            Text(
              data.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: data.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
