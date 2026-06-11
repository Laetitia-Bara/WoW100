import 'package:flutter/material.dart';

import '../../../../core/services/battle_net_token_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/repositories/battle_net_repository.dart';
import 'auth_page.dart';
import 'character_selection_page.dart';

class CharacterSwitchPage extends StatefulWidget {
  const CharacterSwitchPage({super.key});

  @override
  State<CharacterSwitchPage> createState() => _CharacterSwitchPageState();
}

class _CharacterSwitchPageState extends State<CharacterSwitchPage> {
  final BattleNetRepository _repository = BattleNetRepository();
  final BattleNetTokenService _tokenService = BattleNetTokenService();

  bool _isLoading = true;
  String? _error;
  List<WowCharacter> _characters = [];

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _tokenService.loadToken();

      if (token == null || token.isEmpty) {
        throw Exception('Compte Battle.net non connecte.');
      }

      final characters = await _repository.getCharacters(token);

      if (!mounted) return;

      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes personnage')),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Connexion Battle.net requise',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Reconnecter Battle.net'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CharacterSelectionPage(characters: _characters);
  }
}
