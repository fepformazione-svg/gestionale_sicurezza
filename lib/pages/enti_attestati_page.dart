import 'package:flutter/material.dart';

class EntiAttestatiPage extends StatelessWidget {
  const EntiAttestatiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enti rilascio attestati')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 42,
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestione enti rilascio attestati',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Archivio degli enti, organismi o soggetti che rilasciano attestati, certificazioni o documentazione formativa.',
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'In questa sezione saranno gestiti denominazione, tipologia, riferimenti, note e stato attivo/non attivo.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pagina predisposta. La tabella operativa sarà aggiunta nello step successivo.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
