import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';
import 'package:spendly/shared/providers/budget_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _buildHeader(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), // Subtle track color
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, // Selected tab color
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Budgets'),
                    ],
                  ),
                ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
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
        _buildAvgRow(context, dashboardStats.totalIncome, dashboardStats.totalExpense),
        const SizedBox(height: 32),
        _buildSpendingTrend(context, spendingTrend),
        const SizedBox(height: 24),
        _buildComparisonCard(context, monthComparison),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentMonthYear = DateFormat('MMMM yyyy').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Analytics', 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.chevron_left_rounded, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(currentMonthYear, style: theme.textTheme.labelMedium),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetsTab(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(budgetProgressProvider);
    final theme = Theme.of(context);

    return progressState.when(
      data: (progressList) {
        if (progressList.isEmpty) {
          final cats = ref.read(categoryProvider).value ?? [];
          final types = cats.map((c) => c.type.toString().split('.').last).take(5).join(', ');
          return Center(child: Text('Debug - Cats: ${cats.length}, Types: $types'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          itemCount: progressList.length,
          itemBuilder: (context, index) {
            final progress = progressList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildBudgetCard(context, progress, ref),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBudgetCard(BuildContext context, CategoryBudgetProgress progress, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSet = progress.budgetedAmount > 0;
    final color = progress.isOverBudget ? AppColors.expenseAccent : theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progress.categoryName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _showSetBudgetSheet(context, ref, progress),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: theme.colorScheme.surface,
                ),
                child: Text(isSet ? 'Edit' : 'Set Budget', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
              ),
            ],
          ),
          if (isSet) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatBDT(progress.spentAmount), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text('of ${formatBDT(progress.budgetedAmount)}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.percentage,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                color: color,
                minHeight: 8,
              ),
            ),
            if (progress.isOverBudget) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.expenseAccent),
                  const SizedBox(width: 4),
                  Text('Over budget by ${formatBDT(progress.spentAmount - progress.budgetedAmount)}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.expenseAccent)),
                ],
              )
            ]
          ] else ...[
            const SizedBox(height: 8),
            Text('No budget set for this category.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]
        ],
      ),
    );
  }

  void _showSetBudgetSheet(BuildContext context, WidgetRef ref, CategoryBudgetProgress progress) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: progress.budgetedAmount > 0 ? progress.budgetedAmount.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 32,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Budget for ${progress.categoryName}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (৳)',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(controller.text) ?? 0.0;
                    if (amount > 0) {
                      ref.read(budgetProvider.notifier).setBudget(progress.categoryId, amount);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvgRow(BuildContext context, double totalIncome, double totalExpense) {
    return Row(
      children: [
        Expanded(child: _buildAvgCard(context, 'Total Income', formatBDT(totalIncome), true)),
        const SizedBox(width: 16),
        Expanded(child: _buildAvgCard(context, 'Total Expense', formatBDT(totalExpense), false)),
      ],
    );
  }

  Widget _buildAvgCard(BuildContext context, String title, String amount, bool isIncome) {
    final theme = Theme.of(context);
    final color = isIncome ? AppColors.incomeAccent : AppColors.expenseAccent;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(amount, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSpendingTrend(BuildContext context, SpendingTrend trend) {
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
    
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d');
    List<String> labels = [];
    for (int i = 0; i < 7; i++) {
      labels.add(dateFormat.format(now.subtract(Duration(days: 6 - i))));
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('Last 7 Days', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: incomeColor, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Income', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 16),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: expenseColor, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Expense', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
          child: SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxTotal * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxTotal > 0 ? maxTotal / 3 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Text(labels[value.toInt()], style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(radius: 4, color: incomeColor, strokeWidth: 2, strokeColor: theme.colorScheme.surface);
                    }),
                    belowBarData: BarAreaData(
                      show: true, 
                      color: incomeColor.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(radius: 4, color: expenseColor, strokeWidth: 2, strokeColor: theme.colorScheme.surface);
                    }),
                    belowBarData: BarAreaData(
                      show: true, 
                      color: expenseColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, MonthComparison comparison) {
    final theme = Theme.of(context);
    
    final color = comparison.isLower ? AppColors.incomeAccent : AppColors.expenseAccent;
    final icon = comparison.isLower ? Icons.trending_down_rounded : Icons.trending_up_rounded;
    final diffText = comparison.difference == 0 ? 'Same' : '${comparison.difference.toStringAsFixed(0)}% ${comparison.isLower ? 'lower' : 'higher'}';

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
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatBDT(comparison.currentMonthExpense)} vs ${formatBDT(comparison.lastMonthExpense)}', 
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                Text(diffText, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
