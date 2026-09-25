import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';
import 'package:spendly/shared/widgets/custom_header.dart';
import 'package:spendly/shared/widgets/glass_date_picker.dart';
import 'package:spendly/shared/widgets/glass_time_picker.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/category_provider.dart';
import 'package:spendly/domain/entities/transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/shared/utils/category_icon_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:spendly/domain/entities/recurring_transaction.dart';
import 'package:spendly/shared/providers/recurring_transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool isExpense = true;
  bool _isForward = true;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Mobile Banking',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(_onAmountStateChange);
    _amountController.addListener(_onAmountStateChange);
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

  void _onAmountStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountStateChange);
    _amountFocusNode.dispose();
    _amountController.removeListener(_onAmountStateChange);
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoryProvider);

    // If editing, try to pre-select the category once categories are loaded
    if (_selectedCategory == null && widget.transactionToEdit != null) {
      final categories = categoriesState.value;
      if (categories != null) {
        _selectedCategory = categories
            .where((c) => c.id == widget.transactionToEdit!.categoryId)
            .firstOrNull;
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomHeader(
                title: widget.transactionToEdit != null
                    ? 'Edit Transaction'
                    : 'Add Transaction',
                icon: Icons.close_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeToggle(context),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final childIsExpense =
                            (child.key as ValueKey<bool>).value;
                        final isEntering = childIsExpense == isExpense;

                        Offset begin;
                        if (isEntering) {
                          begin = _isForward
                              ? const Offset(0.3, 0)
                              : const Offset(-0.3, 0);
                        } else {
                          begin = _isForward
                              ? const Offset(-0.3, 0)
                              : const Offset(0.3, 0);
                        }

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: begin,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey<bool>(isExpense),
                        children: [
                          _buildAmountInput(context),
                          const SizedBox(height: 32),
                          _buildTextInputField(
                            context,
                            'Title',
                            _titleController,
                            Icons.title_rounded,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          categoriesState.maybeWhen(
                            data: (categories) {
                              final type = isExpense
                                  ? CategoryType.expense
                                  : CategoryType.income;
                              final availableCategories = categories
                                  .where(
                                    (c) =>
                                        c.type == type ||
                                        c.type == CategoryType.both,
                                  )
                                  .toList();

                              return _buildCategorySelector(
                                context,
                                availableCategories,
                              );
                            },
                            orElse: () => const CircularProgressIndicator(),
                          ),
                          const SizedBox(height: 16),
                          _buildDatePicker(context),
                          const SizedBox(height: 16),
                          if (widget.transactionToEdit == null) ...[
                            _buildRecurringSelector(context),
                            const SizedBox(height: 16),
                          ],
                          _buildPaymentMethodSelector(context),
                          const SizedBox(height: 16),
                          _buildTextInputField(
                            context,
                            'Note (optional)',
                            _noteController,
                            Icons.notes_rounded,
                            Colors.grey,
                          ),
                          const SizedBox(height: 48),
                          PrimaryButton(
                            text: widget.transactionToEdit != null
                                ? 'Update Transaction'
                                : 'Save Transaction',
                            onPressed: () {
                              final amount =
                                  double.tryParse(_amountController.text) ??
                                  0.0;

                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid amount greater than 0',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (_selectedCategory == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a category'),
                                  ),
                                );
                                return;
                              }

                              final title = _titleController.text.trim().isEmpty
                                  ? 'New Transaction'
                                  : _titleController.text.trim();

                              final transaction = Transaction(
                                id:
                                    widget.transactionToEdit?.id ??
                                    const Uuid().v4(),
                                title: title,
                                amount: amount,
                                type: isExpense
                                    ? TransactionType.expense
                                    : TransactionType.income,
                                categoryId: _selectedCategory!.id,
                                date: _selectedDate,
                                paymentMethod: _selectedPaymentMethod,
                                note: _noteController.text.trim().isEmpty
                                    ? null
                                    : _noteController.text.trim(),
                                createdAt:
                                    widget.transactionToEdit?.createdAt ??
                                    DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              if (widget.transactionToEdit != null) {
                                ref
                                    .read(transactionProvider.notifier)
                                    .updateTransaction(transaction);
                              } else {
                                ref
                                    .read(transactionProvider.notifier)
                                    .addTransaction(transaction);

                                // If user toggled recurring, also create a recurring entry
                                if (_isRecurring) {
                                  final recurring = RecurringTransaction(
                                    id: const Uuid().v4(),
                                    title: title,
                                    amount: amount,
                                    type: isExpense ? 'expense' : 'income',
                                    categoryId: _selectedCategory!.id,
                                    frequency: _frequency,
                                    nextDate: _calculateNextDate(_selectedDate, _frequency),
                                    paymentMethod: _selectedPaymentMethod,
                                    note: _noteController.text.trim().isEmpty
                                        ? null
                                        : _noteController.text.trim(),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  ref
                                      .read(recurringTransactionProvider.notifier)
                                      .addRecurringTransaction(recurring);
                                }
                              }
                              context.pop();
                            },
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
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // Sliding Background
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tap Targets and Text
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isExpense) return;
                    setState(() {
                      _isForward = false;
                      isExpense = true;
                      _selectedCategory = null;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: isExpense
                            ? AppColors.expenseAccent
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isExpense
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      child: const Text('Expense'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isExpense) return;
                    setState(() {
                      _isForward = true;
                      isExpense = false;
                      _selectedCategory = null;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: !isExpense
                            ? AppColors.incomeAccent
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: !isExpense
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      child: const Text('Income'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currencyPref) {
    final match = RegExp(r'\((.*?)\)').firstMatch(currencyPref);
    return match?.group(1) ?? '৳';
  }

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider);
    final currencySymbol = _getCurrencySymbol(preferences.currency);
    final accentColor = isExpense
        ? AppColors.expenseAccent
        : AppColors.incomeAccent;
    final hasValue = _amountController.text.isNotEmpty;
    final isFocused = _amountFocusNode.hasFocus;
    final textLength = _amountController.text.length;

    // Dynamic font size — shrinks as number gets longer
    double fontSize;
    if (textLength <= 5) {
      fontSize = 42;
    } else if (textLength <= 7) {
      fontSize = 34;
    } else {
      fontSize = 26;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ── Micro-label ──
            AnimatedOpacity(
              opacity: (!hasValue || isFocused) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Enter amount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // ── Amount Display Row ──
            GestureDetector(
              onTap: () {
                _amountFocusNode.requestFocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Currency symbol
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: fontSize * 0.65,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(currencySymbol),
                  ),
                  const SizedBox(width: 4),
                  // Amount text field — bounded IntrinsicWidth prevents overflow
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 140,
                    ),
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: TextStyle(
                          fontSize: fontSize,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                        cursorColor: accentColor,
                        cursorHeight: fontSize * 0.85,
                        cursorWidth: 2.5,
                        cursorRadius: const Radius.circular(2),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 42,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.15,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Clear icon — only visible when there's a value
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: hasValue
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _amountController.clear();
                                _amountFocusNode.requestFocus();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.07),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ── Quick-Add Chips ──
            _buildQuickPresetChips(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPresetChips(Color accentColor) {
    final theme = Theme.of(context);
    final presets = [100, 500, 1000, 5000];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.map((amount) {
        final label = amount >= 1000 ? '+${amount ~/ 1000}k' : '+$amount';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                final current =
                    double.tryParse(_amountController.text) ?? 0.0;
                final next = current + amount;
                final formatted = next == next.truncateToDouble()
                    ? next.toInt().toString()
                    : next.toStringAsFixed(2);
                _amountController.text = formatted;
                _amountController.selection = TextSelection.collapsed(
                  offset: formatted.length,
                );
                setState(() {});
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInputField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon,
    Color iconColor,
  ) {
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

  Widget _buildCategorySelector(
    BuildContext context,
    List<Category> categories,
  ) {
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
                    ? CategoryIconHelper.getColor(_selectedCategory!.icon)
                          .withValues(alpha: 0.1)
                    : iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _selectedCategory != null
                  ? CategoryIconHelper.getIconWidget(
                      _selectedCategory!.icon,
                      color: CategoryIconHelper.getColor(
                        _selectedCategory!.icon,
                      ),
                      size: 20,
                    )
                  : Icon(Icons.category_rounded, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedCategory?.name ?? 'Select Category',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _selectedCategory != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    final theme = Theme.of(context);
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  color: isSelected
                                      ? CategoryIconHelper.getColor(cat.icon)
                                            .withValues(alpha: 0.15)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: CategoryIconHelper.getColor(
                                            cat.icon,
                                          ),
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.06),
                                        ),
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
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
          ),
        );
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
        if (date != null) {
          if (!context.mounted) return;
          final time = await GlassTimePicker.show(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
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
              child: Icon(
                Icons.calendar_today_rounded,
                color: iconColor,
                size: 20,
              ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
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
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedPaymentMethod,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                    )
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

  Widget _buildRecurringSelector(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = Colors.purple;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Repeat Transaction',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Switch(
                value: _isRecurring,
                activeThumbColor: iconColor,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _isRecurring
                ? Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: RecurrenceFrequency.values.map((freq) {
                          final isSelected = _frequency == freq;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _frequency = freq;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? iconColor.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? iconColor
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                freq.name[0].toUpperCase() +
                                    freq.name.substring(1),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? iconColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  DateTime _calculateNextDate(
      DateTime current, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        int year = current.year;
        int month = current.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        int day = current.day;
        final daysInNextMonth = DateTime(year, month + 1, 0).day;
        if (day > daysInNextMonth) day = daysInNextMonth;
        return DateTime(year, month, day, current.hour, current.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day,
            current.hour, current.minute);
    }
  }
}
