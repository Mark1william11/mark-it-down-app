// lib/presentation/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/todo.dart';
import '../notifiers/todo_stats_provider.dart';
import '../notifiers/todo_list_notifier.dart';
import '../theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // We watch the async value to handle loading/error states gracefully
    final todoListAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Productivity Stats')),
      body: todoListAsync.when(
        // Use a shimmer effect while data is loading for a polished feel
        loading: () => Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          child: _buildBody(context, ref, null, isLoading: true),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (_) => _buildBody(context, ref, ref.watch(todoStatsProvider)),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TodoStats? stats, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final statCards = [
      _StatCard(label: 'Total Todos', value: stats?.total.toString() ?? '...'),
      _StatCard(label: 'Active', value: stats?.active.toString() ?? '...'),
      _StatCard(
        label: 'Completed',
        value: stats?.completed.toString() ?? '...',
      ),
    ];

    if (stats?.total == 0 && !isLoading) {
      return const Center(
        child: Text('No stats to show yet. Complete some tasks!'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            [
                  _buildCompletionCard(context, stats),
                  const SizedBox(height: 24),
                  Text(
                    'Completed by Priority',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPriorityPieChart(context, stats),
                  const SizedBox(height: 24),
                  Text('Last 7 Days', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildWeeklyBarChart(context, stats),
                  const SizedBox(height: 24),
                  ...statCards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: card,
                        ),
                      )
                      .toList(),
                ]
                .animate(interval: 100.ms)
                .fade(duration: 400.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context, TodoStats? stats) {
    final theme = Theme.of(context);
    final percent = stats?.percentCompleted ?? 0;
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'of all tasks completed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Animate(
              effects: [
                ScaleEffect(
                  delay: 300.ms,
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
              ],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPieChart(BuildContext context, TodoStats? stats) {
    if (stats?.completed == 0)
      return const Center(child: Text('Complete a task to see this chart.'));

    final sections = [
      PieChartSectionData(
        value: stats?.completedByPriority[Priority.high]?.toDouble() ?? 0,
        color: AppTheme.highPriorityColor,
        title: '${stats?.completedByPriority[Priority.high] ?? 0}',
        radius: 50,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats?.completedByPriority[Priority.medium]?.toDouble() ?? 0,
        color: AppTheme.mediumPriorityColor,
        title: '${stats?.completedByPriority[Priority.medium] ?? 0}',
        radius: 50,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats?.completedByPriority[Priority.low]?.toDouble() ?? 0,
        color: AppTheme.lowPriorityColor,
        title: '${stats?.completedByPriority[Priority.low] ?? 0}',
        radius: 50,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections
                    .where((s) => s.value > 0)
                    .toList(), // Only show sections with data
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
              // THE FIX: Animation properties are now top-level parameters.
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
          const SizedBox(width: 24),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Indicator(color: AppTheme.highPriorityColor, text: 'High'),
              _Indicator(color: AppTheme.mediumPriorityColor, text: 'Medium'),
              _Indicator(color: AppTheme.lowPriorityColor, text: 'Low'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context, TodoStats? stats) {
    final theme = Theme.of(context);
    if (stats == null) return const SizedBox(height: 180);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              (stats.weeklyCompletion.values.maxOrNull ?? 0) *
              1.2, // Give some top padding
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final day = DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - value.toInt())));
                  // THE FIX: Add the required `axisSide` parameter, getting the value from `meta`.
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4, // Add a little space
                    child: Text(day, style: theme.textTheme.bodySmall),
                  );
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final dayOfWeek = DateTime.now()
                .subtract(Duration(days: 6 - index))
                .weekday;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stats.weeklyCompletion[dayOfWeek]?.toDouble() ?? 0,
                  color: theme.colorScheme.secondary,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
