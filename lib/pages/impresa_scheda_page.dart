import 'package:flutter/material.dart';

import '../models/impresa.dart';

class ImpresaSchedaPage extends StatelessWidget {
  final Impresa impresa;

  const ImpresaSchedaPage({
    super.key,
    required this.impresa,
  });

  String valore(String? testo) {
    final v = testo?.trim() ?? '';
    return v.isEmpty ? '-' : v;
  }

  void modificaImpresa(BuildContext context) {
    Navigator.pop(context, 'modifica');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Scheda impresa'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Modifica impresa',
            onPressed: () => modificaImpresa(context),
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                impresa.intestazione,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anagrafica aziendale',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),

              _InfoRiga(
                label: 'Partita IVA',
                value: valore(impresa.partitaIva),
              ),
              _InfoRiga(
                label: 'Codice fiscale',
                value: valore(impresa.codiceFiscale),
              ),
              _InfoRiga(
                label: 'Referente',
                value: valore(impresa.referente),
              ),
              _InfoRiga(
                label: 'Telefono',
                value: valore(impresa.telefono),
              ),
              _InfoRiga(
                label: 'Indirizzo',
                value: valore(impresa.indirizzo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRiga extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRiga({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}