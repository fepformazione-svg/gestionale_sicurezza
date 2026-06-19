import 'package:flutter/material.dart';

class AttrezzaturePage extends StatelessWidget {
  const AttrezzaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attrezzature'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.construction_rounded,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gestione attrezzature',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sezione predisposta per gestire attrezzature, materiali, DPI, dotazioni didattiche e strumenti usati nei corsi.',
                        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
