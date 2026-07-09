import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/backup_service.dart';

class BackupDatabasePage extends StatefulWidget {
  const BackupDatabasePage({super.key});

  @override
  State<BackupDatabasePage> createState() => _BackupDatabasePageState();
}

class _BackupDatabasePageState extends State<BackupDatabasePage> {
  bool backupLocaleInCorso = false;
  bool backupSecondarioInCorso = false;
  String? ultimoBackupCreato;
  String? ultimoBackupSecondarioCreato;

  Future<void> eseguiBackupManuale() async {
    setState(() {
      backupLocaleInCorso = true;
    });

    final percorsoBackup = await BackupService.eseguiBackupManuale();

    if (!mounted) return;

    setState(() {
      backupLocaleInCorso = false;
      ultimoBackupCreato = percorsoBackup;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: percorsoBackup == null
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        content: Text(
          percorsoBackup == null
              ? 'Backup non eseguito. Verificare che il database esista.'
              : 'Backup creato correttamente.',
        ),
      ),
    );
  }

  Future<void> scegliCartellaBackupSecondario() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory == null) return;

      await BackupService.salvaPercorsoBackupSecondario(selectedDirectory);

      if (!mounted) return;

      setState(() {
        ultimoBackupSecondarioCreato = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('Cartella backup secondario configurata.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Errore configurazione backup secondario: $e'),
        ),
      );
    }
  }

  Future<void> rimuoviCartellaBackupSecondario() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rimuovere backup secondario?'),
          content: const Text(
            'Verrà rimossa solo la configurazione del percorso. I backup già creati nella cartella secondaria non saranno eliminati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Rimuovi'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    await BackupService.rimuoviPercorsoBackupSecondario();

    if (!mounted) return;

    setState(() {
      ultimoBackupSecondarioCreato = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFF97316),
        content: Text('Configurazione backup secondario rimossa.'),
      ),
    );
  }

  Future<void> eseguiBackupSecondario() async {
    setState(() {
      backupSecondarioInCorso = true;
    });

    final risultato = await BackupService.eseguiBackupSecondarioManuale();

    if (!mounted) return;

    setState(() {
      backupSecondarioInCorso = false;
      ultimoBackupSecondarioCreato = risultato.percorsoFile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: risultato.riuscito
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
        content: Text(risultato.messaggio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _BackupDatabaseInfo.carica();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Backup e database'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderBackupCard(
            databaseEsistente: info.databaseEsistente,
            dimensioneDatabase: _formattaBytes(info.dimensioneDatabaseBytes),
            ultimaModifica: _formattaDataOra(info.ultimaModificaDatabase),
          ),
          const SizedBox(height: 16),
          _PercorsoCard(
            icona: Icons.storage_rounded,
            titolo: 'Database operativo',
            descrizione: 'File SQLite attualmente usato dal gestionale.',
            percorso: info.percorsoDatabase,
            evidenziato: true,
          ),
          const SizedBox(height: 12),
          _PercorsoCard(
            icona: Icons.backup_rounded,
            titolo: 'Cartella backup',
            descrizione:
                'Destinazione dei backup automatici e del backup manuale.',
            percorso: info.percorsoBackup,
          ),
          const SizedBox(height: 12),
          _PercorsoCard(
            icona: Icons.folder_copy_rounded,
            titolo: 'Cartella export',
            descrizione:
                'Cartella prevista per esportazioni, documenti e file prodotti.',
            percorso: info.percorsoExport,
          ),
          const SizedBox(height: 16),
          _AzioneBackupCard(
            backupInCorso: backupLocaleInCorso,
            backupDisponibile: info.databaseEsistente,
            onBackup: eseguiBackupManuale,
            ultimoBackupCreato: ultimoBackupCreato,
          ),
          const SizedBox(height: 16),
          _BackupSecondarioCard(
            backupInCorso: backupSecondarioInCorso,
            backupDisponibile: info.databaseEsistente,
            percorso: info.percorsoBackupSecondario,
            raggiungibile: info.backupSecondarioRaggiungibile,
            onScegliCartella: scegliCartellaBackupSecondario,
            onRimuoviCartella: rimuoviCartellaBackupSecondario,
            onBackupSecondario: eseguiBackupSecondario,
            ultimoBackupCreato: ultimoBackupSecondarioCreato,
          ),
          const SizedBox(height: 16),
          const _AvvisoRipristinoCard(),
        ],
      ),
    );
  }

  String _formattaBytes(int? bytes) {
    if (bytes == null) return 'Non disponibile';

    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    }

    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  String _formattaDataOra(DateTime? data) {
    if (data == null) return 'Non disponibile';

    final giorno = data.day.toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final anno = data.year.toString();
    final ora = data.hour.toString().padLeft(2, '0');
    final minuti = data.minute.toString().padLeft(2, '0');

    return '$giorno/$mese/$anno $ora:$minuti';
  }
}

class _BackupDatabaseInfo {
  final String? percorsoBase;
  final String? percorsoDatabase;
  final String? percorsoBackup;
  final String? percorsoExport;
  final String? percorsoBackupSecondario;
  final bool backupSecondarioRaggiungibile;
  final bool databaseEsistente;
  final int? dimensioneDatabaseBytes;
  final DateTime? ultimaModificaDatabase;

  const _BackupDatabaseInfo({
    required this.percorsoBase,
    required this.percorsoDatabase,
    required this.percorsoBackup,
    required this.percorsoExport,
    required this.percorsoBackupSecondario,
    required this.backupSecondarioRaggiungibile,
    required this.databaseEsistente,
    required this.dimensioneDatabaseBytes,
    required this.ultimaModificaDatabase,
  });

