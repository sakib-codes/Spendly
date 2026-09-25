import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/recurring_transaction.dart';
import '../../../../shared/providers/recurring_transaction_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/utils/category_icon_helper.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/custom_header.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_dialog.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recurringState = ref.watch(recurringTransactionProvider);
    final categoriesState = ref.watch(categoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CustomHeader(title: 'Subscriptions'),
            Expanded(
              child: recurringState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading subscriptions',
                      style: theme.textTheme.bodyLarge),
                ),
                data: (subscriptions) {
                  if (subscriptions.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Calculate monthly cost
                  double monthlyTotal = 0;
                  for (var sub in subscriptions) {
                    if (sub.type == 'expense') {
                      monthlyTotal += _monthlyEquivalent(sub);
                    }
                  }

                  final categories = categoriesState.value ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monthly Overview Card
                        _buildMonthlyOverview(
                            context, monthlyTotal, subscriptions.length),
                        const SizedBox(height: 28),

                        // Active Subscriptions Header
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'ACTIVE SUBSCRIPTIONS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // Subscription Cards
                        ...subscriptions.map((sub) {
                          final cat = categories
                              .where((c) => c.id == sub.categoryId)
                              .firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSubscriptionCard(
                              context,
                              ref,
                              sub,
                              cat?.icon ?? 'other',
                              cat?.name ?? 'Unknown',
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 56,
                color: Colors.purple.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Subscriptions Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When you add a transaction and toggle\n"Repeat Transaction", it will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(
      BuildContext context, double monthlyTotal, int count) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background gradient orbs
            Positioned(
              top: -40,
              right: -30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.purple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Monthly Cost',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    formatBDT(monthlyTotal),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count active subscription${count == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Yearly estimate
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Colors.purple.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatBDT(monthlyTotal * 12)} / year',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction sub,
    String iconKey,
    String categoryName,
  ) {
    final theme = Theme.of(context);
    final isExpense = sub.type == 'expense';
    final accentColor = isExpense ? AppColors.expenseAccent : AppColors.incomeAccent;
    final dateFormat = DateFormat('MMM d, yyyy');
    final frequencyLabel = sub.frequency.name[0].toUpperCase() + sub.frequency.name.substring(1);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showSubscriptionDetails(context, ref, sub, iconKey, categoryName),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CategoryIconHelper.getColor(iconKey)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: CategoryIconHelper.getIconWidget(iconKey, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            frequencyLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Next: ${dateFormat.format(sub.nextDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Text(
                '${isExpense ? '-' : '+'}${formatBDT(sub.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDetails(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction sub,
    String iconKey,
    String categoryName,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isExpense = sub.type == 'expense';
    final accentColor = isExpense ? AppColors.expenseAccent : AppColors.incomeAccent;
    final frequencyLabel = sub.frequency.name[0].toUpperCase() + sub.frequency.name.substring(1);

    GlassDialog.show(
      context: context,
      title: sub.title,
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CategoryIconHelper.getColor(iconKey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CategoryIconHelper.getIconWidget(iconKey, size: 28),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount
          Text(
            '${isExpense ? '-' : '+'}${formatBDT(sub.amount)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 20),

          // Details rows
          _detailRow(theme, 'Category', categoryName),
          _detailRow(theme, 'Frequency', frequencyLabel),
          _detailRow(theme, 'Next Charge', dateFormat.format(sub.nextDate)),
          if (sub.endDate != null)
            _detailRow(theme, 'Ends On', dateFormat.format(sub.endDate!)),
          if (sub.paymentMethod != null && sub.paymentMethod!.isNotEmpty)
            _detailRow(theme, 'Payment', sub.paymentMethod!),
          if (sub.note != null && sub.note!.isNotEmpty)
            _detailRow(theme, 'Note', sub.note!),

          const SizedBox(height: 4),

          // Monthly / Yearly estimate
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Monthly',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      formatBDT(_monthlyEquivalent(sub)),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                Column(
                  children: [
                    Text('Yearly',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      formatBDT(_monthlyEquivalent(sub) * 12),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Confirm delete
            GlassDialog.show(
              context: context,
              title: 'Cancel Subscription',
              content: Text(
                'Are you sure you want to cancel "${sub.title}"? No future transactions will be auto-created.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Keep',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(recurringTransactionProvider.notifier)
                        .deleteRecurringTransaction(sub.id);
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                  },
                  child: const Text('Cancel Subscription',
                      style: TextStyle(color: AppColors.expenseAccent)),
                ),
              ],
            );
          },
          child: const Text('Cancel Subscription',
              style: TextStyle(color: AppColors.expenseAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close',
              style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _monthlyEquivalent(RecurringTransaction sub) {
    switch (sub.frequency) {
      case RecurrenceFrequency.daily:
        return sub.amount * 30;
      case RecurrenceFrequency.weekly:
        return sub.amount * 4.33;
      case RecurrenceFrequency.monthly:
        return sub.amount;
      case RecurrenceFrequency.yearly:
        return sub.amount / 12;
    }
  }
}
