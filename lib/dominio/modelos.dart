import 'dart:ui' show Offset;

import '../app/formatos.dart';

enum Turno {
  manha('Manhã'),
  tarde('Tarde'),
  integral('Integral');

  const Turno(this.rotulo);
  final String rotulo;
}

/// Ida = casa → escola. Volta = escola → casa.
enum Sentido {
  ida('Ida', 'Casa → Escola'),
  volta('Volta', 'Escola → Casa');

  const Sentido(this.rotulo, this.descricao);
  final String rotulo;
  final String descricao;
}

class Escola {
  Escola({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.entrada,
    required this.saida,
    required this.posicao,
  });

  final String id;
  String nome;
  String endereco;

  /// Minutos desde meia-noite.
  int entrada;
  int saida;

  /// Posição normalizada (0..1) na área de atendimento.
  Offset posicao;
}

class Responsavel {
  const Responsavel({required this.nome, required this.telefone, required this.parentesco});

  final String nome;
  final String telefone;
  final String parentesco;
}

class Aluno {
  Aluno({
    required this.id,
    required this.nome,
    required this.serie,
    required this.escolaId,
    required this.turno,
    required this.responsavel,
    required this.endereco,
    required this.posicao,
    required this.valorMensal,
    required this.diaVencimento,
    required this.nascimento,
    this.cuidados = '',
    this.ativo = true,
  });

  final String id;
  String nome;
  String serie;
  String escolaId;
  Turno turno;
  Responsavel responsavel;
  String endereco;
  Offset posicao;
  double valorMensal;
  int diaVencimento;
  DateTime nascimento;

  /// Alergias, medicação, observações importantes para o motorista.
  String cuidados;
  bool ativo;

  /// A família já acompanha este aluno pelo app (aceitou convite ou foi aprovada).
  bool familiaConectada = false;

  String get primeiro => primeiroNome(nome);

  bool aniversarioNaSemana(DateTime hoje) {
    final base = soData(hoje);
    for (var i = 0; i < 7; i++) {
      final d = base.add(Duration(days: i));
      if (d.day == nascimento.day && d.month == nascimento.month) return true;
    }
    return false;
  }
}

class Veiculo {
  Veiculo({
    required this.id,
    required this.apelido,
    required this.modelo,
    required this.placa,
    required this.capacidade,
    this.motorista = '',
  });

  final String id;
  String motorista;
  String apelido;
  String modelo;
  String placa;
  int capacidade;
}

/// Trajeto fixo que a van faz em um turno e sentido.
class Trajeto {
  Trajeto({
    required this.id,
    required this.turno,
    required this.sentido,
    required this.saida,
    required this.escolaIds,
    required this.alunoIds,
    required this.garagem,
    this.veiculoId = 'v1',
  });

  final String id;
  Turno turno;
  Sentido sentido;
  String veiculoId;

  /// Minutos desde meia-noite.
  int saida;
  final List<String> escolaIds;

  /// Ordem de visita das casas.
  final List<String> alunoIds;

  /// Ponto de partida (casa do motorista / garagem).
  Offset garagem;

  String get nome => '${turno.rotulo} · ${sentido.rotulo}';
}

enum TipoParada { casa, escola }

class Parada {
  const Parada({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.posicao,
    this.alunoIds = const [],
    this.escolaId,
  });

  final TipoParada tipo;
  final String titulo;
  final String subtitulo;
  final Offset posicao;
  final List<String> alunoIds;
  final String? escolaId;
}

enum SituacaoAluno {
  aguardando('Aguardando'),
  aBordo('A bordo'),
  entregue('Entregue'),
  faltou('Não veio'),
  avisado('Ausência avisada');

  const SituacaoAluno(this.rotulo);
  final String rotulo;
}

enum TipoEvento { partida, chegada, embarque, desembarque, falta, aviso, emergencia, fim }

class EventoViagem {
  EventoViagem(this.tipo, this.texto, {this.alunoId}) : quando = DateTime.now();

  final TipoEvento tipo;
  final String texto;
  final String? alunoId;
  final DateTime quando;
}

/// Execução de um trajeto em um dia.
class Viagem {
  Viagem({required this.trajeto, required this.paradas, required this.situacoes})
      : inicio = DateTime.now();

  final Trajeto trajeto;
  final List<Parada> paradas;
  final Map<String, SituacaoAluno> situacoes;
  final DateTime inicio;
  final List<EventoViagem> eventos = [];

  /// Posição fracionária no percurso: 2.4 = 40% entre a parada 2 e a 3.
  /// A posição -1..0 representa o trecho garagem → primeira parada.
  double posicao = -1;
  bool emMovimento = true;
  DateTime? fim;

  bool get encerrada => fim != null;

  int get indiceAtual => posicao.floor().clamp(-1, paradas.length - 1);

  /// Parada em que a van está parada agora (ou null em movimento).
  Parada? get paradaAtual => !emMovimento && posicao >= 0 ? paradas[posicao.round()] : null;

  int get proximaParada => emMovimento ? posicao.floor() + 1 : posicao.round();