  factory _BackupDatabaseInfo.carica() {
    return _BackupDatabaseInfo(
      percorsoBase: BackupService.percorsoBase(),
      percorsoDatabase: BackupService.percorsoDatabase(),
      percorsoBackup: BackupService.percorsoBackup(),
      percorsoExport: BackupService.percorsoExport(),
      percorsoBackupSecondario:
          BackupService.percorsoBackupSecondarioConfigurato(),
      backupSecondarioRaggiungibile:
          BackupService.backupSecondarioRaggiungibile(),
      databaseEsistente: BackupService.databaseEsistente(),
      dimensioneDatabaseBytes: BackupService.dimensioneDatabaseBytes(),
      ultimaModificaDatabase: BackupService.ultimaModificaDatabase(),
    );
  }
}

class _HeaderBackupCard extends StatelessWidget {
  final bool databaseEsistente;
  final String dimensioneDatabase;
  final String ultimaModifica;

  const _HeaderBackupCard({
    required this.databaseEsistente,
    required this.dimensioneDatabase,
    required this.ultimaModifica,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: databaseEsistente
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              databaseEsistente
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: databaseEsistente
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stato database operativo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  databaseEsistente
                      ? 'Database trovato. Backup manuale disponibile.'
                      : 'Database non trovato nel percorso previsto.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoBadge(
                      label: 'Dimensione',
                      valore: dimensioneDatabase,
                      icona: Icons.data_object_rounded,
                    ),
                    _InfoBadge(
                      label: 'Ultima modifica',
                      valore: ultimaModifica,
                      icona: Icons.schedule_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercorsoCard extends StatelessWidget {
  final IconData icona;
  final String titolo;
  final String descrizione;
  final String? percorso;
  final bool evidenziato;

  const _PercorsoCard({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    required this.percorso,
    this.evidenziato = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: evidenziato
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icona, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descrizione,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SelectableText(
                    percorso ?? 'Percorso non disponibile',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AzioneBackupCard extends StatelessWidget {
  final bool backupInCorso;
  final bool backupDisponibile;
  final VoidCallback onBackup;
  final String? ultimoBackupCreato;

  const _AzioneBackupCard({
    required this.backupInCorso,
    required this.backupDisponibile,
    required this.onBackup,
    required this.ultimoBackupCreato,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup manuale',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF14532D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea una copia del database operativo nella cartella Backup. Il database originale non viene modificato.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: backupDisponibile && !backupInCorso ? onBackup : null,
            icon: backupInCorso
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.backup_rounded),
            label: Text(
              backupInCorso ? 'Backup in corso...' : 'Esegui backup manuale',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (ultimoBackupCreato != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Ultimo backup creato:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14532D),
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              ultimoBackupCreato!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackupSecondarioCard extends StatelessWidget {
  final bool backupInCorso;
  final bool backupDisponibile;
  final String? percorso;
  final bool raggiungibile;
  final VoidCallback onScegliCartella;
  final VoidCallback onRimuoviCartella;
  final VoidCallback onBackupSecondario;
  final String? ultimoBackupCreato;

  const _BackupSecondarioCard({
    required this.backupInCorso,
    required this.backupDisponibile,
    required this.percorso,
    required this.raggiungibile,
    required this.onScegliCartella,
    required this.onRimuoviCartella,
    required this.onBackupSecondario,
    required this.ultimoBackupCreato,
  });

  @override
  Widget build(BuildContext context) {
    final configurato = percorso != null && percorso!.trim().isNotEmpty;

    final statoTesto = !configurato
        ? 'Non configurato'
        : raggiungibile
        ? 'Configurato e raggiungibile'
        : 'Configurato ma non raggiungibile';

    final statoColore = !configurato
        ? const Color(0xFFF97316)
        : raggiungibile
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup secondario configurabile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Permette una seconda copia del database operativo su NAS, disco esterno o cartella protetta. Il percorso viene salvato localmente e può essere cambiato in qualsiasi momento.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoBadge(
                label: 'Stato',
                valore: statoTesto,
                icona: configurato && raggiungibile
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  configurato
                      ? raggiungibile
                            ? 'NAS/cartella OK'
                            : 'NAS/cartella non raggiungibile'
                      : 'Percorso da scegliere',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: statoColore,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: SelectableText(
              percorso ?? 'Nessuna cartella secondaria configurata',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: backupInCorso ? null : onScegliCartella,
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(
                  configurato ? 'Cambia cartella' : 'Scegli cartella',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: configurato && !backupInCorso
                    ? onRimuoviCartella
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Rimuovi configurazione'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    backupDisponibile &&
                        configurato &&
                        raggiungibile &&
                        !backupInCorso
                    ? onBackupSecondario
                    : null,
                icon: backupInCorso
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  backupInCorso
                      ? 'Backup secondario in corso...'
                      : 'Esegui backup secondario',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          if (ultimoBackupCreato != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Ultimo backup secondario creato:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              ultimoBackupCreato!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvvisoRipristinoCard extends StatelessWidget {
  const _AvvisoRipristinoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ripristino database non disponibile da questa schermata. Il ripristino resta una procedura manuale controllata, da eseguire solo dopo verifica del backup e chiusura del gestionale.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String valore;
  final IconData icona;

  const _InfoBadge({
    required this.label,
    required this.valore,
    required this.icona,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            valore,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
