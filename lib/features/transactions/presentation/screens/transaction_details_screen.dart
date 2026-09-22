import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/custom_header.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionProvider);
    final categoriesState = ref.watch(categoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: transactionsState.when(
          data: (transactions) {
            final transaction = transactions
                .where((t) => t.id == transactionId)
                .firstOrNull;
            if (transaction == null) {
              return _buildError(context, 'Transaction not found');
            }

            return categoriesState.when(
              data: (categories) {
                final category = categories
                    .where((c) => c.id == transaction.categoryId)
                    .firstOrNull;
                return _buildContent(context, ref, transaction, category);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => _buildError(context, 'Failed to load category'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _buildError(context, 'Failed to load transaction'),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: Center(
            child: Text(message, style: theme.textTheme.titleMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return const CustomHeader(title: 'Details');
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
    Category? category,
  ) {
    final theme = Theme.of(context);
    final formatDate = DateFormat('MMMM d, yyyy');

    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? AppColors.expenseAccent : AppColors.incomeAccent;
    final typeString = isExpense ? 'Expense' : 'Income';

    final categoryColor = category != null
        ? CategoryIconHelper.getColor(category.icon)
        : color;
    final categoryName = category?.name ?? 'Unknown';

    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: category != null
                      ? CategoryIconHelper.getIconWidget(
                          category.icon,
                          size: 32,
                          color: categoryColor,
                        )
                      : Icon(
                          Icons.category_rounded,
                          size: 32,
                          color: categoryColor,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  transaction.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (categoryName.toLowerCase() != transaction.title.toLowerCase())
                Center(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: RichText(
                  text: formatBDTRich(
                    transaction.amount,
                    baseStyle: theme.textTheme.displaySmall!.copyWith(
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
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Type',
                      typeString,
                      valueColor: color,
                    ),
                    Divider(
                      height: 32,
                      thickness: 1,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                    _buildDetailRow(context, 'Category', categoryName),
                    Divider(
                      height: 32,
                      thickness: 1,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                    _buildDetailRow(
                      context,
                      'Date',
                      formatDate.format(transaction.date),
                    ),
                    if (transaction.paymentMethod != null &&
                        transaction.paymentMethod!.isNotEmpty) ...[
                      Divider(
                        height: 32,
                        thickness: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                      ),
                      _buildDetailRow(
                        context,
                        'Payment Method',
                        transaction.paymentMethod!,
                      ),
                    ],
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      Divider(
                        height: 32,
                        thickness: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                      ),
                      _buildDetailRow(context, 'Note', transaction.note!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(transactionProvider.notifier)
                            .deleteTransaction(transaction.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${transaction.title} deleted'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                ref
                                    .read(transactionProvider.notifier)
                                    .addTransaction(transaction);
                              },
                            ),
                          ),
                        );
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expenseAccent.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.expenseAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.addTransaction,
                          extra: transaction,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface,
                        foregroundColor: theme.colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text(
                        'Edit Detail',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
