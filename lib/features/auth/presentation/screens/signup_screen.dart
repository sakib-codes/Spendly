import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignupLoading = false;
  bool _isGoogleLoading = false;
  bool get _isLoading => _isSignupLoading || _isGoogleLoading;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      value: 1.0, // Set to 1.0 to show the last frame
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;
    
    setState(() => _isSignupLoading = true);
    
    try {
      await ref.read(authProvider.notifier).signup(name, email, password);
      if (mounted) context.go(RoutePaths.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.expenseAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSignupLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final isNewUser = await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) {
        if (isNewUser) {
          context.go(RoutePaths.setPassword);
        } else {
          context.go(RoutePaths.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.expenseAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background glowing orbs
          Positioned(
            top: size.height * 0.1,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(color: AppColors.incomeAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(color: AppColors.expenseAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: size.height * 0.01),
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Lottie.asset(
                                'assets/animations/wallet.lottie',
                                width: 80,
                                height: 80,
                                controller: _animationController,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.015),
                          Text('Create Account', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: size.height * 0.01),
                          Text('Sign up to get started', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          SizedBox(height: size.height * 0.025),
                          
                          _buildTextField(context, 'Name', Icons.person_rounded, _nameController),
                          SizedBox(height: size.height * 0.015),
                          _buildTextField(context, 'Email', Icons.email_rounded, _emailController),
                          SizedBox(height: size.height * 0.015),
                          _buildTextField(context, 'Password', Icons.lock_rounded, _passwordController, obscureText: true),
                          SizedBox(height: size.height * 0.025),
                          
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.onSurface,
                                foregroundColor: theme.colorScheme.surface,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isSignupLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(height: size.height * 0.015),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              icon: _isGoogleLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Image.asset('assets/icons/google.png', height: 24),
                              label: const Text('Sign up with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account? ", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Text('Login', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, IconData icon, TextEditingController controller, {bool obscureText = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
