import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendly/shared/providers/preferences_provider.dart';

class BiometricLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricLockWrapper({super.key, required this.child});

  @override
  ConsumerState<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends ConsumerState<BiometricLockWrapper> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  
  // Track if we need to show lock screen. If biometrics is off, this is always false.
  bool _needsAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Determine initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
    });
  }
  
  void _checkInitialState() {
    final prefs = ref.read(preferencesProvider);
    if (prefs.useBiometrics) {
      setState(() => _needsAuth = true);
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final useBiometrics = ref.read(preferencesProvider).useBiometrics;
    if (!useBiometrics) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background, require auth when it comes back
      if (!_needsAuth) {
        setState(() {
          _needsAuth = true;
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_needsAuth && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device doesn't support biometrics, just let them in
        setState(() {
          _isAuthenticated = true;
          _needsAuth = false;
          _isAuthenticating = false;
        });
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access Spendly',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      setState(() {
        _isAuthenticated = didAuthenticate;
        if (didAuthenticate) {
          _needsAuth = false;
        }
        _isAuthenticating = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
      debugPrint('Biometric error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final useBiometrics = ref.watch(preferencesProvider.select((p) => p.useBiometrics));
    
    // If biometrics was turned off while locked, unlock automatically
    if (!useBiometrics && _needsAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _needsAuth = false;
          _isAuthenticated = true;
        });
      });
    }

    return Stack(
      children: [
        widget.child,
        if (useBiometrics && _needsAuth)
          Positioned.fill(
            child: _buildLockScreen(context),
          ),
      ],
    );
  }
  
  Widget _buildLockScreen(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background of the app
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Spendly is locked',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to access your data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isAuthenticating)
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ],
      ),
    );
  }
}
