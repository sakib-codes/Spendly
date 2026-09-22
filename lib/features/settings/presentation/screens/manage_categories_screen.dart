import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/custom_header.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/utils/currency_formatter.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:uuid/uuid.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = ref.watch(categoryProvider);
    final transactionsState = ref.watch(transactionProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            const CustomHeader(title: 'Categories', padding: EdgeInsets.zero),
            const SizedBox(height: 24),

            // Toggle
            _buildToggle(context),
            const SizedBox(height: 24),

            // Section header
            Text(
              _showExpense ? 'EXPENSE CATEGORIES' : 'INCOME CATEGORIES',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Category list
            categoriesState.when(
              data: (categories) {
                final filtered = _showExpense
                    ? categories
                          .where(
                            (c) =>
                                c.type == CategoryType.expense ||
                                c.type == CategoryType.both,
                          )
                          .toList()
                    : categories
                          .where(
                            (c) =>
                                c.type == CategoryType.income ||
                                c.type == CategoryType.both,
                          )
                          .toList();

                final transactions =
                    transactionsState.whenOrNull(data: (t) => t) ?? [];

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No categories yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((category) {
                    return _buildCategoryTile(context, category, transactions);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),

            const SizedBox(height: 24),

            // Add Category button
            Center(
              child: TextButton.icon(
                onPressed: () => _showAddCategorySheet(
                  context,
                  _showExpense ? CategoryType.expense : CategoryType.income,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showExpense = true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: _showExpense
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _showExpense
                      ? [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _showExpense
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: _showExpense
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showExpense = false),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: !_showExpense
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !_showExpense
                      ? [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: !_showExpense
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: !_showExpense
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category,
    List<Transaction> transactions,
  ) {
    final theme = Theme.of(context);
    final color = CategoryIconHelper.getColor(category.icon);

    // Count transactions and total amount for this category
    final categoryTransactions = transactions
        .where((t) => t.categoryId == category.id)
        .toList();
    final transactionCount = categoryTransactions.length;
    final totalAmount = categoryTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    return Dismissible(
      key: ValueKey(category.id),
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
      confirmDismiss: (direction) async {
        if (transactionCount > 0) {
          return await GlassDialog.show<bool>(
            context: context,
            title: "Cannot Delete",
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            content: Text(
              "This category is used in $transactionCount transaction(s).\n\nPlease delete or re-assign them first.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }

        return await GlassDialog.show<bool>(
          context: context,
          title: "Confirm Delete",
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
            size: 48,
          ),
          content: const Text(
            "Are you sure you wish to delete this category?",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "DELETE",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
      onDismissed: (direction) {
        ref.read(categoryProvider.notifier).deleteCategory(category.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(categoryProvider.notifier).addCategory(category);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CategoryIconHelper.getIconWidget(
                  category.icon,
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
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transactionCount > 0
                          ? '$transactionCount transactions • ${formatBDT(totalAmount)}'
                          : 'No transactions yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.drag_handle_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, CategoryType initialType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategorySheet(initialType: initialType),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  final CategoryType initialType;

  const _AddCategorySheet({required this.initialType});

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  late CategoryType _selectedType;
  String _selectedIconKey = 'other';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'New Category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Glass Type Toggle
            GlassCard(
              padding: EdgeInsets.zero,
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedType == CategoryType.expense) return;
                        setState(() => _selectedType = CategoryType.expense);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedType == CategoryType.expense
                              ? theme.colorScheme.surfaceContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedType == CategoryType.expense
                              ? Border.all(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                )
                              : null,
                          boxShadow: _selectedType == CategoryType.expense
                              ? [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _selectedType == CategoryType.expense
                                  ? AppColors.expenseAccent
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: _selectedType == CategoryType.expense
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedType == CategoryType.income) return;
                        setState(() => _selectedType = CategoryType.income);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedType == CategoryType.income
                              ? theme.colorScheme.surfaceContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedType == CategoryType.income
                              ? Border.all(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                )
                              : null,
                          boxShadow: _selectedType == CategoryType.income
                              ? [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Income',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _selectedType == CategoryType.income
                                  ? AppColors.incomeAccent
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: _selectedType == CategoryType.income
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Custom Name Input
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.title_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Category Name',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Icon Selector
            Text('Select Icon', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: CategoryIconHelper.getAllIcons().length,
                itemBuilder: (context, index) {
                  final entry = CategoryIconHelper.getAllIcons().entries
                      .elementAt(index);
                  final isSelected = _selectedIconKey == entry.key;
                  final color = CategoryIconHelper.getColor(entry.key);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconKey = entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: color, width: 2)
                            : Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                      ),
                      child: CategoryIconHelper.getIconWidget(
                        entry.key,
                        size: 24,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            PrimaryButton(
              text: 'Save Category',
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;

                final existingCategories =
                    ref.read(categoryProvider).value ?? [];
                if (existingCategories.any(
                  (c) => c.name.toLowerCase() == name.toLowerCase(),
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A category with this name already exists.',
                      ),
                    ),
                  );
                  return;
                }

                final newCategory = Category(
                  id: const Uuid().v4(),
                  name: name,
                  icon: _selectedIconKey,
                  type: _selectedType,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                ref.read(categoryProvider.notifier).addCategory(newCategory);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
