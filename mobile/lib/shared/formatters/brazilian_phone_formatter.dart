import 'package:flutter/services.dart';

/// Exibe telefones brasileiros com DDD sem alterar o valor persistido.
///
/// Exemplos:
/// - 1133334444 -> (11) 3333-4444
/// - 11999998888 -> (11) 99999-8888
class BrazilianPhoneFormatter extends TextInputFormatter {
  const BrazilianPhoneFormatter();

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String format(String value) {
    final unboundedDigits = digitsOnly(value);
    final digits = unboundedDigits.length > 11
        ? unboundedDigits.substring(0, 11)
        : unboundedDigits;

    if (digits.isEmpty) return '';
    if (digits.length <= 2) return '($digits';

    final areaCode = digits.substring(0, 2);
    final number = digits.substring(2);

    if (number.length <= 4) {
      return '($areaCode) $number';
    }

    final firstPartLength = digits.length == 11 ? 5 : 4;
    final firstPart = number.substring(0, firstPartLength);
    final secondPart = number.substring(firstPartLength);

    return '($areaCode) $firstPart-$secondPart';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOnly(newValue.text);

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final formatted = format(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
