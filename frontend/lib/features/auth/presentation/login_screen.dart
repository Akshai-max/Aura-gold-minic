import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ags_gold/core/responsive/responsive_layout.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/auth/domain/app_audience.dart';
import 'package:ags_gold/features/auth/presentation/providers/app_audience_provider.dart';
import 'package:ags_gold/services/service_providers.dart';
import 'package:ags_gold/l10n/l10n_extension.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.successMessage});

  final String? successMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _successMessage = widget.successMessage;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.successMessage != oldWidget.successMessage) {
      _successMessage = widget.successMessage;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizeMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }
    return digits;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final audience = ref.read(appAudienceProvider);
    final isEndUser = audience == AppAudience.endUser;

    try {
      if (isEndUser) {
        await ref.read(authNotifierProvider.notifier).loginWithMobile(
              _normalizeMobile(_mobileController.text.trim()),
            );
      } else {
        await ref.read(authNotifierProvider.notifier).login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 100,
                    color: AppTheme.primaryGold,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AGS GOLD',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.secureEnterprisePortal,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final audience = ref.watch(appAudienceProvider);
    final isEndUser = audience == AppAudience.endUser;
    final isStaff = audience == AppAudience.staffAdmin;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ResponsiveLayout.isMobile(context)) ...[
            const Center(
              child: Icon(
                Icons.monetization_on,
                size: 64,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'AGS GOLD',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            isStaff ? l10n.staffSignIn : l10n.welcomeBack,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isStaff
                ? l10n.staffSignInSubtitle
                : isEndUser
                ? l10n.endUserSignInSubtitle
                : l10n.defaultSignInSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isEndUser) ...[
            Text(
              'Mobile Number',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('mobileField'),
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: const InputDecoration(
                hintText: '10-digit mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required.';
                }
                final mobile = _normalizeMobile(value.trim());
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
                  return 'Enter a valid 10-digit mobile number.';
                }
                return null;
              },
            ),
          ] else ...[
            Text(
              l10n.emailAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('emailField'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.emailRequired;
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.password,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(l10n.forgotPassword),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('passwordField'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: l10n.enterPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordRequired;
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            key: const Key('loginButton'),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(l10n.signIn),
          ),
          if (isEndUser) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                key: const Key('goToSignupLink'),
                onPressed: () => context.go('/signup'),
                child: Text(l10n.dontHaveAccountSignUp),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go('/welcome'),
              child: Text(l10n.backToAccountType),
            ),
          ),
        ],
      ),
    );
  }
}
