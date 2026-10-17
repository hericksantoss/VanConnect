/// Validações de documentos brasileiros usadas nos cadastros.
library;

String soNumeros(String s) => s.replaceAll(RegExp(r'\D'), '');

/// CPF com dígitos verificadores corretos (e não todos iguais).
bool cpfValido(String bruto) {
  final d = soNumeros(bruto);
  if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
  int digito(int ate) {
    var soma = 0;
    for (var i = 0; i < ate; i++) {
      soma += int.parse(d[i]) * (ate + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digito(9) == int.parse(d[9]) && digito(10) == int.parse(d[10]);
}

String formatarCpf(String bruto) {
  final d = soNumeros(bruto);
  if (d.length != 11) return bruto;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

/// Placa antiga (ABC1234) ou Mercosul (ABC1D23).
bool placaValida(String bruto) {
  final p = bruto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return RegExp(r'^[A-Z]{3}\d[A-Z0-9]\d{2}$').hasMatch(p);
}

String formatarPlaca(String bruto) {
  final p = bruto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (p.length != 7) return bruto.toUpperCase();
  // Mercosul fica sem traço; a antiga ganha traço.
  return RegExp(r'^[A-Z]{3}\d{4}$').hasMatch(p) ? '${p.substring(0, 3)}-${p.substring(3)}' : p;
}

bool telefoneValido(String bruto) {
  final d = soNumeros(bruto);
  return d.length == 10 || d.length == 11;
}

bool emailValido(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());
