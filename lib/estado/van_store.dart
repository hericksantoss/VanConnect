import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/formatos.dart';
import '../dados/semente.dart';
import '../dominio/modelos.dart';

enum Perfil { motorista, responsavel }

class ResumoMes {
  const ResumoMes({required this.esperado, required this.recebido, required this.emAtraso, required this.aReceber});

  final double esperado;
  final double recebido;
  final double emAtraso;
  final double aReceber;

  double get percentual => esperado == 0 ? 0 : recebido / esperado;
}

/// Estado global do protótipo. Tudo em memória; troque os métodos por chamadas
/// ao seu backend quando sair do protótipo.
class VanStore extends ChangeNotifier {
  VanStore() {
    escolas.addAll(Semente.escolas);
    alunos.addAll(Semente.alunos());
    trajetos.addAll(Semente.trajetos());
    cobrancas.addAll(Semente.cobrancas(alunos));
    solicitacoes.addAll(Semente.solicitacoes());
    for (final id in filhosDoResponsavel) {
      aluno(id).familiaConectada = true;
    }
    final amanha = soData(DateTime.now()).add(const Duration(days: 1));
    ausencias.add(Ausencia(
      id: 'aus0',
      alunoId: 'a6',
      data: soData(DateTime.now()),
      sentido: Sentido.ida,
      motivo: 'Consulta médica',
    ));
    ausencias.add(Ausencia(id: 'aus1', alunoId: 'a4', data: amanha, motivo: 'Viagem em família'));
  }

  Perfil? perfil;
  /// Separado do resto do estado para trocar o tema sem reconstruir tudo.
  final tema = ValueNotifier(ThemeMode.system);

  /// Posição da van, atualizada a cada quadro da simulação. Só o mapa escuta;
  /// o restante da interface reconstrói apenas em mudanças de estado.
  final posicaoVan = ValueNotifier<double>(-1);
  final String nomeMotorista = 'Rogério Nunes';
  final String codigoVan = Semente.codigoVan;
  final solicitacoes = <Solicitacao>[];
  final convites = <Convite>[];
  final escolas = <Escola>[];
  final alunos = <Aluno>[];
  final trajetos = <Trajeto>[];
  final cobrancas = <Cobranca>[];
  final ausencias = <Ausencia>[];
  final veiculos = <Veiculo>[Semente.veiculo];

  /// Van principal (a primeira cadastrada).
  Veiculo get veiculo => veiculos.first;
  final List<String> filhosDoResponsavel = List.of(Semente.filhosDoResponsavelDemo);
  final Set<String> concluidosHoje = {};

  // Preferências do motorista.
  bool compartilharAoIniciar = true;
  bool avisarProximaParada = true;
  bool seguirAutomaticamente = true;
  double velocidadeSimulacao = 1;

  Viagem? viagem;
  Timer? _relogio;
  Timer? _seguirDepois;
  int _seq = 100;

  // ---------------------------------------------------------------- consultas

  void preferencias({bool? compartilhar, bool? avisar, bool? seguir}) {
    compartilharAoIniciar = compartilhar ?? compartilharAoIniciar;
    avisarProximaParada = avisar ?? avisarProximaParada;
    seguirAutomaticamente = seguir ?? seguirAutomaticamente;
    notifyListeners();
  }

  void definirTema(ThemeMode modo) => tema.value = modo;

  // ------------------------------------------------------------ vínculos

  /// Normaliza "van 4821", "VAN4821" etc. para "VAN-4821".
  static String normalizarCodigo(String bruto) {
    final digitos = bruto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceFirst('VAN', '');
    return 'VAN-$digitos';
  }

  bool codigoValido(String bruto) => normalizarCodigo(bruto) == codigoVan;

  void solicitarVinculo({
    required String nomeAluno,
    required String escolaId,
    required Turno turno,
    required String endereco,
  }) {
    final mae = aluno(filhosDoResponsavel.first).responsavel;
    solicitacoes.add(Solicitacao(
      id: 's${_seq++}',
      nomeAluno: nomeAluno,
      escolaId: escolaId,
      turno: turno,
      responsavel: mae,
      endereco: endereco,
      doResponsavelDemo: true,
    ));
    notifyListeners();
  }

