import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/discente.dart';
import '../widgets/data_text_input_formatter.dart';

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

Future<bool> apriDialogDiscente({
  required BuildContext context,
  Discente? discente,
  int? impresaIdPreselezionata,
}) async {
  final imprese = await DatabaseService.instance.getImprese();

  if (!context.mounted) return false;

  final bool modifica = discente != null;

  final nomeController = TextEditingController(text: discente?.nome ?? '');
  final cognomeController = TextEditingController(
    text: discente?.cognome ?? '',
  );
  final luogoController = TextEditingController(
    text: discente?.luogoNascita ?? '',
  );
  final dataController = TextEditingController(
    text: discente?.dataNascita ?? '',
  );
  final cfController = TextEditingController(
    text: discente?.codiceFiscale ?? '',
  );

  final dataVisitaController = TextEditingController(
    text: discente?.dataVisitaMedica ?? '',
  );
  final scadenzaVisitaController = TextEditingController(
    text: discente?.scadenzaVisitaMedica ?? '',
  );

  bool visitaMedicaSvolta = discente?.visitaMedicaSvolta == 1;

  int? impresaId = discente?.impresaId ?? impresaIdPreselezionata;

  final salvato = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(modifica ? 'Modifica discente' : 'Nuovo discente'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cognomeController,
                            decoration: _inputDecoration('Cognome *'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nomeController,
                            decoration: _inputDecoration('Nome *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: luogoController,
                            decoration: _inputDecoration('Luogo nascita'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: dataController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [DataTextInputFormatter()],
                            decoration: _inputDecoration('Data nascita'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cfController,
                      decoration: _inputDecoration('Codice fiscale'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: impresaId,
                      decoration: _inputDecoration('Impresa'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Nessuna impresa'),
                        ),
                        ...imprese.map(
                          (impresa) => DropdownMenuItem<int?>(
                            value: impresa.id,
                            child: Text(impresa.nome),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          impresaId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: visitaMedicaSvolta,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visita medica svolta'),
                      onChanged: (value) {
                        setDialogState(() {
                          visitaMedicaSvolta = value ?? false;
                        });
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dataVisitaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [DataTextInputFormatter()],
                            decoration: _inputDecoration('Data visita'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: scadenzaVisitaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [DataTextInputFormatter()],
                            decoration: _inputDecoration('Scadenza visita'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salva'),
                onPressed: () async {
                  final nome = nomeController.text.trim();
                  final cognome = cognomeController.text.trim();

                  if (nome.isEmpty || cognome.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nome e cognome sono obbligatori'),
                      ),
                    );
                    return;
                  }

                  final nuovoDiscente = Discente(
                    id: discente?.id,
                    nome: nome,
                    cognome: cognome,
                    luogoNascita: luogoController.text.trim(),
                    dataNascita: dataController.text.trim(),
                    codiceFiscale: cfController.text.trim(),
                    impresaId: impresaId,
                    visitaMedicaSvolta: visitaMedicaSvolta ? 1 : 0,
                    dataVisitaMedica: dataVisitaController.text.trim(),
                    scadenzaVisitaMedica: scadenzaVisitaController.text.trim(),
                  );

                  if (modifica) {
                    await DatabaseService.instance.updateDiscente(
                      nuovoDiscente,
                    );
                  } else {
                    await DatabaseService.instance.insertDiscente(
                      nuovoDiscente,
                    );
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        },
      );
    },
  );

  if (!context.mounted) return false;

  return salvato == true;
}
