import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';
// Removed invalid import
import 'package:spendly/shared/providers/budget_provider.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:spendly/shared/widgets/zoomable_line_chart.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:intl/intl.dart';
import 'package:spendly/shared/widgets/month_picker_pill.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(20),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor
                              .withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    labelStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: Theme.of(context)
                        .textTheme
                        .titleMedium,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Budgets'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping to allow chart gestures
                  children: [
                    _buildOverviewTab(context, ref),
                    _buildBudgetsTab(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final spendingTrend = ref.watch(spendingTrendProvider);
    final monthComparison = ref.watch(monthComparisonProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
      children: [
        _buildAvgRow(
          context,
          dashboardStats.totalIncome,
          dashboardStats.totalExpense,
        ),
        const SizedBox(height: 32),
        _buildSpendingTrend(
          context,
          ref,
          spendingTrend,
          ref.watch(selectedMonthProvider),
        ),
        const SizedBox(height: 24),
        _buildComparisonCard(context, monthComparison),
      ],
    );
  }

  // The month switcher was removed in favor of inline pickers

  Widget _buildBudgetsTab(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(budgetProgressProvider);
    final theme = Theme.of(context);

    return progressState.when(
      data: (progressList) {
        if (progressList.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No budgets set yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Set Budget" below to start tracking',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        final sortedList = List.of(progressList)
          ..sort((a, b) => b.percentage.compareTo(a.percentage));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Budgets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const MonthPickerPill(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                itemCount: sortedList.length,
                itemBuilder: (context, index) {
                  final progress = sortedList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildBudgetCard(context, progress, ref),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    CategoryBudgetProgress progress,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isSet = progress.budgetedAmount > 0;
    final color = progress.isOverBudget
        ? AppColors.expenseAccent
        : theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CategoryIconHelper.getIconWidget(
                      progress.categoryIcon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    progress.categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showSetBudgetSheet(context, progress),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.06,
                  ), // Subtle highlight color
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isSet ? 'Edit' : 'Set Budget',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isSet) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatBDT(progress.spentAmount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'of ${formatBDT(progress.budgetedAmount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.percentage,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
                color: color,
                minHeight: 8,
              ),
            ),
            if (progress.isOverBudget) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.expenseAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Over budget by ${formatBDT(progress.spentAmount - progress.budgetedAmount)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.expenseAccent,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No budget set for this category.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSetBudgetSheet(
    BuildContext context,
    CategoryBudgetProgress progress,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetBudgetSheet(progress: progress),
    );
  }

  Widget _buildAvgRow(
    BuildContext context,
    double totalIncome,
    double totalExpense,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildAvgCard(
            context,
            'Total Income',
            formatBDT(totalIncome),
            true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAvgCard(
            context,
            'Total Expense',
            formatBDT(totalExpense),
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildAvgCard(
    BuildContext context,
    String title,
    String amount,
    bool isIncome,
  ) {
    final theme = Theme.of(context);
    final color = isIncome ? AppColors.incomeAccent : AppColors.expenseAccent;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrend(
    BuildContext context,
    WidgetRef ref,
    SpendingTrend trend,
    DateTime selectedMonth,
  ) {
    final theme = Theme.of(context);
    final expenseColor = AppColors.expenseAccent;
    final incomeColor = AppColors.incomeAccent;

    // Find max for chart scaling
    double maxTotal = 1.0;
    for (var val in trend.dailyExpense) {
      if (val > maxTotal) maxTotal = val;
    }
    for (var val in trend.dailyIncome) {
      if (val > maxTotal) maxTotal = val;
    }

    List<FlSpot> expenseSpots = [];
    List<FlSpot> incomeSpots = [];
    for (int i = 0; i < trend.dailyExpense.length; i++) {
      expenseSpots.add(FlSpot(i.toDouble(), trend.dailyExpense[i]));
      incomeSpots.add(FlSpot(i.toDouble(), trend.dailyIncome[i]));
    }

    final dateFormat = DateFormat('MMM d');
    List<String> labels = [];
    for (int i = 0; i < trend.dailyExpense.length; i++) {
      labels.add(
        dateFormat.format(
          DateTime(selectedMonth.year, selectedMonth.month, i + 1),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Income Vs Spending Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const MonthPickerPill(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: incomeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Income',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: expenseColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Expense',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 24,
            left: 16,
            right: 24,
          ),
          child: SizedBox(
            height: 180,
            child: ZoomableLineChart(
              expenseSpots: expenseSpots,
              incomeSpots: incomeSpots,
              labels: labels,
              minY: -(maxTotal * 0.05),
              maxY: maxTotal * 1.2,
              horizontalInterval: maxTotal > 0 ? maxTotal / 3 : 1,
              incomeColor: incomeColor,
              expenseColor: expenseColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    MonthComparison comparison,
  ) {
    final theme = Theme.of(context);

    final color = comparison.isLower
        ? AppColors.incomeAccent
        : AppColors.expenseAccent;
    final icon = comparison.isLower
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    final diffText = comparison.difference == 0
        ? 'Same'
        : '${comparison.difference.toStringAsFixed(0)}% ${comparison.isLower ? 'lower' : 'higher'}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs Last Month (${comparison.lastMonthName})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatBDT(comparison.currentMonthExpense)} vs ${formatBDT(comparison.lastMonthExpense)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  diffText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetBudgetSheet extends ConsumerStatefulWidget {
  final CategoryBudgetProgress progress;

  const _SetBudgetSheet({required this.progress});

  @override
  ConsumerState<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<_SetBudgetSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.progress.budgetedAmount > 0
          ? widget.progress.budgetedAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getCurrencySymbol(String currencyPref) {
    final match = RegExp(r'\((.*?)\)').firstMatch(currencyPref);
    return match?.group(1) ?? currencyPref;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider);
    final currencySymbol = _getCurrencySymbol(preferences.currency);

    return GlassCard(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        top: 32,
        left: 24,
        right: 24,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Budget',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: '$currencySymbol ',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Save Budget',
            color: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
            onPressed: () {
              final amount = double.tryParse(_controller.text) ?? 0.0;
              if (amount > 0) {
                ref
                    .read(budgetProvider.notifier)
                    .setBudget(widget.progress.categoryId, amount);
              } else {
                ref
                    .read(budgetProvider.notifier)
                    .removeBudget(widget.progress.categoryId);
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
          if (widget.progress.budgetedAmount > 0) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref
                    .read(budgetProvider.notifier)
                    .removeBudget(widget.progress.categoryId);
                Navigator.of(context, rootNavigator: true).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                foregroundColor: AppColors.expenseAccent,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Remove Budget',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