  List<Solicitacao> get solicitacoesDoResponsavel => solicitacoes.where((s) => s.doResponsavelDemo).toList();

  /// Aprova o pedido: vira aluno, entra nas rotas e ganha mensalidade.
  List<Trajeto> aprovar(Solicitacao s) {
    solicitacoes.remove(s);
    final rotas = adicionarAluno(
      nome: s.nomeAluno,
      serie: '—',
      escolaId: s.escolaId,
      turno: s.turno,
      responsavel: s.responsavel,
      endereco: s.endereco,
      valorMensal: 320,
      diaVencimento: 10,
      nascimento: DateTime(DateTime.now().year - 8),
    );
    alunos.last.familiaConectada = true;
    if (s.doResponsavelDemo) filhosDoResponsavel.add(alunos.last.id);
    notifyListeners();
    return rotas;
  }

  // ------------------------------------------------------- convites (família)

  static const _alfabetoConvite = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const validadeConvite = Duration(days: 7);

  /// Irmãos: alunos ativos com o mesmo telefone de responsável.
  List<Aluno> familiaDe(Aluno a) => alunosAtivos
      .where((x) => x.responsavel.telefone == a.responsavel.telefone)
      .toList()
    ..sort((x, y) => x.nome.compareTo(y.nome));

  /// Convite ainda válido que inclui este aluno (se houver).
  Convite? conviteAtivoDe(String alunoId) {
    final agora = DateTime.now();
    for (final c in convites.reversed) {
      if (c.valido(agora) && c.alunoIds.contains(alunoId)) return c;
    }
    return null;
  }

  /// Gera (ou reaproveita) o convite de uso único para estes alunos.
  Convite gerarConvite(List<String> alunoIds) {
    final ids = [...{...alunoIds}]..sort();
    final existente = conviteAtivoDe(ids.first);
    if (existente != null && ({...existente.alunoIds}.containsAll(ids)) && existente.alunoIds.length == ids.length) {
      return existente;
    }
    // Um convite novo substitui os anteriores destes alunos.
    for (final id in ids) {
      conviteAtivoDe(id)?.cancelado = true;
    }
    final r = math.Random.secure();
    String codigo;
    do {
      codigo = List.generate(6, (_) => _alfabetoConvite[r.nextInt(_alfabetoConvite.length)]).join();
    } while (convites.any((c) => c.codigo == codigo));
    final agora = DateTime.now();
    final c = Convite(
      codigo: codigo,
      alunoIds: ids,
      responsavel: aluno(ids.first).responsavel,
      criadoEm: agora,
      expiraEm: agora.add(validadeConvite),
    );
    convites.add(c);
    notifyListeners();
    return c;
  }

  /// Tira espaços, traços e minúsculas: "k7p 2qx" → "K7P2QX".
  static String limparCodigo(String bruto) => bruto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Código geral do motorista começa com VAN; o resto é tratado como convite.
  static bool pareceCodigoGeral(String bruto) => limparCodigo(bruto).startsWith('VAN');

  Convite? buscarConvite(String bruto) {
    final codigo = limparCodigo(bruto);
    final agora = DateTime.now();
    for (final c in convites) {
      if (c.codigo == codigo && c.valido(agora)) return c;
    }
    return null;
  }

  /// O responsável aceita: os filhos passam a aparecer para ele. Sem aprovação,
  /// porque foi o próprio motorista quem convidou.
  List<Aluno> aceitarConvite(Convite c) {
    c.aceitoEm = DateTime.now();
    for (final id in c.alunoIds) {
      aluno(id).familiaConectada = true;
      if (!filhosDoResponsavel.contains(id)) filhosDoResponsavel.add(id);
    }
    notifyListeners();
    return c.alunoIds.map(aluno).toList();
  }

  void cancelarConvite(Convite c) {
    c.cancelado = true;
    notifyListeners();
  }

