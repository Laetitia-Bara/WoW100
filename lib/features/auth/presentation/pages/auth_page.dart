import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firebase_account_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_user_profile.dart';
import '../../../../data/models/app_wallpaper_preference.dart';
import '../../../legal/presentation/pages/legal_page.dart';

enum _AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.signIn;
  bool _isBusy = false;
  String? _message;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _runAuthAction(() async {
      if (_isSignUp) {
        await _accountService.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _accountService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    });
  }

  Future<void> _signInWithGoogle() {
    return _runAuthAction(_accountService.signInWithGoogle);
  }

  Future<void> _signInWithApple() {
    return _runAuthAction(_accountService.signInWithApple);
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = 'Entre ton e-mail, puis relance la reinitialisation.';
      });
      return;
    }

    await _runAuthAction(
      () => _accountService.sendPasswordReset(email),
      successMessage: 'E-mail de reinitialisation envoye.',
      stayOnPage: true,
    );
  }

  Future<void> _signOut() async {
    await _runAuthAction(_accountService.signOut, stayOnPage: true);
  }

  Future<void> _updateWallpaperPreference(
    AppWallpaperPreference preference,
  ) async {
    await _runAuthAction(
      () => _accountService.updateWallpaperPreference(preference),
      successMessage: 'Fond d\'ecran mis a jour.',
      stayOnPage: true,
    );
  }

  Future<void> _runAuthAction(
    Future<void> Function() action, {
    String? successMessage,
    bool stayOnPage = false,
  }) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await action();

      if (!mounted) return;
      if (successMessage != null || stayOnPage) {
        setState(() {
          _message = successMessage;
        });
        return;
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _authErrorMessage(error);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _genericAuthErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'E-mail requis';
    if (!email.contains('@')) return 'E-mail invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 6) return '6 caracteres minimum';
    return null;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Adresse e-mail invalide.',
      'invalid-credential' => 'Identifiants incorrects.',
      'email-already-in-use' => 'Un compte existe deja avec cet e-mail.',
      'weak-password' => 'Mot de passe trop faible.',
      'operation-not-allowed' =>
        'Ce fournisseur doit etre active dans Firebase Authentication.',
      'popup-closed-by-user' => 'Fenetre de connexion fermee.',
      'unauthorized-domain' =>
        'Ce domaine doit etre autorise dans Firebase Authentication.',
      _ => error.message ?? 'Connexion impossible pour le moment.',
    };
  }

  String _genericAuthErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('canceled') || text.contains('cancelled')) {
      return 'Connexion annulee.';
    }
    if (text.contains('SignInWithAppleNotSupportedException')) {
      return 'Connexion Apple indisponible sur cet appareil.';
    }

    return 'Connexion impossible pour le moment.';
  }

  void _openLegalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LegalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/icones/icone192.png',
                height: 34,
                width: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Text(
                  'WoW100%',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Informations legales',
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.info_outline),
              onPressed: _openLegalPage,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<AppUserProfile?>(
          stream: _accountService.profileChanges,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 680
                    ? 520.0
                    : double.infinity;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: profile == null
                          ? _AuthForm(
                              formKey: _formKey,
                              mode: _mode,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isBusy: _isBusy,
                              message: _message,
                              onModeChanged: (mode) {
                                setState(() {
                                  _mode = mode;
                                  _message = null;
                                });
                              },
                              onSubmit: _submitEmailPassword,
                              onGoogle: _signInWithGoogle,
                              onApple: _signInWithApple,
                              onPasswordReset: _sendPasswordReset,
                              validateEmail: _validateEmail,
                              validatePassword: _validatePassword,
                            )
                          : _SignedInPanel(
                              profile: profile,
                              isBusy: _isBusy,
                              message: _message,
                              onWallpaperChanged: _updateWallpaperPreference,
                              onSignOut: _signOut,
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.mode,
    required this.emailController,
    required this.passwordController,
    required this.isBusy,
    required this.message,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onGoogle,
    required this.onApple,
    required this.onPasswordReset,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final _AuthMode mode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isBusy;
  final String? message;
  final ValueChanged<_AuthMode> onModeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onPasswordReset;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  bool get _isSignUp => mode == _AuthMode.signUp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'WoW100%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connecte-toi afin de retrouver ton progress et tes favoris, quelque soit ta plateforme (Web, Android, iOS)  ;)',
                style: TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 18),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMode.signIn,
                    icon: Icon(Icons.login),
                    label: Text('Connexion'),
                  ),
                  ButtonSegment(
                    value: _AuthMode.signUp,
                    icon: Icon(Icons.person_add_alt_1),
                    label: Text('Inscription'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: isBusy
                    ? null
                    : (selection) => onModeChanged(selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                enabled: !isBusy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  labelText: 'E-mail',
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                enabled: !isBusy,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Mot de passe',
                ),
                validator: validatePassword,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isBusy ? null : onSubmit,
                icon: Icon(_isSignUp ? Icons.person_add_alt_1 : Icons.login),
                label: Text(_isSignUp ? 'Creer mon compte' : 'Me connecter'),
              ),
              if (!_isSignUp)
                TextButton(
                  onPressed: isBusy ? null : onPasswordReset,
                  child: const Text('Mot de passe oublié'),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ou',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onGoogle,
                icon: Opacity(
                  opacity: isBusy ? 0.38 : 1,
                  child: Image.asset(
                    'assets/images/google_g_logo.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                label: const Text('Continuer avec Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onApple,
                icon: Icon(
                  Icons.apple,
                  color: isBusy ? AppTheme.mutedText : Colors.white,
                  size: 21,
                ),
                label: const Text('Continuer avec Apple'),
              ),
              if (isBusy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (message != null) ...[
                const SizedBox(height: 14),
                _AuthMessage(message: message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInPanel extends StatelessWidget {
  const _SignedInPanel({
    required this.profile,
    required this.isBusy,
    required this.message,
    required this.onWallpaperChanged,
    required this.onSignOut,
  });

  final AppUserProfile profile;
  final bool isBusy;
  final String? message;
  final ValueChanged<AppWallpaperPreference> onWallpaperChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final title = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!.trim()
        : profile.email ?? 'Compte connecté';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: profile.photoUrl == null
                      ? null
                      : NetworkImage(profile.photoUrl!),
                  child: profile.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email ?? profile.uid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _WallpaperPreferenceSelector(
              selected: profile.wallpaperPreference,
              isBusy: isBusy,
              onChanged: onWallpaperChanged,
            ),
            const SizedBox(height: 18),
            _PremiumStatusBadge(isPremium: profile.isPremium),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              _AuthMessage(message: message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumStatusBadge extends StatelessWidget {
  const _PremiumStatusBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? const Color(0xFF34D399) : AppTheme.gold;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.hourglass_empty,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPremium
                  ? 'Premium actif : les pubs sont masquées.'
                  : 'Premium inactif : les pubs restent affichées.',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _WallpaperPreferenceSelector extends StatelessWidget {
  const _WallpaperPreferenceSelector({
    required this.selected,
    required this.isBusy,
    required this.onChanged,
  });

  final AppWallpaperPreference selected;
  final bool isBusy;
  final ValueChanged<AppWallpaperPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    const choices = AppWallpaperPreference.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fond d\'ecran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 430;
            final children = [
              for (final choice in choices)
                _WallpaperChoiceTile(
                  choice: choice,
                  isSelected: selected == choice,
                  isBusy: isBusy,
                  onTap: () {
                    if (selected != choice) {
                      onChanged(choice);
                    }
                  },
                ),
            ];

            if (isCompact) {
              return Column(
                children: [
                  for (final child in children) ...[
                    child,
                    if (child != children.last) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (final child in children) ...[
                  Expanded(child: child),
                  if (child != children.last) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WallpaperChoiceTile extends StatelessWidget {
  const _WallpaperChoiceTile({
    required this.choice,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
  });

  final AppWallpaperPreference choice;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.gold
        : AppTheme.mutedText.withValues(alpha: 0.28);

    return Semantics(
      button: true,
      selected: isSelected,
      label: choice.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  choice.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
                ColoredBox(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.22 : 0.45,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppTheme.gold : AppTheme.text,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            choice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? AppTheme.gold : AppTheme.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700),
    );
  }
}
