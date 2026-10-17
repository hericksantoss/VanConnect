import 'package:flutter/services.dart';

/// Máscara de números enquanto digita: cada `#` é um dígito.
class Mascara extends TextInputFormatter {
  Mascara(this.padroes);

  /// Um ou mais padrões; usa o primeiro que comporta a quantidade de dígitos.
  final List<String> padroes;

  static final cpf = Mascara(['###.###.###-##']);
  static final telefone = Mascara(['(##) ####-####', '(##) #####-####']);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final maximo = padroes.map((p) => '#'.allMatches(p).length).reduce((a, b) => a > b ? a : b);
    final d = digitos.length > maximo ? digitos.substring(0, maximo) : digitos;
    final padrao = padroes.firstWhere((p) => '#'.allMatches(p).length >= d.length, orElse: () => padroes.last);

    final saida = StringBuffer();
    var i = 0;
    for (final ch in padrao.split('')) {
      if (i >= d.length) break;
      if (ch == '#') {
        saida.write(d[i++]);
      } else {
        saida.write(ch);
      }
    }
    final t = saida.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Placa: só letras e números, em maiúsculas, até 7 caracteres.
class MascaraPlaca extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var t = novo.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (t.length > 7) t = t.substring(0, 7);
    // Placa antiga ganha o traço (ABC-1234); Mercosul fica junta (ABC1D23).
    if (t.length > 3 && RegExp(r'^[A-Z]{3}\d{1,4}$').hasMatch(t) && (t.length < 5 || RegExp(r'^\d$').hasMatch(t[4]))) {
      t = '${t.substring(0, 3)}-${t.substring(3)}';
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