  String mensagemConvite(Convite c) {
    final nomes = c.alunoIds.map((id) => aluno(id).primeiro).toList();
    final quem = nomes.length == 1 ? nomes.first : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    return 'Olá, ${primeiroNome(c.responsavel.nome)}! Aqui é ${primeiroNome(nomeMotorista)}, da van escolar 🚐\n'
        'Para acompanhar $quem ao vivo e avisar ausências pelo Van Connect, toque no link:\n'
        '${c.link}\n\n'
        'Ou abra o app e digite o código ${c.codigoFormatado} (válido até ${dataCurta(c.expiraEm)}).';
  }

  void recusar(Solicitacao s) {
    solicitacoes.remove(s);
    notifyListeners();
  }

  // ----------------------------------------------------------- emergência

  DateTime? emergenciaEm;

  void dispararEmergencia() {
    emergenciaEm = DateTime.now();
    viagem?.eventos.insert(0, EventoViagem(TipoEvento.emergencia, 'Alerta de emergência enviado às famílias'));
    notifyListeners();
  }

  void encerrarEmergencia() {
    emergenciaEm = null;
    viagem?.eventos.insert(0, EventoViagem(TipoEvento.aviso, 'Emergência encerrada: tudo bem'));
    notifyListeners();
  }

  void escolherPerfil(Perfil? p) {
    perfil = p;
    notifyListeners();
  }

  Escola escola(String id) => escolas.firstWhere((e) => e.id == id);
  Aluno aluno(String id) => alunos.firstWhere((a) => a.id == id);

  List<Aluno> get alunosAtivos => alunos.where((a) => a.ativo).toList();

  List<Trajeto> get trajetosOrdenados => [...trajetos]..sort((a, b) => a.saida.compareTo(b.saida));

  Trajeto? get proximoTrajeto {
    final agora = DateTime.now();
    final minutos = agora.hour * 60 + agora.minute;
    final pendentes = trajetosOrdenados.where((t) => !concluidosHoje.contains(t.id)).toList();
    if (pendentes.isEmpty) return null;
    return pendentes.firstWhere((t) => t.saida >= minutos - 60, orElse: () => pendentes.first);
  }

  Ausencia? ausenciaHoje(String alunoId, Sentido sentido) {
    final hoje = DateTime.now();
    for (final a in ausencias) {
      if (a.alunoId == alunoId && a.afeta(hoje, sentido)) return a;
    }
    return null;
  }

  List<Ausencia> get ausenciasDeHoje {
    final hoje = DateTime.now();
    return ausencias.where((a) => mesmoDia(a.data, hoje)).toList();
  }

  List<Ausencia> ausenciasFuturasDe(String alunoId) {
    final hoje = soData(DateTime.now());
    return ausencias.where((a) => a.alunoId == alunoId && !a.data.isBefore(hoje)).toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }

  List<Aluno> alunosDo(Trajeto t) =>
      t.alunoIds.map(aluno).where((a) => a.ativo).toList();

  List<Aluno> get aniversariantesDaSemana =>
      alunosAtivos.where((a) => a.aniversarioNaSemana(DateTime.now())).toList();

  // ------------------------------------------------------------- financeiro

  List<Cobranca> cobrancasDoMes(DateTime mes) => cobrancas
      .where((c) => c.competencia.year == mes.year && c.competencia.month == mes.month)
      .toList()
    ..sort((a, b) => a.vencimento.compareTo(b.vencimento));

  List<Cobranca> cobrancasDo(String alunoId) =>
      cobrancas.where((c) => c.alunoId == alunoId).toList()..sort((a, b) => b.competencia.compareTo(a.competencia));

  ResumoMes resumo(DateTime mes) {
    final hoje = DateTime.now();
    var esperado = 0.0, recebido = 0.0, atraso = 0.0, aReceber = 0.0;
    for (final c in cobrancasDoMes(mes)) {
      esperado += c.valor;
      switch (c.status(hoje)) {
        case StatusCobranca.paga:
          recebido += c.valor;
        case StatusCobranca.atrasada:
          atraso += c.valor;
        case StatusCobranca.pendente || StatusCobranca.informada:
          aReceber += c.valor;
      }
    }
    return ResumoMes(esperado: esperado, recebido: recebido, emAtraso: atraso, aReceber: aReceber);
  }