  bool paradaResolvida(Parada p) => p.alunoIds.every((id) {
        final s = situacoes[id]!;
        if (p.tipo == TipoParada.casa) {
          return trajeto.sentido == Sentido.ida
              ? s != SituacaoAluno.aguardando
              : s != SituacaoAluno.aBordo;
        }
        return trajeto.sentido == Sentido.ida
            ? s != SituacaoAluno.aBordo
            : s != SituacaoAluno.aguardando;
      });

  int get aBordo => situacoes.values.where((s) => s == SituacaoAluno.aBordo).length;
}

enum StatusCobranca {
  paga('Paga'),
  pendente('Em aberto'),
  atrasada('Atrasada'),
  informada('Pagamento informado');

  const StatusCobranca(this.rotulo);
  final String rotulo;
}

enum MeioPagamento {
  pix('Pix'),
  dinheiro('Dinheiro'),
  transferencia('Transferência'),
  cartao('Cartão');

  const MeioPagamento(this.rotulo);
  final String rotulo;
}

class Cobranca {
  Cobranca({
    required this.id,
    required this.alunoId,
    required this.competencia,
    required this.vencimento,
    required this.valor,
    this.pagaEm,
    this.meio,
    this.informadaPeloResponsavel = false,
  });

  final String id;
  final String alunoId;

  /// Primeiro dia do mês de referência.
  final DateTime competencia;
  final DateTime vencimento;
  final double valor;
  DateTime? pagaEm;
  MeioPagamento? meio;
  bool informadaPeloResponsavel;

  StatusCobranca status(DateTime hoje) {
    if (pagaEm != null) return StatusCobranca.paga;
    if (informadaPeloResponsavel) return StatusCobranca.informada;
    if (soData(hoje).isAfter(vencimento)) return StatusCobranca.atrasada;
    return StatusCobranca.pendente;
  }
}

class Ausencia {
  Ausencia({required this.id, required this.alunoId, required this.data, this.sentido, this.motivo = ''});

  final String id;
  final String alunoId;
  final DateTime data;

  /// null = dia todo (ida e volta).
  final Sentido? sentido;
  final String motivo;

  bool afeta(DateTime dia, Sentido s) => mesmoDia(data, dia) && (sentido == null || sentido == s);

  String get rotuloSentido => sentido == null ? 'Ida e volta' : sentido!.rotulo;
}

/// Pedido de vínculo feito pelo responsável com o código da van.
class Solicitacao {
  Solicitacao({
    required this.id,
    required this.nomeAluno,
    required this.escolaId,
    required this.turno,
    required this.responsavel,
    required this.endereco,
    this.doResponsavelDemo = false,
  }) : criadaEm = DateTime.now();

  final String id;
  final String nomeAluno;
  final String escolaId;
  final Turno turno;
  final Responsavel responsavel;
  final String endereco;
  final DateTime criadaEm;

  /// Feita pelo perfil "responsável" da demonstração (vira filho dele ao aprovar).
  final bool doResponsavelDemo;
}

/// Convite que o motorista envia para uma família: já aponta para os filhos
/// e, por consequência, para as rotas deles. Uso único, com validade.
class Convite {
  Convite({
    required this.codigo,
    required this.alunoIds,
    required this.responsavel,
    required this.criadoEm,
    required this.expiraEm,
    this.escopo = Escopo.completo,
    this.nomeConvidado,
  });

  /// O que quem aceitar poderá fazer.
  final Escopo escopo;

  /// Nome de um familiar diferente do responsável cadastrado (ex.: "Avó Lúcia").
  final String? nomeConvidado;

  /// Seis caracteres sem ambiguidades (sem 0/O, 1/I), ex.: "K7P2QX".
  final String codigo;
  final List<String> alunoIds;
  final Responsavel responsavel;
  final DateTime criadoEm;
  final DateTime expiraEm;
  DateTime? aceitoEm;
  bool cancelado = false;

  String get codigoFormatado => '${codigo.substring(0, 3)}-${codigo.substring(3)}';

  /// Link que abre o app direto no convite (deep link).
  String get link => 'https://vanconnect.app/c/$codigo';

  bool valido(DateTime agora) => !cancelado && aceitoEm == null && agora.isBefore(expiraEm);
}

/// O que cada familiar pode fazer no app.
enum Escopo {
  completo('Ver e agir', 'Acompanha, marca ausência e informa pagamentos'),
  leitura('Só acompanhar', 'Vê o mapa e os avisos, sem alterar nada');

  const Escopo(this.rotulo, this.descricao);
  final String rotulo;
  final String descricao;
}

/// Outro aparelho executando uma rota nesta van (ex.: motorista auxiliar).
class ExecucaoRemota {
  ExecucaoRemota({required this.quem, required this.desde, required this.trajetoNome});

  final String quem;
  final DateTime desde;
  final String trajetoNome;
}

/// Mudanças só de hoje numa rota, sem mexer na rota padrão.
class AjusteDoDia {
  final incluidos = <String>{};
  final removidos = <String>{};

  bool get vazio => incluidos.isEmpty && removidos.isEmpty;
}
