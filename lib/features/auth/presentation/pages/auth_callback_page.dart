import 'package:flutter/material.dart';
import 'package:wow100/core/services/battle_net_token_service.dart';

import '../../../../core/services/selected_character_service.dart';
import '../../../../data/models/wow_character.dart';
import '../../../../data/repositories/battle_net_repository.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import 'character_selection_page.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key, required this.code, required this.error});

  final String? code;
  final String? error;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  static final Map<String, Future<List<WowCharacter>>> _charactersByCode = {};

  final BattleNetRepository _repository = BattleNetRepository();
  final BattleNetTokenService _tokenService = BattleNetTokenService();
  final SelectedCharacterService _selectedCharacterService =
      SelectedCharacterService();

  bool _isLoading = true;
  String? _error;
  List<WowCharacter> _characters = [];

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    try {
      if (widget.error != null) {
        throw Exception(widget.error);
      }

      final code = widget.code;
      if (code == null || code.isEmpty) {
        throw Exception('Aucun code OAuth reçu.');
      }

      final characters = await _loadCharactersForCode(code);

      if (!mounted) return;

      final selectedCharacter = await _matchingSelectedCharacter(characters);
      if (selectedCharacter != null) {
        await _selectedCharacterService.saveCharacter(selectedCharacter);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
        return;
      }

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

  Future<List<WowCharacter>> _loadCharactersForCode(String code) {
    final existingLoad = _charactersByCode[code];
    if (existingLoad != null) {
      return existingLoad;
    }

    final load = _exchangeCodeAndLoadCharacters(code).catchError((error) async {
      _charactersByCode.remove(code);

      if (_isConsumedAuthorizationCodeError(error)) {
        final token = await _tokenService.loadToken();
        if (token != null) {
          return _repository.getCharacters(token);
        }
      }

      throw error;
    });

    _charactersByCode[code] = load;
    return load;
  }

  Future<List<WowCharacter>> _exchangeCodeAndLoadCharacters(String code) async {
    final authResult = await _repository.exchangeCodeForToken(code);
    await _tokenService.saveAuthResult(authResult);
    return _repository.getCharacters(authResult.accessToken);
  }

  Future<WowCharacter?> _matchingSelectedCharacter(
    List<WowCharacter> characters,
  ) async {
    final selectedCharacter = await _selectedCharacterService.loadCharacter();
    if (selectedCharacter == null) {
      return null;
    }

    for (final character in characters) {
      if (character.name == selectedCharacter.name &&
          character.realmSlug == selectedCharacter.realmSlug) {
        return character;
      }
    }

    return null;
  }

  bool _isConsumedAuthorizationCodeError(Object error) {
    return error.toString().contains('invalid_grant');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Retour Battle.net')),
        body: Padding(padding: const EdgeInsets.all(18), child: Text(_error!)),
      );
    }

    return CharacterSelectionPage(characters: _characters);
  }
}