  /// Todas as cobranças atrasadas, de qualquer mês.
  List<Cobranca> get atrasadas {
    final hoje = DateTime.now();
    return cobrancas.where((c) => c.status(hoje) == StatusCobranca.atrasada).toList();
  }

  List<Cobranca> get informadas =>
      cobrancas.where((c) => c.status(DateTime.now()) == StatusCobranca.informada).toList();

  void registrarPagamento(Cobranca c, MeioPagamento meio) {
    c
      ..pagaEm = DateTime.now()
      ..meio = meio
      ..informadaPeloResponsavel = false;
    notifyListeners();
  }

  void desfazerPagamento(Cobranca c) {
    c
      ..pagaEm = null
      ..meio = null;
    notifyListeners();
  }

  void informarPagamento(Cobranca c) {
    c.informadaPeloResponsavel = true;
    notifyListeners();
  }

  /// Gera as cobranças que faltam no mês. Retorna quantas foram criadas.
  int gerarCobrancas(DateTime mes) {
    var criadas = 0;
    final comp = DateTime(mes.year, mes.month, 1);
    for (final a in alunosAtivos) {
      final existe = cobrancas.any((c) =>
          c.alunoId == a.id && c.competencia.year == comp.year && c.competencia.month == comp.month);
      if (existe) continue;
      cobrancas.add(Cobranca(
        id: 'c${_seq++}',
        alunoId: a.id,
        competencia: comp,
        vencimento: DateTime(comp.year, comp.month, a.diaVencimento),
        valor: a.valorMensal,
      ));
      criadas++;
    }
    notifyListeners();
    return criadas;
  }

  String mensagemCobranca(Cobranca c) {
    final a = aluno(c.alunoId);
    return 'Olá, ${primeiroNome(a.responsavel.nome)}! Tudo bem? 😊\n'
        'Passando para lembrar da mensalidade do transporte escolar de ${a.primeiro} '
        '(${mesAno(c.competencia)}), no valor de ${moeda(c.valor)}, '
        'com vencimento em ${dataCurta(c.vencimento)}.\n'
        'Qualquer dúvida, estou à disposição. Obrigado!';
  }

  // --------------------------------------------------------------- cadastros

  /// Adiciona o aluno e já o encaixa nos trajetos do turno (ida e volta).
  List<Trajeto> adicionarAluno({
    required String nome,
    required String serie,
    required String escolaId,
    required Turno turno,
    required Responsavel responsavel,
    required String endereco,
    required double valorMensal,
    required int diaVencimento,
    required DateTime nascimento,
    String cuidados = '',
  }) {
    final r = math.Random(nome.hashCode);
    final aluno = Aluno(
      id: 'a${_seq++}',
      nome: nome,
      serie: serie,
      escolaId: escolaId,
      turno: turno,
      responsavel: responsavel,
      endereco: endereco,
      posicao: Offset(0.12 + r.nextDouble() * 0.6, 0.3 + r.nextDouble() * 0.55),
      valorMensal: valorMensal,
      diaVencimento: diaVencimento,
      nascimento: nascimento,
      cuidados: cuidados,
    );
    alunos.add(aluno);
    final encaixados = <Trajeto>[];
    for (final t in trajetos) {
      if (t.turno == turno && t.escolaIds.contains(escolaId)) {
        t.alunoIds.add(aluno.id);
        otimizarOrdem(t, notificar: false);
        encaixados.add(t);
      }
    }
    gerarCobrancas(DateTime.now());
    notifyListeners();
    return encaixados;
  }

  void alternarAtivo(Aluno a) {
    a.ativo = !a.ativo;
    notifyListeners();
  }

