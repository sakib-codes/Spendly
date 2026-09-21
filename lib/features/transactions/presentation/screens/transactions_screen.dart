import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:spendly/shared/providers/dashboard_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _filterType;
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionProvider);
    final categoriesState = ref.watch(categoryProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Transactions', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            _buildSearchBar(context, ref),
            const SizedBox(height: 32),
            transactionsState.when(
              data: (allTransactions) {
                final selectedMonth = ref.watch(selectedMonthProvider);
                var transactions = allTransactions.where((t) => t.date.year == selectedMonth.year && t.date.month == selectedMonth.month).toList();
                
                if (_filterType != null) {
                  transactions = transactions.where((t) => t.type == _filterType).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  transactions = transactions.where((t) => 
                    t.title.toLowerCase().contains(_searchQuery) || 
                    (t.note?.toLowerCase().contains(_searchQuery) ?? false)
                  ).toList();
                }

                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No transactions found.'),
                    ),
                  );
                }

                if (_sortBy == 'date_desc') {
                  transactions.sort((a, b) => b.date.compareTo(a.date));
                } else if (_sortBy == 'date_asc') {
                  transactions.sort((a, b) => a.date.compareTo(b.date));
                } else if (_sortBy == 'amount_desc') {
                  transactions.sort((a, b) => b.amount.compareTo(a.amount));
                } else if (_sortBy == 'amount_asc') {
                  transactions.sort((a, b) => a.amount.compareTo(b.amount));
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
                          


                          return _buildTransactionTile(
                            context, 
                            ref,
                            t, 
                            categoryName, 
                            DateFormat('h:mm a').format(t.date), 
                            '$amountPrefix${formatBDT(t.amount)}', 
                            categoryIconKey
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

  Widget _buildMonthSwitcher(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentMonthYear = DateFormat('MMMM').format(selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => ref.read(selectedMonthProvider.notifier).setMonth(DateTime(selectedMonth.year, selectedMonth.month - 1)),
          ),
          const SizedBox(width: 16),
          Text(
            currentMonthYear.toUpperCase(), 
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            )
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => ref.read(selectedMonthProvider.notifier).setMonth(DateTime(selectedMonth.year, selectedMonth.month + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
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
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              useRootNavigator: true,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40, height: 4,
                                decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('Filters', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            
                            Text('Month', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _buildMonthSwitcher(context, ref),
                            ),
                            const SizedBox(height: 24),

                            Text('Type', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildFilterChip(context, 'All', _filterType == null, () {
                                  setModalState(() => _filterType = null);
                                  setState(() {});
                                })),
                                const SizedBox(width: 8),
                                Expanded(child: _buildFilterChip(context, 'Income', _filterType == TransactionType.income, () {
                                  setModalState(() => _filterType = TransactionType.income);
                                  setState(() {});
                                }, activeColor: AppColors.incomeAccent)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildFilterChip(context, 'Expense', _filterType == TransactionType.expense, () {
                                  setModalState(() => _filterType = TransactionType.expense);
                                  setState(() {});
                                }, activeColor: AppColors.expenseAccent)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text('Sort By', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildFilterChip(context, 'Newest First', _sortBy == 'date_desc', () {
                                  setModalState(() => _sortBy = 'date_desc');
                                  setState(() {});
                                })),
                                const SizedBox(width: 8),
                                Expanded(child: _buildFilterChip(context, 'Oldest First', _sortBy == 'date_asc', () {
                                  setModalState(() => _sortBy = 'date_asc');
                                  setState(() {});
                                })),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildFilterChip(context, 'Highest Amount', _sortBy == 'amount_desc', () {
                                  setModalState(() => _sortBy = 'amount_desc');
                                  setState(() {});
                                })),
                                const SizedBox(width: 8),
                                Expanded(child: _buildFilterChip(context, 'Lowest Amount', _sortBy == 'amount_asc', () {
                                  setModalState(() => _sortBy = 'amount_asc');
                                  setState(() {});
                                })),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _filterType = null;
                                  _sortBy = 'date_desc';
                                  ref.read(selectedMonthProvider.notifier).setMonth(DateTime.now());
                                });
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Clear All Filters',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
          child: GlassCard(
            padding: EdgeInsets.zero,
            height: 56,
            width: 56,
            child: Center(
              child: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        color: isSelected ? color : null,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
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
