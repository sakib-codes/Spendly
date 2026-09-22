import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/router/route_names.dart';
import 'package:spendly/app/theme/app_colors.dart';
import 'package:spendly/shared/widgets/glass_card.dart';
import 'package:spendly/shared/providers/theme_provider.dart';
import 'package:spendly/shared/providers/transaction_provider.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';
import 'package:spendly/shared/utils/export_service.dart';
import 'package:spendly/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/shared/widgets/glass_dialog.dart';
import 'package:spendly/shared/widgets/primary_button.dart';
import 'package:spendly/shared/widgets/custom_license_page.dart';
import 'package:spendly/shared/widgets/glass_toast.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final preferences = ref.watch(preferencesProvider);
    final String themeText = switch (themeMode) {
      ThemeMode.system => 'System Default',
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSection(context, 'PREFERENCES', [
              _buildSettingItem(
                context,
                'Manage Categories',
                '',
                onTap: () {
                  context.pushNamed(RouteNames.categories);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'Currency',
                preferences.currency,
                onTap: () {
                  _showCurrencyPicker(context, ref, preferences.currency);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'Theme',
                themeText,
                onTap: () {
                  _showThemePicker(context, ref, themeMode);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'First day of month',
                preferences.firstDayOfMonth,
                onTap: () {
                  _showFirstDayPicker(
                    context,
                    ref,
                    preferences.firstDayOfMonth,
                  );
                },
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'ACCOUNT', [
              _buildSettingItem(
                context,
                'Edit Profile Name',
                '',
                onTap: () {
                  _showChangeNameDialog(context, ref);
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                ref.read(authProvider.notifier).hasPasswordProvider
                    ? 'Change Password'
                    : 'Set Password',
                '',
                onTap: () {
                  if (ref.read(authProvider.notifier).hasPasswordProvider) {
                    _showChangePasswordDialog(context, ref);
                  } else {
                    _showSetPasswordDialog(context, ref);
                  }
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'Log Out',
                '',
                isDestructive: true,
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Logout Dialog',
                    pageBuilder: (context, _, _) => const _LogoutDialog(),
                  );
                },
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'DATA & SECURITY', [
              _buildSettingItem(
                context,
                'Export Data',
                'CSV / PDF',
                onTap: () async {
                  final transactions = ref.read(transactionProvider).value;
                  if (transactions != null && transactions.isNotEmpty) {
                    await ExportService.exportTransactionsToCSV(transactions);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No transactions to export'),
                      ),
                    );
                  }
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'Clear All Data',
                '',
                isDestructive: true,
                onTap: () {
                  String confirmationText = '';
                  GlassDialog.show(
                    context: context,
                    title: 'Clear All Data',
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.expenseAccent,
                      size: 48,
                    ),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        final theme = Theme.of(context);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Are you sure you want to delete all transactions? This action cannot be undone.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Type "DELETE" to confirm:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    confirmationText = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'DELETE',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return PrimaryButton(
                            width: null, // Let it adapt in the Row
                            text: 'Delete',
                            color: AppColors.expenseAccent,
                            textColor: Colors.white,
                            onPressed: confirmationText == 'DELETE'
                                ? () {
                                    ref
                                        .read(transactionProvider.notifier)
                                        .clearAll();
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'All data cleared successfully',
                                        ),
                                      ),
                                    );
                                  }
                                : () {}, // disabled state handled by Button internally if we wanted, but we can just pass empty or null. Wait, PrimaryButton takes required onPressed, so we can't pass null.
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ]),
            const SizedBox(height: 32),
            _buildSection(context, 'ABOUT', [
              _buildSettingItem(
                context,
                'About Spendly',
                '',
                onTap: () {
                  GlassDialog.show(
                    context: context,
                    title: 'Spendly',
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v1.4.2',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Spendly is a modern, privacy-first personal finance tracker built with Flutter.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrimaryButton(
                              text: 'View Licenses',
                              onPressed: () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(); // Dismiss the dialog first
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (context) => CustomLicensePage(
                                      applicationName: 'Spendly',
                                      applicationVersion: '1.4.2',
                                      applicationIcon: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'assets/icons/app_icon.png',
                                          width: 64,
                                          height: 64,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                'App Version',
                'v1.4.2',
                onTap: () {
                  GlassToast.show(
                    context: context,
                    message: 'You are on the latest version!',
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(xfile.path);
      await ref.read(authProvider.notifier).updateProfilePicture(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'User';

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.2,
                ),
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showChangeNameDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const _ChangeNameDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const _ChangePasswordDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showSetPasswordDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const _SetPasswordDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String label,
    String value, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textColor = isDestructive
        ? AppColors.expenseAccent
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(color: textColor),
            ),
            const SizedBox(width: 16),
            if (value.isNotEmpty)
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            if (value.isNotEmpty) const SizedBox(width: 8),
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

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      indent: 20,
    );
  }

  void _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T currentItem,
    required String Function(T) itemLabel,
    required void Function(T) onSelected,
  }) {
    final theme = Theme.of(context);

    GlassDialog.show(
      context: context,
      title: title,
      actions: const [],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = currentItem == item;
          return InkWell(
            onTap: () {
              onSelected(item);
              Navigator.of(context, rootNavigator: true).pop();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    itemLabel(item),
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

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    String currentCurrency,
  ) {
    final currencies = ['BDT (৳)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)'];
    _showSelectionSheet<String>(
      context: context,
      title: 'Select Currency',
      items: currencies,
      currentItem: currentCurrency,
      itemLabel: (item) => item,
      onSelected: (value) =>
          ref.read(preferencesProvider.notifier).setCurrency(value),
    );
  }

  void _showFirstDayPicker(
    BuildContext context,
    WidgetRef ref,
    String currentDay,
  ) {
    final days = ['1st of Month', 'Monday', 'Sunday'];
    _showSelectionSheet<String>(
      context: context,
      title: 'First Day of Month',
      items: days,
      currentItem: currentDay,
      itemLabel: (item) => item,
      onSelected: (value) =>
          ref.read(preferencesProvider.notifier).setFirstDayOfMonth(value),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentThemeMode,
  ) {
    final themes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final themeNames = {
      ThemeMode.system: 'System Default',
      ThemeMode.light: 'Light Mode',
      ThemeMode.dark: 'Dark Mode',
    };
    _showSelectionSheet<ThemeMode>(
      context: context,
      title: 'Select Theme',
      items: themes,
      currentItem: currentThemeMode,
      itemLabel: (item) => themeNames[item] ?? '',
      onSelected: (value) =>
          ref.read(themeModeProvider.notifier).setTheme(value),
    );
  }
}

class _ChangeNameDialog extends ConsumerStatefulWidget {
  const _ChangeNameDialog();

  @override
  ConsumerState<_ChangeNameDialog> createState() => _ChangeNameDialogState();
}

class _ChangeNameDialogState extends ConsumerState<_ChangeNameDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Change Name',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your name',
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expenseAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.expenseAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expenseAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.expenseAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          width: null,
          text: 'Save',
          isLoading: _isLoading,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            if (_nameController.text.trim().isEmpty) return;
            final newName = _nameController.text.trim();
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(authProvider.notifier).updateProfileName(newName);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Name updated successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.incomeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  elevation: 0,
                ),
              );
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = e.toString();
                });
              }
            }
          },
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Change Password',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _oldPasswordController,
              obscureText: _obscureText,
              enabled: !_isLoading,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Current password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _newPasswordController,
              obscureText: _obscureText,
              enabled: !_isLoading,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureText,
              enabled: !_isLoading,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Confirm new password',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_newPasswordController.text.isNotEmpty &&
                        _newPasswordController.text ==
                            _confirmPasswordController.text &&
                        _newPasswordController.text.length >= 6) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expenseAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.expenseAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expenseAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.expenseAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          width: null,
          text: 'Save',
          isLoading: _isLoading,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            final oldPass = _oldPasswordController.text.trim();
            final newPass = _newPasswordController.text.trim();
            final confirmPass = _confirmPasswordController.text.trim();

            if (oldPass.isEmpty) {
              setState(
                () => _errorMessage = 'Please enter your current password',
              );
              return;
            }
            if (newPass.length < 6) {
              setState(
                () => _errorMessage =
                    'New password must be at least 6 characters',
              );
              return;
            }
            if (newPass != confirmPass) {
              setState(() => _errorMessage = 'New passwords do not match');
              return;
            }

            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              await ref
                  .read(authProvider.notifier)
                  .changePasswordWithReauth(oldPass, newPass);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password updated successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.incomeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  elevation: 0,
                ),
              );
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = e.toString();
                });
              }
            }
          },
        ),
      ],
    );
  }
}

