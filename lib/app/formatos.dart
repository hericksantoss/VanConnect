/// Formatação simples em pt-BR, sem dependências externas.
library;

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];
const _mesesCurtos = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
const _diasSemana = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

String moeda(double valor) {
  final negativo = valor < 0;
  final centavos = (valor.abs() * 100).round();
  final inteiro = (centavos ~/ 100).toString();
  final resto = (centavos % 100).toString().padLeft(2, '0');
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return '${negativo ? '-' : ''}R\$ $buffer,$resto';
}

String doisDigitos(int n) => n.toString().padLeft(2, '0');

/// Minutos desde meia-noite → "06:40".
String horario(int minutos) => '${doisDigitos(minutos ~/ 60)}:${doisDigitos(minutos % 60)}';

String hora(DateTime d) => '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

String dataCurta(DateTime d) => '${doisDigitos(d.day)}/${doisDigitos(d.month)}';

String dataExtenso(DateTime d) => '${_diasSemana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

String mesAno(DateTime d) => '${_meses[d.month - 1]} ${d.year}';

String mesCurto(DateTime d) => _mesesCurtos[d.month - 1];

String capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

String primeiroNome(String nome) => nome.trim().split(' ').first;

String saudacao(DateTime agora) {
  if (agora.hour < 12) return 'Bom dia';
  if (agora.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
