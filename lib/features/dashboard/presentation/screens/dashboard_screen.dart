import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final transactionsState = ref.watch(transactionProvider);
    final spendingBreakdown = ref.watch(spendingBreakdownProvider);
    final categoriesState = ref.watch(categoryProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildTotalBalance(context, dashboardStats.totalBalance),
            const SizedBox(height: 24),
            _buildIncomeExpenseRow(context, dashboardStats.totalIncome, dashboardStats.totalExpense),
            const SizedBox(height: 32),
            _buildSpendingThisMonth(context, dashboardStats.totalExpense, spendingBreakdown),
            const SizedBox(height: 32),
            _buildRecentTransactions(context, ref, transactionsState, categoriesState),
          ],
        ),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,', 
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Sakib', 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

  Widget _buildTotalBalance(BuildContext context, double totalBalance) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('TOTAL BALANCE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        RichText(
          text: formatBDTRich(
            totalBalance,
            baseStyle: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            decimalStyle: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseRow(BuildContext context, double totalIncome, double totalExpense) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(context, 'Income', totalIncome, true)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard(context, 'Expenses', totalExpense, false)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, double amount, bool isIncome) {
    final theme = Theme.of(context);
    final color = isIncome ? AppColors.incomeAccent : AppColors.expenseAccent;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text.rich(
                formatBDTRich(
                  amount,
                  baseStyle: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: color),
                  decimalStyle: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingThisMonth(BuildContext context, double totalExpense, List<CategorySpending> breakdown) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.compactCurrency(name: 'BDT', symbol: '৳');
    final formatTop = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: 0);

    List<PieChartSectionData> sections = [];
    if (breakdown.isEmpty) {
      sections.add(PieChartSectionData(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), value: 100, radius: 16, showTitle: false));
    } else {
      sections = breakdown.map((cat) => PieChartSectionData(
        color: cat.color,
        value: cat.percentage,
        radius: 16,
        showTitle: false,
      )).toList();
    }

    String topSpendingText = 'No expenses this month';
    if (breakdown.isNotEmpty) {
      final top = breakdown.first;
      topSpendingText = 'Top spending is ${top.categoryName} (${formatTop.format(top.amount)})';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending This Month', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 35,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('TOTAL', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                          Text(formatCurrency.format(totalExpense), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: breakdown.isEmpty
                    ? Center(
                        child: Text(
                          'No spending yet this month',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: breakdown.take(3).map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildLegendItem(context, cat.categoryName, '${cat.percentage.toStringAsFixed(1)}%', cat.color),
                          );
                        }).toList(),
                      ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.expenseAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.expenseAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(topSpendingText, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.expenseAccent)),
              ),
              Text('This Month', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.expenseAccent.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String title, String percentage, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title, 
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(percentage, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref, AsyncValue<List<Transaction>> transactionsState, AsyncValue<List<Category>> categoriesState) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Transactions', 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.transactions),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        transactionsState.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No transactions yet.'),
              );
            }
            return Column(
              children: transactions.take(3).map((t) {
                final hasDecimal = t.amount != t.amount.truncateToDouble();
                final formatCurrency = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: hasDecimal ? 2 : 0);
                final amountPrefix = t.type == TransactionType.income ? '+' : '-';
                
                String categoryName = 'Unknown';
                String categoryIconKey = 'other';
                categoriesState.maybeWhen(
                  data: (categories) {
                    final cat = categories.where((c) => c.id == t.categoryId).firstOrNull;
                    if (cat != null) {
                      categoryName = cat.name;
                      categoryIconKey = cat.icon;
                    }
                  },
                  orElse: () {},
                );
                

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTransactionTile(
                    context, 
                    ref,
                    t, 
                    categoryName, 
                    DateFormat('MMM d').format(t.date), 
                    '$amountPrefix${formatCurrency.format(t.amount)}', 
                    categoryIconKey
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, Transaction t, String category, String date, String amount, String iconKey) {
    final theme = Theme.of(context);
    final color = CategoryIconHelper.getColor(iconKey);

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(transactionProvider.notifier).deleteTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.title} deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(transactionProvider.notifier).addTransaction(t);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => context.pushNamed(RouteNames.transactionDetails, pathParameters: {'id': t.id}),
        behavior: HitTestBehavior.opaque,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CategoryIconHelper.getIconWidget(iconKey, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title, 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $date', 
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.type == TransactionType.income ? AppColors.incomeAccent : theme.colorScheme.onSurface)),
          ],
        ),
      ),
      ),
    );
  }
}