class _SetPasswordDialog extends ConsumerStatefulWidget {
  const _SetPasswordDialog();

  @override
  ConsumerState<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends ConsumerState<_SetPasswordDialog> {
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Set Password',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set a password so you can sign in with your email later.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _newPasswordController,
              obscureText: _obscureText,
              enabled: !_isLoading,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureText,
              enabled: !_isLoading,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Confirm new password',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_newPasswordController.text.isNotEmpty &&
                        _newPasswordController.text ==
                            _confirmPasswordController.text &&
                        _newPasswordController.text.length >= 6) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expenseAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.expenseAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expenseAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.expenseAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          width: null,
          text: 'Save',
          isLoading: _isLoading,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            final newPass = _newPasswordController.text.trim();
            final confirmPass = _confirmPasswordController.text.trim();

            if (newPass.length < 6) {
              setState(
                () => _errorMessage =
                    'New password must be at least 6 characters',
              );
              return;
            }
            if (newPass != confirmPass) {
              setState(() => _errorMessage = 'New passwords do not match');
              return;
            }

            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(authProvider.notifier).updatePassword(newPass);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password set successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.incomeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  elevation: 0,
                ),
              );
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = e.toString();
                });
              }
            }
          },
        ),
      ],
    );
  }
}

class _LogoutDialog extends ConsumerStatefulWidget {
  const _LogoutDialog();

  @override
  ConsumerState<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends ConsumerState<_LogoutDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: 'Log Out',
      content: const Text(
        'Are you sure you want to log out of your account?',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          width: null,
          text: 'Log Out',
          isLoading: _isLoading,
          color: AppColors.expenseAccent,
          textColor: Colors.white,
          onPressed: () async {
            setState(() => _isLoading = true);
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context).pop();
              context.go(RoutePaths.login);
            }
          },
        ),
      ],
    );
  }
}
