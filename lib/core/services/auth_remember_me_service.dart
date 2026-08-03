import 'package:shared_preferences/shared_preferences.dart';

class RememberedAuthInfo {
  const RememberedAuthInfo({required this.rememberMe, this.email});

  final bool rememberMe;
  final String? email;
}

class AuthRememberMeService {
  static const _rememberMeKey = 'auth_remember_me';
  static const _emailKey = 'auth_remembered_email';

  Future<RememberedAuthInfo> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_emailKey)?.trim();

    return RememberedAuthInfo(
      rememberMe: rememberMe,
      email: rememberMe == true && email != null && email.isNotEmpty
          ? email
          : null,
    );
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedEmail = email.trim();

    await prefs.setBool(_rememberMeKey, true);
    if (trimmedEmail.isEmpty) {
      await prefs.remove(_emailKey);
      return;
    }

    await prefs.setString(_emailKey, trimmedEmail);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_emailKey);
  }
}
