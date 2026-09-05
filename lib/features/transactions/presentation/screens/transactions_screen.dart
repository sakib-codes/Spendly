import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionProvider);
    final categoriesState = ref.watch(categoryProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSearchBar(context),
            const SizedBox(height: 32),
            transactionsState.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No transactions found.'),
                    ),
                  );
                }

                // Group transactions by date
                final Map<String, List<Transaction>> grouped = {};
                for (var t in transactions) {
                  final dateStr = DateFormat('MMM d, yyyy').format(t.date);
                  grouped.putIfAbsent(dateStr, () => []).add(t);
                }

                return Column(
                  children: grouped.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildDateGroup(
                        context, 
                        entry.key.toUpperCase(), 
                        entry.value.map((t) {
                          final hasDecimal = t.amount != t.amount.truncateToDouble();
                          final formatCurrency = NumberFormat.simpleCurrency(name: 'BDT', decimalDigits: hasDecimal ? 2 : 0);
                          final amountPrefix = t.type == TransactionType.expense ? '-' : '+';
                          
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
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildTransactionTile(
                              context, 
                              ref,
                              t, 
                              categoryName, 
                              DateFormat('h:mm a').format(t.date), 
                              '$amountPrefix${formatCurrency.format(t.amount)}', 
                              categoryIconKey
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Transactions', 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left_rounded, size: 20, color: theme.colorScheme.onSurface),
                const SizedBox(width: 4),
                Flexible(
                  child: Text('September 2026', style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search description...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildDateGroup(BuildContext context, String dateLabel, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            dateLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
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
