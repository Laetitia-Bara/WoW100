import 'package:flutter/material.dart';

class AuthCallbackPage extends StatelessWidget {
  const AuthCallbackPage({super.key, required this.code, required this.error});

  final String? code;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Retour Battle.net')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCode ? 'Code OAuth reçu ✅' : 'Connexion incomplète',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  hasCode
                      ? 'Code : $code'
                      : 'Erreur : ${error ?? "aucun code reçu"}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
