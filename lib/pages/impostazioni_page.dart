import 'package:flutter/material.dart';
import 'dati_azienda_page.dart';
import 'medici_strutture_page.dart';
import 'visite_mediche_page.dart';
import 'docenti_page.dart';
import 'aule_sedi_page.dart';
import 'attrezzature_page.dart';
import 'enti_attestati_page.dart';
import 'privacy_gdpr_page.dart';
import 'utenti_ruoli_page.dart';
import 'login_page.dart';

import '../services/app_database.dart';
import '../services/sessione_utente_service.dart';

class ImpostazioniPage extends StatelessWidget {
  const ImpostazioniPage({super.key});

  Future<void> apriUtentiRuoliSeAutorizzato(BuildContext context) async {
    final sessione = SessioneUtenteService.instance;

    if (!sessione.utenteLoggato) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      if (!context.mounted) return;
    }

    final ruoli = await AppDatabase.instance.getRuoliUtenti(soloAttivi: false);

    final autorizzato = SessioneUtenteService.instance.puoGestireUtenti(ruoli);

    if (!context.mounted) return;

    if (!autorizzato) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Area riservata agli utenti con ruolo Amministratore.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UtentiRuoliPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SezioneImpostazioniCard(
            icona: Icons.business_rounded,
            titolo: 'Dati azienda',
            descrizione:
                'Gestione intestazione aziendale, recapiti, riferimenti fiscali e dati usati negli export.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DatiAziendaPage()),
              );
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.medical_services_rounded,
            titolo: 'Medici / Strutture mediche',
            descrizione:
                'Anagrafica medici competenti e strutture per visite mediche del lavoro.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MediciStrutturePage()),
              );
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.health_and_safety_rounded,
            titolo: 'Visite mediche',
            descrizione:
                'Gestione visite mediche, idoneità, scadenze e storico sanitario dei discenti.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VisiteMedichePage()),
              );
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.school_rounded,
            titolo: 'Docenti',
            descrizione:
                'Lista docenti e futura associazione ai corsi o alle edizioni svolte.',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DocentiPage()));
            },
          ),
          _SezioneImpostazioniCard(
            icona: Icons.meeting_room_rounded,
            titolo: 'Aule / Sedi formative',
            descrizione:
                'Gestisci aule, campi prova e sedi cliente per i corsi.',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AuleSediPage()));
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.construction_rounded,
            titolo: 'Attrezzature',
            descrizione:
                'Gestisci attrezzature, materiali, DPI e dotazioni usate nei corsi.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttrezzaturePage()),
              );
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.workspace_premium_rounded,
            titolo: 'Enti rilascio attestati',
            descrizione:
                'Anagrafica degli enti che rilasciano attestati o certificazioni.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EntiAttestatiPage()),
              );
            },
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.privacy_tip_rounded,
            titolo: 'Privacy / GDPR 679/2016',
            descrizione:
                'Informativa sul trattamento dei dati, consensi privacy e futura gestione GDPR.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyGdprPage()),
              );
            },
          ),

          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.admin_panel_settings_rounded,
            titolo: 'Utenti e Ruoli',
            descrizione:
                'Area riservata agli amministratori per gestione utenti, ruoli, accessi e permessi.',
            onTap: () => apriUtentiRuoliSeAutorizzato(context),
          ),
          SizedBox(height: 12),
          _SezioneImpostazioniCard(
            icona: Icons.storage_rounded,
            titolo: 'Backup e database',
            descrizione:
                'Percorsi database, backup, esportazioni e future impostazioni tecniche.',
          ),
        ],
      ),
    );
  }
}

class _SezioneImpostazioniCard extends StatelessWidget {
  final IconData icona;
  final String titolo;
  final String descrizione;
  final VoidCallback? onTap;

  const _SezioneImpostazioniCard({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icona, color: const Color(0xFF2563EB)),
        ),
        title: Text(
          titolo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            descrizione,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.3),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
