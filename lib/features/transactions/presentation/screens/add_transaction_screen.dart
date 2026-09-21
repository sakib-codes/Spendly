import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';
import 'package:spendly/shared/widgets/glass_date_picker.dart';
import 'package:spendly/shared/widgets/glass_time_picker.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool isExpense = true;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<String> _paymentMethods = ['Cash', 'Card', 'Mobile Banking', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      isExpense = t.type == TransactionType.expense;
      _selectedDate = t.date;
      _selectedPaymentMethod = t.paymentMethod ?? 'Cash';
      _amountController.text = t.amount == t.amount.truncateToDouble()
          ? t.amount.toInt().toString()
          : t.amount.toString();
      _titleController.text = t.title;
      _noteController.text = t.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = ref.watch(categoryProvider);

    // If editing, try to pre-select the category once categories are loaded
    if (_selectedCategory == null && widget.transactionToEdit != null) {
      final categories = categoriesState.value;
      if (categories != null) {
        _selectedCategory = categories.where((c) => c.id == widget.transactionToEdit!.categoryId).firstOrNull;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _buildTypeToggle(context),
            const SizedBox(height: 32),
            _buildAmountInput(context),
            const SizedBox(height: 32),
            _buildTextInputField(context, 'Title', _titleController, Icons.title_rounded, Colors.purple),
            const SizedBox(height: 16),
            categoriesState.maybeWhen(
              data: (categories) {
                final type = isExpense ? CategoryType.expense : CategoryType.income;
                final availableCategories = categories.where((c) => c.type == type || c.type == CategoryType.both).toList();
                
                return _buildCategorySelector(context, availableCategories);
              },
              orElse: () => const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(context),
            const SizedBox(height: 16),
            _buildPaymentMethodSelector(context),
            const SizedBox(height: 16),
            _buildTextInputField(context, 'Note (optional)', _noteController, Icons.notes_rounded, Colors.grey),
            const SizedBox(height: 48),
            PrimaryButton(
              text: widget.transactionToEdit != null ? 'Update Transaction' : 'Save Transaction',
              onPressed: () {
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount greater than 0')),
                  );
                  return;
                }
                
                if (_selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a category')),
                  );
                  return;
                }

                final title = _titleController.text.trim().isEmpty ? 'New Transaction' : _titleController.text.trim();

                final transaction = Transaction(
                  id: widget.transactionToEdit?.id ?? const Uuid().v4(),
                  title: title,
                  amount: amount,
                  type: isExpense ? TransactionType.expense : TransactionType.income,
                  categoryId: _selectedCategory!.id,
                  date: _selectedDate,
                  paymentMethod: _selectedPaymentMethod,
                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                  createdAt: widget.transactionToEdit?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (widget.transactionToEdit != null) {
                  ref.read(transactionProvider.notifier).updateTransaction(transaction);
                } else {
                  ref.read(transactionProvider.notifier).addTransaction(transaction);
                }
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final theme = Theme.of(context);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isExpense) return;
                setState(() {
                  isExpense = true;
                  _selectedCategory = null;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isExpense ? theme.colorScheme.surfaceContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: isExpense ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)) : null,
                  boxShadow: isExpense ? [
                    BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isExpense ? AppColors.expenseAccent : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isExpense ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isExpense) return;
                setState(() {
                  isExpense = false;
                  _selectedCategory = null;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isExpense ? theme.colorScheme.surfaceContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: !isExpense ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)) : null,
                  boxShadow: !isExpense ? [
                    BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: !isExpense ? AppColors.incomeAccent : theme.colorScheme.onSurfaceVariant,
                      fontWeight: !isExpense ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text('AMOUNT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('৳', style: theme.textTheme.headlineMedium?.copyWith(
              color: isExpense ? AppColors.expenseAccent : AppColors.incomeAccent,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                  constraints: BoxConstraints(minWidth: 50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInputField(BuildContext context, String label, TextEditingController controller, IconData icon, Color iconColor) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, List<Category> categories) {
    final theme = Theme.of(context);
    final iconColor = AppColors.expenseAccent;

    return InkWell(
      onTap: () => _showCategoryPicker(context, categories),
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedCategory != null 
                    ? CategoryIconHelper.getColor(_selectedCategory!.icon).withValues(alpha: 0.1) 
                    : iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _selectedCategory != null 
                  ? CategoryIconHelper.getIconWidget(_selectedCategory!.icon, color: CategoryIconHelper.getColor(_selectedCategory!.icon), size: 20)
                  : Icon(Icons.category_rounded, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedCategory?.name ?? 'Select Category',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _selectedCategory != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    final theme = Theme.of(context);
    final color = isExpense ? AppColors.expenseAccent : AppColors.incomeAccent;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Category', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? CategoryIconHelper.getColor(cat.icon).withValues(alpha: 0.15) : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(color: CategoryIconHelper.getColor(cat.icon), width: 2)
                                    : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                              ),
                              child: CategoryIconHelper.getIconWidget(
                                cat.icon,
                                color: CategoryIconHelper.getColor(cat.icon),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = Colors.blue;
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    return InkWell(
      onTap: () async {
        final date = await GlassDatePicker.show(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null && mounted) {
          final time = await GlassTimePicker.show(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null && mounted) {
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_rounded, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Date', 
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                dateFormat.format(_selectedDate), 
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = Colors.grey;

    return InkWell(
      onTap: () => _showPaymentMethodPicker(context),
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_rounded, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedPaymentMethod,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodPicker(BuildContext context) {
    final theme = Theme.of(context);
    
    GlassDialog.show(
      context: context,
      title: 'Payment Method',
      actions: const [],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod == method;
          return InkWell(
            onTap: () {
              setState(() => _selectedPaymentMethod = method);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    method,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                  else
                    const SizedBox(width: 24, height: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormField(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label, 
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value, 
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}
