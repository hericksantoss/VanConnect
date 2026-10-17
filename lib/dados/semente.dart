import 'dart:ui' show Offset;

import '../dominio/modelos.dart';

/// Dados fictícios de demonstração. Nenhum dado real.
class Semente {
  static List<Escola> get escolas => [
    Escola(
      id: 'e1',
      nome: 'Colégio Horizonte',
      endereco: 'Av. das Palmeiras, 1200',
      entrada: 7 * 60 + 30,
      saida: 12 * 60 + 30,
      posicao: const Offset(0.80, 0.18),
    ),
    Escola(
      id: 'e2',
      nome: 'Escola Ipê Amarelo',
      endereco: 'Rua dos Girassóis, 88',
      entrada: 13 * 60,
      saida: 17 * 60 + 30,
      posicao: const Offset(0.60, 0.10),
    ),
  ];

  static Veiculo get veiculo => Veiculo(
    id: 'v1',
    apelido: 'Amarelinha',
    modelo: 'Sprinter 416 · 2022',
    placa: 'EMB-2A26',
    capacidade: 16,
    motorista: 'Rogério Nunes',
  );

  /// Van reserva do mesmo motorista (não é compartilhada com ninguém).
  static Veiculo get veiculo2 =>
      Veiculo(id: 'v2', apelido: 'Reserva', modelo: 'Master Escolar · 2021', placa: 'VNC-7B31', capacidade: 15, motorista: 'Rogério Nunes');

  static List<Aluno> alunos() {
    Aluno a(
      String id,
      String nome,
      String serie,
      String escola,
      Turno turno,
      Responsavel r,
      String end,
      Offset pos,
      double valor,
      int venc,
      DateTime nasc, [
      String cuidados = '',
    ]) => Aluno(
      id: id,
      nome: nome,
      serie: serie,
      escolaId: escola,
      turno: turno,
      responsavel: r,
      endereco: end,
      posicao: pos,
      valorMensal: valor,
      diaVencimento: venc,
      nascimento: nasc,
      cuidados: cuidados,
    );

    final hoje = DateTime.now();
    final mariana = const Responsavel(nome: 'Mariana Costa', telefone: '(11) 98888-1020', parentesco: 'Mãe');

    return [
      a(
        'a1',
        'Lucas Costa',
        '4º ano',
        'e1',
        Turno.manha,
        mariana,
        'Rua Aurora, 45',
        const Offset(0.18, 0.70),
        320,
        5,
        DateTime(2016, 3, 12),
        'Alergia a amendoim',
      ),
      a(
        'a2',
        'Helena Costa',
        '1º ano',
        'e1',
        Turno.manha,
        mariana,
        'Rua Aurora, 45',
        const Offset(0.18, 0.70),
        300,
        5,
        DateTime(2019, hoje.month, (hoje.day + 2).clamp(1, 28)),
      ),
      a(
        'a3',
        'Theo Almeida',
        '3º ano',
        'e1',
        Turno.manha,
        const Responsavel(nome: 'Rafael Almeida', telefone: '(11) 97777-3344', parentesco: 'Pai'),
        'Rua do Sol, 310',
        const Offset(0.30, 0.78),
        320,
        10,
        DateTime(2017, 8, 2),
      ),
      a(
        'a4',
        'Valentina Rocha',
        '5º ano',
        'e1',
        Turno.manha,
        const Responsavel(nome: 'Juliana Rocha', telefone: '(11) 96666-2211', parentesco: 'Mãe'),
        'Travessa Lua, 12',
        const Offset(0.42, 0.62),
        320,
        10,
        DateTime(2015, 11, 23),
      ),
      a(
        'a5',
        'Miguel Santos',
        '2º ano',
        'e1',
        Turno.manha,
        const Responsavel(nome: 'Patrícia Santos', telefone: '(11) 95555-7788', parentesco: 'Avó'),
        'Rua Esperança, 501',
        const Offset(0.36, 0.45),
        300,
        5,
        DateTime(2018, 1, 30),
        'Usa bombinha (asma)',
      ),
      a(
        'a6',
        'Laura Ferreira',
        '4º ano',
        'e1',
        Turno.manha,
        const Responsavel(nome: 'Carlos Ferreira', telefone: '(11) 94444-6655', parentesco: 'Pai'),
        'Av. Brasil, 2040',
        const Offset(0.55, 0.52),
        340,
        15,
        DateTime(2016, 6, 7),
      ),
      a(
        'a7',
        'Arthur Lima',
        '6º ano',
        'e1',
        Turno.manha,
        const Responsavel(nome: 'Fernanda Lima', telefone: '(11) 93333-9090', parentesco: 'Mãe'),
        'Rua das Flores, 77',
        const Offset(0.66, 0.40),
        340,
        15,
        DateTime(2014, 4, 18),
      ),
      a(
        'a8',
        'Sofia Martins',
        '1º ano',
        'e2',
        Turno.tarde,
        const Responsavel(nome: 'Bruno Martins', telefone: '(11) 92222-1212', parentesco: 'Pai'),
        'Rua Primavera, 15',
        const Offset(0.24, 0.55),
        290,
        10,
        DateTime(2019, 9, 9),
      ),
      a(
        'a9',
        'Davi Oliveira',
        '2º ano',
        'e2',
        Turno.tarde,
        const Responsavel(nome: 'Aline Oliveira', telefone: '(11) 91111-3434', parentesco: 'Mãe'),
        'Rua Harmonia, 230',
        const Offset(0.40, 0.30),
        290,
        10,
        DateTime(2018, 12, 1),
      ),
      a(
        'a10',
        'Alice Souza',
        'Infantil 5',
        'e2',
        Turno.tarde,
        const Responsavel(nome: 'Renata Souza', telefone: '(11) 90000-5656', parentesco: 'Mãe'),
        'Alameda Verde, 9',
        const Offset(0.14, 0.38),
        280,
        5,
        DateTime(2020, 2, 14),
        'Intolerância a lactose',
      ),
    ];
  }

