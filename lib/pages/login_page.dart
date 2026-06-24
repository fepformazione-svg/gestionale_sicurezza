import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/sessione_utente_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.loginObbligatorio = false});

  final bool loginObbligatorio;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool caricamento = false;
  bool mostraPassword = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> eseguiLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserire username e password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      caricamento = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final risultato = await AuthService.instance.verificaCredenziali(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (risultato.ok && risultato.utente != null) {
        SessioneUtenteService.instance.impostaUtenteCorrente(risultato.utente!);

        messenger.showSnackBar(
          SnackBar(
            content: Text(risultato.messaggio),
            backgroundColor: Colors.green,
          ),
        );

        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(risultato.messaggio),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Errore durante il login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          caricamento = false;
        });
      }
    }
  }

  void chiudiSenzaLogin() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final puoChiudere = !widget.loginObbligatorio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accesso gestionale'),
        automaticallyImplyLeading: puoChiudere,
        actions: [
          if (puoChiudere)
            TextButton.icon(
              onPressed: caricamento ? null : chiudiSenzaLogin,
              icon: const Icon(Icons.close),
              label: const Text('Chiudi'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 56,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login utente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pagina preparatoria: il login è già funzionante, ma non è ancora obbligatorio all’avvio del gestionale.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: usernameController,
                      enabled: !caricamento,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      enabled: !caricamento,
                      obscureText: !mostraPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (!caricamento) {
                          eseguiLogin();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: mostraPassword
                              ? 'Nascondi password'
                              : 'Mostra password',
                          icon: Icon(
                            mostraPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: caricamento
                              ? null
                              : () {
                                  setState(() {
                                    mostraPassword = !mostraPassword;
                                  });
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: caricamento ? null : eseguiLogin,
                      icon: caricamento
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(caricamento ? 'Accesso...' : 'Accedi'),
                    ),
                    if (puoChiudere) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: caricamento ? null : chiudiSenzaLogin,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Torna al gestionale'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
