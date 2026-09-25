import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';
import 'package:spendly/shared/providers/budget_provider.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:spendly/shared/widgets/zoomable_line_chart.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:intl/intl.dart';
import 'package:spendly/shared/widgets/month_picker_pill.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:spendly/domain/entities/transaction.dart';
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
                  physics: const NeverScrollableScrollPhysics(),
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
    final spendingBreakdown = ref.watch(spendingBreakdownProvider);
    final topExpenses = ref.watch(topExpensesProvider);
    final paymentBreakdown = ref.watch(paymentMethodBreakdownProvider);
    final sixMonthTrend = ref.watch(sixMonthTrendProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
      children: [
        // --- Month Picker Row ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const MonthPickerPill(),
          ],
        ),
        const SizedBox(height: 16),

        // --- Income / Expense Summary Cards ---
        _buildAvgRow(
          context,
          dashboardStats.totalIncome,
          dashboardStats.totalExpense,
        ),
        const SizedBox(height: 12),

        // --- Net Savings Card ---
        _buildSavingsCard(context, dashboardStats.totalIncome, dashboardStats.totalExpense),
        const SizedBox(height: 12),

        // --- Avg Daily Spend & Peak Spending Day ---
        _buildInsightRow(context, spendingTrend, ref.watch(selectedMonthProvider)),
        const SizedBox(height: 32),

        // --- Income vs Spending Trend Chart ---
        _buildSectionHeader(context, 'Income vs Spending Trend'),
        const SizedBox(height: 12),
        _buildSpendingTrend(
          context,
          ref,
          spendingTrend,
          ref.watch(selectedMonthProvider),
        ),
        const SizedBox(height: 32),

        // --- 6-Month Trend Chart ---
        if (sixMonthTrend.isNotEmpty) ...[
          _buildSectionHeader(context, '6-Month Trend'),
          const SizedBox(height: 12),
          _buildSixMonthTrend(context, sixMonthTrend),
          const SizedBox(height: 32),
        ],

        // --- Spending Breakdown (Donut Chart) ---
        if (spendingBreakdown.isNotEmpty) ...[
          _buildSectionHeader(context, 'Spending Breakdown'),
          const SizedBox(height: 12),
          _buildSpendingBreakdown(context, spendingBreakdown),
          const SizedBox(height: 32),
        ],

        // --- Top 5 Expenses ---
        if (topExpenses.isNotEmpty) ...[
          _buildSectionHeader(context, 'Top 5 Expenses'),
          const SizedBox(height: 12),
          _buildTopExpenses(context, topExpenses),
          const SizedBox(height: 32),
        ],

        // --- Payment Method Breakdown ---
        if (paymentBreakdown.isNotEmpty) ...[
          _buildSectionHeader(context, 'Payment Methods'),
          const SizedBox(height: 12),
          _buildPaymentBreakdown(context, paymentBreakdown),
          const SizedBox(height: 32),
        ],

        // --- Month Comparison Card ---
        _buildSectionHeader(context, 'Month Comparison'),
        const SizedBox(height: 12),
        _buildComparisonCard(context, monthComparison),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

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
                  ),
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
        const SizedBox(width: 12),
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
    final icon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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

  // --- NEW: Net Savings Card ---
  Widget _buildSavingsCard(
    BuildContext context,
    double totalIncome,
    double totalExpense,
  ) {
    final theme = Theme.of(context);
    final netSavings = totalIncome - totalExpense;
    final isPositive = netSavings >= 0;
    final color = isPositive ? AppColors.incomeAccent : AppColors.expenseAccent;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive ? Icons.savings_rounded : Icons.money_off_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Savings',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatBDT(netSavings.abs()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${savingsRate.abs().toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  isPositive ? 'saved' : 'deficit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Insight Row (Avg Daily + Peak Day) ---
  Widget _buildInsightRow(
    BuildContext context,
    SpendingTrend trend,
    DateTime selectedMonth,
  ) {
    final theme = Theme.of(context);

    // Find peak spending day
    double peakAmount = 0;
    int peakDayIndex = 0;
    for (int i = 0; i < trend.dailyExpense.length; i++) {
      if (trend.dailyExpense[i] > peakAmount) {
        peakAmount = trend.dailyExpense[i];
        peakDayIndex = i;
      }
    }
    final peakDate = DateTime(selectedMonth.year, selectedMonth.month, peakDayIndex + 1);
    final peakDateStr = DateFormat('MMM d').format(peakDate);

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Avg / Day',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatBDT(trend.avgExpensePerDay),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.expenseAccent,
                  ),
                ),
                Text(
                  'expense',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Peak Day',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  peakAmount > 0 ? formatBDT(peakAmount) : '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warningAccent,
                  ),
                ),
                Text(
                  peakAmount > 0 ? peakDateStr : 'No data',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

    // Empty state
    final hasData = trend.dailyExpense.any((v) => v > 0) ||
        trend.dailyIncome.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 24,
            left: 16,
            right: 24,
          ),
          child: !hasData
              ? SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No transactions this month',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
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

  // --- NEW: Spending Breakdown Donut Chart ---
  Widget _buildSpendingBreakdown(
    BuildContext context,
    List<CategorySpending> breakdown,
  ) {
    final theme = Theme.of(context);
    final top5 = breakdown.take(5).toList();
    final totalExpense = top5.fold(0.0, (sum, c) => sum + c.amount);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Donut chart
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    sections: top5.asMap().entries.map((entry) {
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.amount,
                        color: item.color,
                        radius: 26,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatBDT(totalExpense),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: top5.map((item) {
                final pct = totalExpense > 0
                    ? (item.amount / totalExpense * 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.categoryName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    MonthComparison comparison,
  ) {
    final theme = Theme.of(context);

    final double absoluteDiff = (comparison.currentMonthExpense - comparison.lastMonthExpense).abs();
    final bool isSame = comparison.currentMonthExpense == comparison.lastMonthExpense;
    final bool isHigher = comparison.currentMonthExpense > comparison.lastMonthExpense;
    final bool isLower = comparison.currentMonthExpense < comparison.lastMonthExpense;
    final bool noLastMonthData = comparison.lastMonthExpense == 0;

    Color color;
    IconData icon;
    String diffText;
    String mainText;

    if (isSame) {
      color = theme.colorScheme.onSurfaceVariant;
      icon = Icons.remove_rounded;
      diffText = 'Same';
      mainText = 'Exactly the same';
    } else if (noLastMonthData) {
      color = AppColors.warningAccent;
      icon = Icons.fiber_new_rounded;
      diffText = 'New';
      mainText = 'No expenses in ${comparison.lastMonthName}';
    } else if (isHigher) {
      color = AppColors.expenseAccent;
      icon = Icons.trending_up_rounded;
      diffText = '${comparison.difference.toStringAsFixed(0)}% higher';
      mainText = '${formatBDT(absoluteDiff)} more';
    } else {
      color = AppColors.incomeAccent;
      icon = Icons.trending_down_rounded;
      diffText = '${comparison.difference.abs().toStringAsFixed(0)}% lower';
      mainText = '${formatBDT(absoluteDiff)} less';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.compare_arrows_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comparison.currentMonthName} vs ${comparison.lastMonthName}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  mainText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
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

  Widget _buildSixMonthTrend(BuildContext context, List<MonthSummary> summaries) {
    final theme = Theme.of(context);
    final expenseColor = AppColors.expenseAccent;
    final incomeColor = AppColors.incomeAccent;

    double maxY = 1.0;
    for (var s in summaries) {
      if (s.income > maxY) maxY = s.income;
      if (s.expense > maxY) maxY = s.expense;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: incomeColor, shape: BoxShape.circle),
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
              decoration: BoxDecoration(color: expenseColor, shape: BoxShape.circle),
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
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 0, right: 24),
          child: SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatBDT(rod.toY),
                        theme.textTheme.labelMedium!.copyWith(
                          color: rodIndex == 0 ? incomeColor : expenseColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summaries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            summaries[index].monthName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 3 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                barGroups: summaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.income,
                        color: incomeColor,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: summary.expense,
                        color: expenseColor,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopExpenses(BuildContext context, List<Transaction> expenses) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: expenses.map((expense) {
          final isLast = expense == expenses.last;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expenseAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: AppColors.expenseAccent, size: 20),
                ),
                title: Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(expense.date),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  formatBDT(expense.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.expenseAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 64,
                  endIndent: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentBreakdown(
    BuildContext context,
    List<PaymentMethodSpending> breakdown,
  ) {
    final theme = Theme.of(context);
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: breakdown.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.methodName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatBDT(item.amount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    color: item.color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.15),
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
