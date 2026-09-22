import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:spendly/shared/widgets/month_picker_pill.dart';

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
            await Future.delayed(const Duration(milliseconds: 300));

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
              _buildFinancialSummary(context, ref, dashboardStats),
              const SizedBox(height: 32),
              _buildSpendingThisMonth(
                context,
                ref,
                dashboardStats.totalExpense,
                spendingBreakdown,
              ),
              const SizedBox(height: 32),
              _buildRecentTransactions(
                context,
                ref,
                transactionsState,
                categoriesState,
              ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Refreshing weather...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 1),
                  elevation: 0,
                ),
              );
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

  Widget _buildFinancialSummary(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'NET BALANCE',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const MonthPickerPill(),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.left,
              text: formatBDTRich(
                stats.totalBalance,
                baseStyle: theme.textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                decimalStyle: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Divider
          Container(
            height: 1,
            width: double.infinity,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          // Income & Expense Section
          Row(
            children: [
              Expanded(
                child: _buildMiniSummary(
                  context,
                  'Income',
                  stats.totalIncome,
                  true,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.2,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildMiniSummary(
                  context,
                  'Expenses',
                  stats.totalExpense,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummary(
    BuildContext context,
    String title,
    double amount,
    bool isIncome,
  ) {
    final theme = Theme.of(context);
    final color = isIncome ? AppColors.incomeAccent : AppColors.expenseAccent;
    final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
    final iconBgColor = color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => context.goNamed(RouteNames.transactions),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              formatBDTRich(
                amount,
                baseStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
                decimalStyle: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingThisMonth(
    BuildContext context,
    WidgetRef ref,
    double totalExpense,
    List<CategorySpending> breakdown,
  ) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthName = DateFormat('MMMM').format(selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending in $monthName',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: breakdown.isEmpty
              ? _buildEmptySpendingState(context, theme)
              : _buildSpendingContent(context, theme, totalExpense, breakdown),
        ),
      ],
    );
  }

  Widget _buildEmptySpendingState(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: double.infinity),
        Lottie.asset(
          'assets/animations/wallet.lottie',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 16),
        Text(
          'No spending yet! 🎉',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have no expenses recorded for this month.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpendingContent(
    BuildContext context,
    ThemeData theme,
    double totalExpense,
    List<CategorySpending> breakdown,
  ) {
    final topCat = breakdown.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Spending Banner integrated inside the card!
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.expenseAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.expenseAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Top spending: ${topCat.categoryName}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.expenseAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: breakdown
                          .map(
                            (cat) => PieChartSectionData(
                              color: cat.color,
                              value: cat.percentage,
                              radius: 12,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        FittedBox(
                          child: Text(
                            formatBDT(totalExpense),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: breakdown.take(4).map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildLegendItem(
                      context,
                      cat.categoryName,
                      '${cat.percentage.toStringAsFixed(1)}%',
                      cat.color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String title,
    String percentage,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          percentage,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Transaction>> transactionsState,
    AsyncValue<List<Category>> categoriesState,
  ) {
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
            final monthTransactions = transactions
                .where(
                  (t) =>
                      t.date.month == selectedMonth.month &&
                      t.date.year == selectedMonth.year,
                )
                .toList();

            if (monthTransactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No transactions for this month.'),
              );
            }
            return Column(
              children: monthTransactions.take(3).map((t) {
                final amountPrefix = t.type == TransactionType.income
                    ? '+'
                    : '-';

                String categoryName = 'Unknown';
                String categoryIconKey = 'other';
                categoriesState.maybeWhen(
                  data: (categories) {
                    final cat = categories
                        .where((c) => c.id == t.categoryId)
                        .firstOrNull;
                    if (cat != null) {
                      categoryName = cat.name;
                      categoryIconKey = cat.icon;
                    }
                  },
                  orElse: () {},
                );

                final now = DateTime.now();
                final dateFormat = t.date.year == now.year
                    ? DateFormat('MMM d')
                    : DateFormat('MMM d, yyyy');

                return _buildTransactionTile(
                  context,
                  ref,
                  t,
                  categoryName,
                  dateFormat.format(t.date),
                  '$amountPrefix${formatBDT(t.amount)}',
                  categoryIconKey,
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

  Widget _buildTransactionTile(
    BuildContext context,
    WidgetRef ref,
    Transaction t,
    String category,
    String date,
    String amount,
    String iconKey,
  ) {
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
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${t.title} deleted',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.expenseAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 0,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                ref.read(transactionProvider.notifier).addTransaction(t);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => context.pushNamed(
          RouteNames.transactionDetails,
          pathParameters: {'id': t.id},
        ),
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
                  child: CategoryIconHelper.getIconWidget(
                    iconKey,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$category • $date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Text(
                    amount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: t.type == TransactionType.income
                          ? AppColors.incomeAccent
                          : AppColors.expenseAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