  void avisarAusencia({required String alunoId, required DateTime data, Sentido? sentido, String motivo = ''}) {
    ausencias.add(Ausencia(id: 'aus${_seq++}', alunoId: alunoId, data: soData(data), sentido: sentido, motivo: motivo));
    final v = viagem;
    if (v != null && !v.encerrada && mesmoDia(data, DateTime.now()) && (sentido == null || sentido == v.trajeto.sentido)) {
      if (v.situacoes[alunoId] == SituacaoAluno.aguardando) {
        v.situacoes[alunoId] = SituacaoAluno.avisado;
        v.eventos.insert(0, EventoViagem(TipoEvento.aviso, '${aluno(alunoId).primeiro} não vai hoje (avisado pelo responsável)', alunoId: alunoId));
      }
    }
    notifyListeners();
  }

  void removerAusencia(Ausencia a) {
    ausencias.remove(a);
    notifyListeners();
  }

  // ------------------------------------------------------------ gestão

  Veiculo salvarVeiculo({Veiculo? existente, required String apelido, required String modelo, required String placa, required int capacidade}) {
    final v = existente ??
        Veiculo(id: 'v${_seq++}', apelido: apelido, modelo: modelo, placa: placa, capacidade: capacidade);
    v
      ..apelido = apelido
      ..modelo = modelo
      ..placa = placa.toUpperCase()
      ..capacidade = capacidade;
    if (existente == null) veiculos.add(v);
    notifyListeners();
    return v;
  }

  bool removerVeiculo(Veiculo v) {
    if (veiculos.length == 1) return false;
    veiculos.remove(v);
    for (final t in trajetos.where((t) => t.veiculoId == v.id)) {
      t.veiculoId = veiculo.id;
    }
    notifyListeners();
    return true;
  }

  Veiculo veiculoDe(Trajeto t) => veiculos.firstWhere((v) => v.id == t.veiculoId, orElse: () => veiculo);

  Escola salvarEscola({Escola? existente, required String nome, required String endereco, required int entrada, required int saida}) {
    final r = math.Random(nome.hashCode);
    final e = existente ??
        Escola(
          id: 'e${_seq++}',
          nome: nome,
          endereco: endereco,
          entrada: entrada,
          saida: saida,
          posicao: Offset(0.55 + r.nextDouble() * 0.35, 0.06 + r.nextDouble() * 0.2),
        );
    e
      ..nome = nome
      ..endereco = endereco
      ..entrada = entrada
      ..saida = saida;
    if (existente == null) escolas.add(e);
    notifyListeners();
    return e;
  }

  bool removerEscola(Escola e) {
    if (alunos.any((a) => a.escolaId == e.id) || escolas.length == 1) return false;
    escolas.remove(e);
    for (final t in trajetos) {
      t.escolaIds.remove(e.id);
    }
    notifyListeners();
    return true;
  }

  void atualizarAluno(Aluno a, {String? nome, String? endereco, String? escolaId, Turno? turno, double? valorMensal, int? diaVencimento, String? cuidados}) {
    final mudouRota = (escolaId != null && escolaId != a.escolaId) || (turno != null && turno != a.turno);
    a
      ..nome = nome ?? a.nome
      ..endereco = endereco ?? a.endereco
      ..escolaId = escolaId ?? a.escolaId
      ..turno = turno ?? a.turno
      ..valorMensal = valorMensal ?? a.valorMensal
      ..diaVencimento = diaVencimento ?? a.diaVencimento
      ..cuidados = cuidados ?? a.cuidados;
    if (mudouRota) {
      for (final t in trajetos) {
        final deveEstar = t.turno == a.turno && t.escolaIds.contains(a.escolaId);
        if (deveEstar && !t.alunoIds.contains(a.id)) {
          t.alunoIds.add(a.id);
          otimizarOrdem(t, notificar: false);
        } else if (!deveEstar) {
          t.alunoIds.remove(a.id);
        }
      }
    }
    notifyListeners();
  }

