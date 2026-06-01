import 'package:flutter/material.dart';

import '../../../../data/models/wow_character.dart';
import '../../../../data/repositories/battle_net_repository.dart';
import 'character_selection_page.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key, required this.code, required this.error});

  final String? code;
  final String? error;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  final BattleNetRepository _repository = BattleNetRepository();

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

      final token = await _repository.exchangeCodeForToken(code);
      final characters = await _repository.getCharacters(token);

      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
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
        appBar: AppBar(title: const Text('Retour Battle.net')),
        body: Padding(padding: const EdgeInsets.all(18), child: Text(_error!)),
      );
    }

    return CharacterSelectionPage(characters: _characters);
  }
}
