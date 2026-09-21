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
import 'package:spendly/shared/providers/weather_provider.dart';
import 'package:spendly/shared/widgets/advanced_weather_card.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good evening,'; // Late night
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final transactionsState = ref.watch(transactionProvider);
    final spendingBreakdown = ref.watch(spendingBreakdownProvider);
    final categoriesState = ref.watch(categoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            // Add a small delay so the refresh animation has time to show
            // since local database queries return almost instantly!
            await Future.delayed(const Duration(seconds: 1));
            
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(transactionProvider);
            ref.invalidate(spendingBreakdownProvider);
            ref.invalidate(weatherInfoProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 24),
              _buildTotalBalance(context, ref, dashboardStats.totalBalance),
              const SizedBox(height: 32),
              _buildIncomeExpenseRow(context, dashboardStats.totalIncome, dashboardStats.totalExpense),
              const SizedBox(height: 32),
              _buildSpendingThisMonth(context, ref, dashboardStats.totalExpense, spendingBreakdown),
              const SizedBox(height: 32),
              _buildRecentTransactions(context, ref, transactionsState, categoriesState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weatherState = ref.watch(weatherInfoProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(), 
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Sakib', 
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        weatherState.when(
          data: (weather) => GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing weather...'), duration: Duration(seconds: 1)));
              ref.invalidate(weatherInfoProvider);
            },
            behavior: HitTestBehavior.opaque,
            child: AdvancedWeatherCard(weather: weather),
          ),
          loading: () => const SizedBox(
            width: 70,
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => GestureDetector(
            onTap: () => ref.invalidate(weatherInfoProvider),
            child: const SizedBox(
              width: 70,
              height: 60,
              child: Center(child: Icon(Icons.refresh, color: Colors.grey)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalance(BuildContext context, WidgetRef ref, double totalBalance) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentMonthYear = DateFormat('MMMM').format(selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurface),
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).setMonth(DateTime(selectedMonth.year, selectedMonth.month - 1));
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentMonthYear.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface),
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).setMonth(DateTime(selectedMonth.year, selectedMonth.month + 1));
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Text('NET BALANCE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: formatBDTRich(
                  totalBalance,
                  baseStyle: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  decimalStyle: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ],
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
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
    final iconBgColor = color.withValues(alpha: 0.1);
    
    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.transactions),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title, 
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                formatBDTRich(
                  amount,
                  baseStyle: theme.textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800, 
                    color: theme.colorScheme.onSurface,
                  ),
                  decimalStyle: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800, 
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingThisMonth(BuildContext context, WidgetRef ref, double totalExpense, List<CategorySpending> breakdown) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthName = DateFormat('MMMM').format(selectedMonth);
    List<PieChartSectionData> sections = [];
    if (breakdown.isEmpty) {
      sections.add(PieChartSectionData(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), value: 100, radius: 8, showTitle: false));
    } else {
      sections = breakdown.map((cat) => PieChartSectionData(
        color: cat.color,
        value: cat.percentage,
        radius: 8,
        showTitle: false,
      )).toList();
    }

    String topSpendingText = 'No expenses this month';
    if (breakdown.isNotEmpty) {
      final top = breakdown.first;
      topSpendingText = 'Top spending is ${top.categoryName} (${formatBDT(top.amount)})';
    }
    
    final isZeroExpense = breakdown.isEmpty;
    final bannerColor = isZeroExpense ? AppColors.incomeAccent : AppColors.expenseAccent;
    final bannerIcon = isZeroExpense ? Icons.check_circle_outline_rounded : Icons.error_outline;

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
                        centerSpaceRadius: 40,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 60,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('TOTAL', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
                              Text(formatBDT(totalExpense), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: breakdown.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/animations/wallet.lottie', width: 80, height: 80),
                          const SizedBox(height: 4),
                          Text(
                            'No spending yet! 🎉',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
            color: bannerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(topSpendingText, style: theme.textTheme.bodyMedium?.copyWith(color: bannerColor)),
              ),
              Text(monthName, style: theme.textTheme.bodySmall?.copyWith(color: bannerColor.withValues(alpha: 0.7))),
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
            final selectedMonth = ref.watch(selectedMonthProvider);
            final monthTransactions = transactions.where((t) => t.date.month == selectedMonth.month && t.date.year == selectedMonth.year).toList();
            
            if (monthTransactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No transactions for this month.'),
              );
            }
            return Column(
              children: monthTransactions.take(3).map((t) {
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
                

                final now = DateTime.now();
                final dateFormat = t.date.year == now.year ? DateFormat('MMM d') : DateFormat('MMM d, yyyy');

                return _buildTransactionTile(
                  context, 
                  ref,
                  t, 
                  categoryName, 
                  dateFormat.format(t.date), 
                  '$amountPrefix${formatBDT(t.amount)}', 
                  categoryIconKey
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
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                Text(amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: t.type == TransactionType.income ? AppColors.incomeAccent : AppColors.expenseAccent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