  Trajeto criarTrajeto({required Turno turno, required Sentido sentido, required int saida, required String escolaId}) {
    final t = Trajeto(
      id: 't${_seq++}',
      turno: turno,
      sentido: sentido,
      saida: saida,
      escolaIds: [escolaId],
      alunoIds: alunosAtivos.where((a) => a.turno == turno && a.escolaId == escolaId).map((a) => a.id).toList(),
      garagem: const Offset(0.08, 0.9),
      veiculoId: veiculo.id,
    );
    trajetos.add(t);
    otimizarOrdem(t, notificar: false);
    notifyListeners();
    return t;
  }

  void removerTrajeto(Trajeto t) {
    trajetos.remove(t);
    notifyListeners();
  }

  void alternarAlunoNoTrajeto(Trajeto t, String alunoId) {
    if (t.alunoIds.contains(alunoId)) {
      t.alunoIds.remove(alunoId);
    } else {
      t.alunoIds.add(alunoId);
      otimizarOrdem(t, notificar: false);
    }
    notifyListeners();
  }

  void alternarEscolaNoTrajeto(Trajeto t, String escolaId) {
    if (t.escolaIds.contains(escolaId)) {
      if (t.escolaIds.length > 1) t.escolaIds.remove(escolaId);
    } else {
      t.escolaIds.add(escolaId);
    }
    notifyListeners();
  }

  void definirVeiculoDoTrajeto(Trajeto t, Veiculo v) {
    t.veiculoId = v.id;
    notifyListeners();
  }

  // --------------------------------------------------------- relatórios

  /// Resumos dos últimos [meses] meses, do mais antigo ao atual.
  List<(DateTime, ResumoMes)> historico({int meses = 6}) {
    final hoje = DateTime.now();
    return [
      for (var i = meses - 1; i >= 0; i--)
        () {
          final m = DateTime(hoje.year, hoje.month - i);
          return (m, resumo(m));
        }(),
    ];
  }

  /// Percentual do valor esperado que está atrasado no mês.
  double inadimplencia(DateTime mes) {
    final r = resumo(mes);
    return r.esperado == 0 ? 0 : r.emAtraso / r.esperado;
  }

  /// Mensagem única para cobrar vários responsáveis (copiar e colar).
  String mensagemCobrancaEmLote(List<Cobranca> lista) => lista.map(mensagemCobranca).join('\n\n———\n\n');

  // ---------------------------------------------------------------- trajetos

  void ajustarSaida(Trajeto t, int minutos) {
    t.saida = minutos;
    notifyListeners();
  }

  void reordenar(Trajeto t, int de, int para) {
    final id = t.alunoIds.removeAt(de);
    t.alunoIds.insert(para, id);
    notifyListeners();
  }

  static double _distancia(Offset a, Offset b) => (a.dx - b.dx).abs() + (a.dy - b.dy).abs();

  double comprimento(Trajeto t) {
    final pontos = pontosDoTrajeto(t);
    var total = 0.0;
    for (var i = 1; i < pontos.length; i++) {
      total += _distancia(pontos[i - 1], pontos[i]);
    }
    return total;
  }

  /// "km" ilustrativos: o mapa normalizado equivale a ~6 km de lado.
  double km(Trajeto t) => comprimento(t) * 6;

  List<Offset> pontosDoTrajeto(Trajeto t) {
    final casas = alunosDo(t).map((a) => a.posicao).toList();
    final escolasPos = t.escolaIds.map((id) => escola(id).posicao).toList();
    return t.sentido == Sentido.ida
        ? [t.garagem, ...casas, ...escolasPos]
        : [t.garagem, ...escolasPos, ...casas];
  }

  /// Vizinho mais próximo a partir do ponto de partida. Retorna km economizados.
  double otimizarOrdem(Trajeto t, {bool notificar = true}) {
    final antes = km(t);
    final inicio = t.sentido == Sentido.ida ? t.garagem : escola(t.escolaIds.first).posicao;
    final restantes = [...t.alunoIds];
    final ordem = <String>[];
    var atual = inicio;
    while (restantes.isNotEmpty) {
      restantes.sort((x, y) => _distancia(atual, aluno(x).posicao).compareTo(_distancia(atual, aluno(y).posicao)));
      final prox = restantes.removeAt(0);
      ordem.add(prox);
      atual = aluno(prox).posicao;
    }
    t.alunoIds
      ..clear()
      ..addAll(ordem);
    if (notificar) notifyListeners();
    return math.max(0, antes - km(t));
  }

