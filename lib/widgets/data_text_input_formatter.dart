import 'package:flutter/services.dart';

class DataTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final soloNumeri = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();

    for (var i = 0; i < soloNumeri.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }

      buffer.write(soloNumeri[i]);
    }

    final testoFormattato = buffer.toString();

    return TextEditingValue(
      text: testoFormattato,
      selection: TextSelection.collapsed(offset: testoFormattato.length),
    );
  }
}
