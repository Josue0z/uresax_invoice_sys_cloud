import 'dart:convert';
import 'package:currency_formatter/currency_formatter.dart';
import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}


CurrencyFormat dopSettings = CurrencyFormat(
  symbol: 'RD',
  symbolSide: SymbolSide.left,
  thousandSeparator: ',',
  decimalSeparator: '.',
  symbolSeparator: ' \$',
);

CurrencyFormat usSettings = CurrencyFormat(
  symbol: 'US',
  symbolSide: SymbolSide.left,
  thousandSeparator: ',',
  decimalSeparator: '.',
  symbolSeparator: ' \$',
);
CurrencyFormat defaultSettings = CurrencyFormat(
    symbol: '',
    symbolSide: SymbolSide.left,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolSeparator: ' \$');


extension DopFormatterExtension on double {
  toDop() {
    return CurrencyFormatter.format(this, dopSettings, enforceDecimals: true);
  }

  toUS() {
    return CurrencyFormatter.format(this, usSettings, enforceDecimals: true);
  }

  toCoin() {
    return CurrencyFormatter.format(this, defaultSettings,
        enforceDecimals: true);
  }
}

extension TextCustomFormatter on String {

String formatPatterns(String pattern) {
  // Limpiamos la entrada de separadores
  var cleanInput = replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  var inputChars = cleanInput.split('');

  var result = StringBuffer();
  int index = 0;

  for (var char in pattern.split('')) {
    if (char == '#') {
      if (index < inputChars.length) {
        result.write(inputChars[index]);
        index++;
      } else {
        // Si faltan caracteres, dibujamos el símbolo #
        result.write('#');
      }
    } else {
      // Copiamos cualquier otro carácter del patrón (ej. guion, espacio, etc.)
      result.write(char);
    }
  }

  return result.toString();
}

}



class CustomLatinCodec extends Codec<String, List<int>> {
  @override
  Converter<String, List<int>> get encoder => _CustomLatinEncoder();

  @override
  Converter<List<int>, String> get decoder => latin1.decoder;
}

class _CustomLatinEncoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String input) {
    final bytes = <int>[];
    for (var rune in input.runes) {
      switch (rune) {
        case 0x00F1: // ñ
          bytes.add(0xA4); // código que tu impresora espera
          break;
        case 0x00E1: // á
          bytes.add(0xA0);
          break;
        case 0x00E9: // é
          bytes.add(0x82);
          break;
        case 0x00ED: // í
          bytes.add(0xA1);
          break;
        case 0x00F3: // ó
          bytes.add(0xA2);
          break;
        case 0x00FA: // ú
          bytes.add(0xA3);
          break;
        default:
          bytes.add(rune < 256 ? rune : 63); // 63 = '?'
      }
    }
    return Uint8List.fromList(bytes);
  }
}