  // ------------------------------------------------------------------ viagem

  List<Parada> _montarParadas(Trajeto t, Map<String, SituacaoAluno> situacoes) {
    final casas = <Parada>[];
    final porEndereco = <Offset, List<Aluno>>{};
    for (final a in alunosDo(t)) {
      if (situacoes[a.id] == SituacaoAluno.avisado) continue;
      porEndereco.putIfAbsent(a.posicao, () => []).add(a);
    }
    for (final grupo in porEndereco.values) {
      casas.add(Parada(
        tipo: TipoParada.casa,
        titulo: grupo.map((a) => a.primeiro).join(' e '),
        subtitulo: grupo.first.endereco,
        posicao: grupo.first.posicao,
        alunoIds: grupo.map((a) => a.id).toList(),
      ));
    }
    final presentes = alunosDo(t).where((a) => situacoes[a.id] != SituacaoAluno.avisado);
    final paradasEscola = t.escolaIds.map((id) {
      final e = escola(id);
      return Parada(
        tipo: TipoParada.escola,
        titulo: e.nome,
        subtitulo: e.endereco,
        posicao: e.posicao,
        escolaId: id,
        alunoIds: presentes.where((a) => a.escolaId == id).map((a) => a.id).toList(),
      );
    });
    return t.sentido == Sentido.ida ? [...casas, ...paradasEscola] : [...paradasEscola, ...casas];
  }

  void iniciarViagem(Trajeto t) {
    encerrarViagem(silencioso: true);
    final situacoes = <String, SituacaoAluno>{
      for (final a in alunosDo(t))
        a.id: ausenciaHoje(a.id, t.sentido) != null ? SituacaoAluno.avisado : SituacaoAluno.aguardando,
    };
    final v = Viagem(trajeto: t, paradas: _montarParadas(t, situacoes), situacoes: situacoes);
    v.eventos.insert(0, EventoViagem(TipoEvento.partida, 'Viagem ${t.nome} iniciada'));
    final avisados = situacoes.values.where((s) => s == SituacaoAluno.avisado).length;
    if (avisados > 0) {
      v.eventos.insert(0, EventoViagem(TipoEvento.aviso, '$avisados aluno(s) com ausência avisada — paradas puladas'));
    }
    viagem = v;
    posicaoVan.value = v.posicao;
    _anunciarProxima(v);
    _relogio = Timer.periodic(const Duration(milliseconds: 50), (_) => _avancar());
    notifyListeners();
  }

  void _avancar() {
    final v = viagem;
    if (v == null || v.encerrada || !v.emMovimento) return;
    final alvo = v.posicao.floor() + 1;
    if (alvo >= v.paradas.length) return;
    v.posicao = math.min(alvo.toDouble(), v.posicao + 0.012 * velocidadeSimulacao);
    posicaoVan.value = v.posicao;
    if (v.posicao >= alvo) {
      v.emMovimento = false;
      final p = v.paradas[alvo];
      v.eventos.insert(0, EventoViagem(TipoEvento.chegada, 'Chegou em ${p.tipo == TipoParada.casa ? 'casa de ' : ''}${p.titulo}'));
      // Parada sem ninguém para atender (ex.: aluno faltou na escola) → segue sozinho.
      _talvezSeguir(v);
      notifyListeners();
    }
  }

  void _anunciarProxima(Viagem v) {
    if (!avisarProximaParada) return;
    final idx = v.posicao.floor() + 1;
    if (idx >= v.paradas.length) return;
    final p = v.paradas[idx];
    if (p.tipo == TipoParada.casa) {
      v.eventos.insert(
        0,
        EventoViagem(TipoEvento.aviso, 'Responsáveis de ${p.titulo} avisados: van a caminho'),
      );
    }
  }