  static List<Trajeto> trajetos() => [
    Trajeto(
      id: 't1',
      turno: Turno.manha,
      sentido: Sentido.ida,
      saida: 6 * 60 + 35,
      escolaIds: ['e1'],
      alunoIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7'],
      garagem: const Offset(0.08, 0.90),
    ),
    Trajeto(
      id: 't2',
      turno: Turno.manha,
      sentido: Sentido.volta,
      saida: 12 * 60 + 30,
      escolaIds: ['e1'],
      alunoIds: ['a7', 'a6', 'a5', 'a4', 'a3', 'a1', 'a2'],
      garagem: const Offset(0.92, 0.30),
    ),
    Trajeto(
      id: 't3',
      turno: Turno.tarde,
      sentido: Sentido.ida,
      saida: 12 * 60 + 15,
      escolaIds: ['e2'],
      alunoIds: ['a10', 'a8', 'a9'],
      garagem: const Offset(0.08, 0.90),
    ),
    Trajeto(
      id: 't4',
      turno: Turno.tarde,
      sentido: Sentido.volta,
      saida: 17 * 60 + 30,
      escolaIds: ['e2'],
      alunoIds: ['a9', 'a8', 'a10'],
      garagem: const Offset(0.60, 0.04),
    ),
  ];

  /// Cobranças dos últimos 6 meses. Meses anteriores quase todos pagos.
  static List<Cobranca> cobrancas(List<Aluno> alunos) {
    final hoje = DateTime.now();
    final lista = <Cobranca>[];
    var seq = 0;
    for (var m = 5; m >= 0; m--) {
      final comp = DateTime(hoje.year, hoje.month - m, 1);
      for (final (i, aluno) in alunos.indexed) {
        final venc = DateTime(comp.year, comp.month, aluno.diaVencimento);
        final c = Cobranca(id: 'c${seq++}', alunoId: aluno.id, competencia: comp, vencimento: venc, valor: aluno.valorMensal);
        final atrasadaDeVerdade = m == 1 && i == 3;
        final pagaNoMesAtual = m == 0 && i.isEven;
        if ((m > 0 && !atrasadaDeVerdade) || pagaNoMesAtual) {
          c.pagaEm = venc.subtract(Duration(days: i % 3));
          c.meio = MeioPagamento.values[i % 3];
        }
        if (m == 0 && i == 5) c.informadaPeloResponsavel = true;
        lista.add(c);
      }
    }
    return lista;
  }

  /// O perfil "responsável" da demonstração é a Mariana, mãe do Lucas e da Helena.
  static const filhosDoResponsavelDemo = ['a1', 'a2'];

  /// Código que o motorista compartilha com as famílias.
  static const codigoVan = 'VAN-4821';

  static List<Solicitacao> solicitacoes() => [
    Solicitacao(
      id: 's1',
      nomeAluno: 'Benício Prado',
      // O pai digitou com erro: o motorista precisa confirmar a escola certa.
      escolaInformada: 'Colegio Horisonte',
      turno: Turno.manha,
      responsavel: const Responsavel(nome: 'Camila Prado', telefone: '(11) 98123-4567', parentesco: 'Mãe'),
      endereco: 'Rua Jasmim, 140',
      contaId: 'conta-camila',
    ),
  ];
}