  void marcar(String alunoId, SituacaoAluno s) {
    final v = viagem;
    if (v == null) return;
    v.situacoes[alunoId] = s;
    final nome = aluno(alunoId).primeiro;
    final evento = switch (s) {
      SituacaoAluno.aBordo => EventoViagem(TipoEvento.embarque, '$nome embarcou', alunoId: alunoId),
      SituacaoAluno.entregue => EventoViagem(
          TipoEvento.desembarque,
          v.trajeto.sentido == Sentido.ida ? '$nome entregue na escola' : '$nome entregue em casa',
          alunoId: alunoId,
        ),
      SituacaoAluno.faltou => EventoViagem(TipoEvento.falta, '$nome não veio', alunoId: alunoId),
      _ => null,
    };
    if (evento != null) v.eventos.insert(0, evento);
    _talvezSeguir(v);
    notifyListeners();
  }

  void resolverParadaInteira(Parada p, SituacaoAluno s) {
    final v = viagem;
    if (v == null) return;
    for (final id in p.alunoIds) {
      final atual = v.situacoes[id];
      final pendente = s == SituacaoAluno.entregue ? atual == SituacaoAluno.aBordo : atual == SituacaoAluno.aguardando;
      if (pendente) {
        v.situacoes[id] = s;
        v.eventos.insert(0, EventoViagem(s == SituacaoAluno.entregue ? TipoEvento.desembarque : TipoEvento.embarque,
            '${aluno(id).primeiro} ${s == SituacaoAluno.entregue ? 'desembarcou' : 'embarcou'}', alunoId: id));
      }
    }
    _talvezSeguir(v);
    notifyListeners();
  }

  void _talvezSeguir(Viagem v) {
    final p = v.paradaAtual;
    if (p == null || !v.paradaResolvida(p)) return;
    if (v.posicao.round() >= v.paradas.length - 1) {
      _seguirDepois?.cancel();
      _seguirDepois = Timer(const Duration(milliseconds: 700), encerrarViagem);
      return;
    }
    if (seguirAutomaticamente) {
      _seguirDepois?.cancel();
      _seguirDepois = Timer(const Duration(milliseconds: 900), seguir);
    }
  }

  void seguir() {
    final v = viagem;
    if (v == null || v.emMovimento || v.encerrada) return;
    if (v.posicao.round() >= v.paradas.length - 1) {
      encerrarViagem();
      return;
    }
    v.posicao = v.posicao.roundToDouble() + 0.0001;
    posicaoVan.value = v.posicao;
    v.emMovimento = true;
    _anunciarProxima(v);
    notifyListeners();
  }

  void encerrarViagem({bool silencioso = false}) {
    _relogio?.cancel();
    _seguirDepois?.cancel();
    final v = viagem;
    if (v == null || v.encerrada) return;
    v.fim = DateTime.now();
    v.eventos.insert(0, EventoViagem(TipoEvento.fim, 'Viagem encerrada · compartilhamento desligado'));
    concluidosHoje.add(v.trajeto.id);
    if (!silencioso) notifyListeners();
  }

  void descartarViagem() {
    encerrarViagem(silencioso: true);
    viagem = null;
    notifyListeners();
  }

  /// Minutos estimados até a van chegar na parada do aluno (null se não se aplica).
  int? previsaoMinutos(String alunoId) {
    final v = viagem;
    if (v == null || v.encerrada) return null;
    final idx = v.paradas.indexWhere((p) => p.tipo == TipoParada.casa && p.alunoIds.contains(alunoId));
    if (idx < 0) return null;
    final faltam = idx - v.posicao;
    if (faltam <= 0) return 0;
    return math.max(1, (faltam * 4).round());
  }

  @override
  void dispose() {
    tema.dispose();
    posicaoVan.dispose();
    _relogio?.cancel();
    _seguirDepois?.cancel();
    super.dispose();
  }
}

/// Disponibiliza a store para a árvore e reconstrói quem depende dela.
class VanScope extends InheritedNotifier<VanStore> {
  const VanScope({super.key, required VanStore store, required super.child}) : super(notifier: store);

  static VanStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VanScope>()!.notifier!;

  static VanStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<VanScope>()!.notifier!;
}
