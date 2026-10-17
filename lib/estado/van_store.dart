import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/formatos.dart';
import '../app/geo.dart';
import '../dados/semente.dart';
import '../dominio/modelos.dart';
import '../servicos/autenticacao_servico.dart';
import '../servicos/endereco_servico.dart';
import '../servicos/localizacao_servico.dart';

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
  VanStore({EnderecoServico? enderecos, LocalizacaoServico? localizacao, AutenticacaoServico? auth})
    : enderecos = enderecos ?? EnderecoServico(),
      localizacao = localizacao ?? LocalizacaoGeolocator(),
      auth = auth ?? AutenticacaoDemonstracao() {
    escolas.addAll(Semente.escolas);
    alunos.addAll(Semente.alunos());
    trajetos.addAll(Semente.trajetos());
    cobrancas.addAll(Semente.cobrancas(alunos));
    solicitacoes.addAll(Semente.solicitacoes());
    for (final id in filhosDoResponsavel) {
      aluno(id).familiaConectada = true;
    }
    // Avisos de exemplo para a demonstração.
    notificarMotorista(
      TipoAviso.pedido,
      'Novo pedido para entrar na van',
      'Camila Prado pediu uma vaga para Benício (escreveu "Colegio Horisonte"). Confira o colégio antes de aceitar.',
    );
    notificarMotorista(TipoAviso.pagamento, 'Pagamento para confirmar', 'Carlos Ferreira informou o pagamento de Laura.');
    notificarResponsaveis(
      ['a2'],
      TipoAviso.cobranca,
      'Mensalidade de Helena em atraso',
      'A mensalidade deste mês venceu. Combine o pagamento com o motorista.',
    );

    final amanha = soData(DateTime.now()).add(const Duration(days: 1));
    ausencias.add(Ausencia(id: 'aus0', alunoId: 'a6', data: soData(DateTime.now()), sentido: Sentido.ida, motivo: 'Consulta médica'));
    ausencias.add(Ausencia(id: 'aus1', alunoId: 'a4', data: amanha, motivo: 'Viagem em família'));
  }

  /// CEP (ViaCEP) e localização no mapa. Injetável para testes.
  final EnderecoServico enderecos;

  /// GPS do celular (obrigatório para iniciar viagem). Injetável para testes.
  final LocalizacaoServico localizacao;

  Perfil? perfil;

  /// Separado do resto do estado para trocar o tema sem reconstruir tudo.
  final tema = ValueNotifier(ThemeMode.system);

  /// Posição da van, atualizada a cada quadro da simulação. Só o mapa escuta;
  /// o restante da interface reconstrói apenas em mudanças de estado.
  final posicaoVan = ValueNotifier<double>(-1);

  /// A posição que as famílias recebem (pode ficar para trás se o sinal cair).
  final posicaoCompartilhada = ValueNotifier<double>(-1);
  String nomeMotorista = 'Rogério Nunes';

  // ------------------------------------------------------------- conta
  /// Login (Google, Facebook, e-mail). No protótipo, simulado.
  final AutenticacaoServico auth;
  ContaUsuario? conta;
  String cpfMotorista = '';
  String rgMotorista = '';
  String cnhMotorista = '';
  String telefoneMotorista = '';

  /// Conta dona dos dados do motorista (quem fez o cadastro neste aparelho).
  String? contaMotoristaId;

  /// Filhos liberados para cada conta de responsável (lembra ao entrar de novo).
  final Map<String, List<String>> filhosPorConta = {};

  /// Chamado quando muda quem está logado (o app salva a sessão no aparelho).
  VoidCallback? aoMudarSessao;
  void _sessaoMudou() => aoMudarSessao?.call();

  /// Responsável logado que ainda não tem filho liberado (esperando aprovação).
  bool get aguardandoAprovacao => perfil == Perfil.responsavel && filhosDoResponsavel.isEmpty;

  /// Fim do cadastro do motorista: dados pessoais e a van principal.
  void concluirCadastroMotorista({
    required ContaUsuario conta,
    required String nome,
    required String cpf,
    required String rg,
    required String cnh,
    required String telefone,
    required String apelidoVan,
    required String modeloVan,
    required String placa,
    required int lugares,
  }) {
    this.conta = conta;
    contaMotoristaId = conta.id;
    nomeMotorista = nome;
    cpfMotorista = cpf;
    rgMotorista = rg;
    cnhMotorista = cnh;
    telefoneMotorista = telefone;
    // A van cadastrada vira a principal (mantém o id para as rotas continuarem valendo).
    veiculo
      ..apelido = apelidoVan
      ..modelo = modeloVan
      ..placa = placa.toUpperCase()
      ..capacidade = lugares
      ..motorista = nome;
    deixarSoVanPrincipal();
    perfil = Perfil.motorista;
    notificarMotorista(
      TipoAviso.sistema,
      'Bem-vindo ao Van Connect, ${primeiroNome(nome)}!',
      'Cadastre a chave Pix em Finanças e convide as famílias pela ficha de cada aluno.',
    );
    _sessaoMudou();
    notifyListeners();
  }

  /// Conta nova começa só com a própria van (as de demonstração saem) e
  /// todas as rotas passam a usar essa van.
  void deixarSoVanPrincipal() {
    final principal = veiculo;
    veiculos.removeWhere((v) => v.id != principal.id);
    for (final t in trajetos) {
      t.veiculoId = principal.id;
    }
  }

  /// Motorista que já tem cadastro só entra.
  bool motoristaCadastrado(ContaUsuario c) => contaMotoristaId == c.id;

  void entrarMotorista(ContaUsuario c) {
    conta = c;
    perfil = Perfil.motorista;
    _sessaoMudou();
    notifyListeners();
  }

  /// "Meus dados" do motorista (a van é editada em Vans).
  void atualizarDadosMotorista({
    required String nome,
    required String cpf,
    required String rg,
    required String cnh,
    required String telefone,
  }) {
    nomeMotorista = nome;
    cpfMotorista = cpf;
    rgMotorista = rg;
    cnhMotorista = cnh;
    telefoneMotorista = telefone;
    for (final v in veiculos) {
      v.motorista = nome;
    }
    _sessaoMudou();
    notifyListeners();
  }

  void entrarDemonstracaoMotorista() {
    conta = const ContaUsuario(
      id: 'demo-rogerio',
      nome: 'Rogério Nunes',
      email: 'demo@vanconnect.app',
      provedor: ProvedorLogin.demonstracao,
    );
    nomeMotorista = 'Rogério Nunes';
    perfil = Perfil.motorista;
    _sessaoMudou();
    notifyListeners();
  }

  /// Responsável entrou com a conta; ainda precisa do código para acessar.
  void comecarSessaoResponsavel(ContaUsuario c) {
    conta = c;
    contaResponsavelId = c.id;
    nomeSessao = c.nome;
    telefoneSessao = '';
    escopoSessao = Escopo.completo;
    filhosDoResponsavel
      ..clear()
      ..addAll((filhosPorConta[c.id] ?? const []).where((id) => alunos.any((a) => a.id == id)));
  }

  void _lembrarFilhos() {
    if (perfil == Perfil.responsavel || filhosDoResponsavel.isNotEmpty) {
      filhosPorConta[contaResponsavelId] = List.of(filhosDoResponsavel);
    }
  }

  void sair() {
    if (perfil == Perfil.responsavel) _lembrarFilhos();
    unawaited(auth.sair());
    perfil = null;
    conta = null;
    _sessaoMudou();
    notifyListeners();
  }

  final String codigoVan = Semente.codigoVan;
  final solicitacoes = <Solicitacao>[];
  final convites = <Convite>[];
  final escolas = <Escola>[];
  final alunos = <Aluno>[];
  final trajetos = <Trajeto>[];
  final cobrancas = <Cobranca>[];
  final ausencias = <Ausencia>[];
  final veiculos = <Veiculo>[Semente.veiculo, Semente.veiculo2];

  /// Van principal (a primeira cadastrada).
  Veiculo get veiculo => veiculos.first;

  /// Sessão do responsável: quem está usando o app, quais filhos vê e o que pode fazer.
  final List<String> filhosDoResponsavel = List.of(Semente.filhosDoResponsavelDemo);
  String nomeSessao = 'Mariana Costa';
  String telefoneSessao = '(11) 98888-1020';
  Escopo escopoSessao = Escopo.completo;

  /// Familiar "só acompanhar" não marca ausência nem informa pagamento.
  bool get podeAgir => escopoSessao == Escopo.completo;

  void entrarDemonstracaoResponsavel() {
    conta = const ContaUsuario(
      id: 'demo-mariana',
      nome: 'Mariana Costa',
      email: 'demo@vanconnect.app',
      provedor: ProvedorLogin.demonstracao,
    );
    contaResponsavelId = 'demo-mariana';
    filhosDoResponsavel
      ..clear()
      ..addAll(Semente.filhosDoResponsavelDemo);
    nomeSessao = 'Mariana Costa';
    telefoneSessao = '(11) 98888-1020';
    escopoSessao = Escopo.completo;
    escolherPerfil(Perfil.responsavel);
  }

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

  /// Compara nomes de escola ignorando maiúsculas, acentos e espaços extras.
  static String _chaveNome(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final buffer = StringBuffer();
    for (final ch in s.toLowerCase().trim().split('')) {
      final i = de.indexOf(ch);
      buffer.write(i >= 0 ? para[i] : ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Sugere a escola cadastrada quando o nome digitado pelo responsável bate.
  Escola? escolaParecida(String nome) {
    final chave = _chaveNome(nome);
    for (final e in escolas) {
      if (_chaveNome(e.nome) == chave) return e;
    }
    return null;
  }

  /// Pedido do responsável pelo código geral. Ele informa a escola por escrito,
  /// sem ver as escolas do motorista; o motorista confirma antes de aprovar.
  void solicitarVinculo({
    required String nomeAluno,
    required String escolaInformada,
    required Turno turno,
    Endereco? endereco,
    String enderecoTexto = '',
  }) {
    final s = Solicitacao(
      id: 's${_seq++}',
      nomeAluno: nomeAluno,
      escolaInformada: escolaInformada,
      escolaId: escolaParecida(escolaInformada)?.id,
      turno: turno,
      responsavel: Responsavel(nome: nomeSessao, telefone: telefoneSessao, parentesco: 'Responsável'),
      endereco: endereco?.resumo ?? enderecoTexto,
      enderecoCompleto: endereco,
      contaId: contaResponsavelId,
    );
    solicitacoes.add(s);
    notificarMotorista(
      TipoAviso.pedido,
      'Novo pedido para entrar na van',
      '${s.responsavel.nome} pediu uma vaga para ${primeiroNome(nomeAluno)} (${s.escolaInformada}).',
    );
    notifyListeners();
  }

  List<Solicitacao> get solicitacoesDoResponsavel => solicitacoes.where((s) => s.contaId == contaResponsavelId).toList();

  /// O motorista corrige o que o responsável mandou antes de aprovar.
  void atualizarSolicitacao(
    Solicitacao s, {
    String? nomeAluno,
    String? escolaId,
    Turno? turno,
    Endereco? endereco,
    String? nomeResponsavel,
    String? telefone,
  }) {
    s
      ..nomeAluno = nomeAluno ?? s.nomeAluno
      ..escolaId = escolaId ?? s.escolaId
      ..turno = turno ?? s.turno;
    if (endereco != null) {
      s
        ..enderecoCompleto = endereco
        ..endereco = endereco.resumo;
    }
    if (nomeResponsavel != null || telefone != null) {
      s.responsavel = Responsavel(
        nome: nomeResponsavel ?? s.responsavel.nome,
        telefone: telefone ?? s.responsavel.telefone,
        parentesco: s.responsavel.parentesco,
      );
    }
    notifyListeners();
  }

  /// Aprova o pedido: vira aluno, entra nas rotas e ganha mensalidade.
  /// Exige a escola confirmada pelo motorista.
  List<Trajeto> aprovar(Solicitacao s) {
    if (s.escolaId == null) throw StateError('Confirme a escola antes de aprovar.');
    solicitacoes.remove(s);
    final rotas = adicionarAluno(
      nome: s.nomeAluno,
      serie: '—',
      escolaId: s.escolaId!,
      turno: s.turno,
      responsavel: s.responsavel,
      endereco: s.endereco,
      enderecoCompleto: s.enderecoCompleto,
      valorMensal: 320,
      diaVencimento: 10,
      nascimento: DateTime(DateTime.now().year - 8),
    );
    final novo = alunos.last;
    novo.familiaConectada = true;
    if (s.contaId != null) {
      final daConta = filhosPorConta.putIfAbsent(s.contaId!, () => []);
      if (!daConta.contains(novo.id)) daConta.add(novo.id);
      if (s.contaId == contaResponsavelId && !filhosDoResponsavel.contains(novo.id)) filhosDoResponsavel.add(novo.id);
      _sessaoMudou();
    }
    notificarResponsaveis(
      [novo.id],
      TipoAviso.pedido,
      'Pedido aprovado 🎉',
      '${primeiroNome(nomeMotorista)} aceitou ${novo.primeiro} na van. Já dá para acompanhar no mapa.',
    );
    notifyListeners();
    return rotas;
  }

  /// Só para a demonstração num aparelho só: aprova os pedidos da conta logada
  /// (a escola é casada pelo nome; sem par, usa a primeira cadastrada).
  int aprovarPedidosDemonstracao() {
    final pedidos = solicitacoesDoResponsavel;
    if (escolas.isEmpty) return 0;
    for (final s in pedidos) {
      s.escolaId ??= escolaParecida(s.escolaInformada)?.id ?? escolas.first.id;
      aprovar(s);
    }
    return pedidos.length;
  }

  // ------------------------------------------------------- convites (família)

  static const _alfabetoConvite = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const validadeConvite = Duration(days: 7);

  /// Irmãos: alunos ativos com o mesmo telefone de responsável.
  List<Aluno> familiaDe(Aluno a) =>
      alunosAtivos.where((x) => x.responsavel.telefone == a.responsavel.telefone).toList()..sort((x, y) => x.nome.compareTo(y.nome));

  /// Convite ainda válido que inclui este aluno (se houver).
  Convite? conviteAtivoDe(String alunoId) {
    final agora = DateTime.now();
    for (final c in convites.reversed) {
      if (c.valido(agora) && c.alunoIds.contains(alunoId)) return c;
    }
    return null;
  }

  /// Gera (ou reaproveita) o convite de uso único para estes alunos.
  Convite gerarConvite(List<String> alunoIds, {Escopo escopo = Escopo.completo, String? nomeConvidado}) {
    final ids = [
      ...{...alunoIds},
    ]..sort();
    final nome = (nomeConvidado == null || nomeConvidado.trim().isEmpty) ? null : nomeConvidado.trim();
    final agora0 = DateTime.now();
    Convite? mesmoTipo(String id) {
      for (final c in convites.reversed) {
        if (c.valido(agora0) && c.alunoIds.contains(id) && c.escopo == escopo && c.nomeConvidado == nome) return c;
      }
      return null;
    }

    final existente = mesmoTipo(ids.first);
    if (existente != null && ({...existente.alunoIds}.containsAll(ids)) && existente.alunoIds.length == ids.length) {
      return existente;
    }
    // Um convite novo substitui os anteriores do mesmo tipo destes alunos
    // (convites para outros familiares continuam valendo).
    for (final id in ids) {
      mesmoTipo(id)?.cancelado = true;
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
      escopo: escopo,
      nomeConvidado: nome,
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
    _lembrarFilhos();
    _sessaoMudou();
    notifyListeners();
    return c.alunoIds.map(aluno).toList();
  }

  /// O convite também é o login: abre uma sessão nova só com os filhos do convite.
  List<Aluno> entrarComConvite(Convite c) {
    c.aceitoEm = DateTime.now();
    notificarMotorista(
      TipoAviso.convite,
      'Convite aceito',
      '${c.nomeConvidado ?? c.responsavel.nome} entrou para acompanhar ${c.alunoIds.map((id) => aluno(id).primeiro).join(' e ')}.',
    );
    filhosDoResponsavel
      ..clear()
      ..addAll(c.alunoIds);
    for (final id in c.alunoIds) {
      aluno(id).familiaConectada = true;
    }
    nomeSessao = conta?.nome.isNotEmpty == true ? conta!.nome : (c.nomeConvidado ?? c.responsavel.nome);
    telefoneSessao = c.nomeConvidado == null ? c.responsavel.telefone : '';
    escopoSessao = c.escopo;
    perfil = Perfil.responsavel;
    _lembrarFilhos();
    _sessaoMudou();
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
    return 'Olá, ${primeiroNome(c.nomeConvidado ?? c.responsavel.nome)}! Aqui é ${primeiroNome(nomeMotorista)}, da van escolar 🚐\n'
        'Para acompanhar $quem ao vivo e avisar ausências pelo Van Connect, toque no link:\n'
        '${c.link}\n\n'
        'Ou abra o app e digite o código ${c.codigoFormatado} (válido até ${dataCurta(c.expiraEm)}).';
  }

  void recusar(Solicitacao s) {
    solicitacoes.remove(s);
    notifyListeners();
  }

  // --------------------------------------------------------- Pix e cobranças

  /// Chave Pix do motorista, enviada junto com as cobranças.
  ChavePix? chavePix;

  void salvarChavePix(ChavePix c) {
    final nova = chavePix == null;
    chavePix = c;
    notificarMotorista(
      TipoAviso.pix,
      nova ? 'Nova chave Pix adicionada' : 'Chave Pix atualizada',
      'Lembre-se: cobranças e lembretes agora vão com a chave ${c.tipo.rotulo} ${c.valor}.',
    );
    notificarResponsaveis(
      const [],
      TipoAviso.pix,
      'Chave Pix do motorista',
      'Para pagar as mensalidades, use a chave ${c.tipo.rotulo} ${c.valor} (${c.titular}).',
      chavePix: c.valor,
    );
    notifyListeners();
  }

  String _textoPix() =>
      chavePix == null ? 'Combine o pagamento com o motorista.' : 'Pague pelo Pix: ${chavePix!.valor} (${chavePix!.titular}).';

  /// Cobra uma mensalidade: a família recebe um aviso no app com a chave Pix.
  void cobrar(Cobranca c) {
    final a = aluno(c.alunoId);
    final atrasada = c.status(DateTime.now()) == StatusCobranca.atrasada;
    notificarResponsaveis(
      [c.alunoId],
      TipoAviso.cobranca,
      atrasada ? 'Mensalidade de ${a.primeiro} em atraso' : 'Mensalidade de ${a.primeiro}',
      '${capitalizar(mesAno(c.competencia))}: ${moeda(c.valor)}, ${atrasada ? 'venceu' : 'vence'} em ${dataCurta(c.vencimento)}. ${_textoPix()}',
      chavePix: chavePix?.valor,
    );
    notifyListeners();
  }

  /// Avisa no app todas as famílias com mensalidade atrasada. Retorna quantas.
  int cobrarAtrasadas() {
    final lista = atrasadas;
    for (final c in lista) {
      cobrar(c);
    }
    return lista.length;
  }

  /// Lembrete antes do vencimento para quem ainda não pagou. Retorna quantas famílias.
  int lembrarAntesDoVencimento({int dias = 5}) {
    final hoje = soData(DateTime.now());
    final limite = hoje.add(Duration(days: dias));
    final lista = cobrancas
        .where((c) => c.status(hoje) == StatusCobranca.pendente && !c.vencimento.isBefore(hoje) && !c.vencimento.isAfter(limite))
        .toList();
    for (final c in lista) {
      final a = aluno(c.alunoId);
      notificarResponsaveis(
        [c.alunoId],
        TipoAviso.lembrete,
        'Lembrete: mensalidade de ${a.primeiro}',
        'Vence em ${dataCurta(c.vencimento)} (${moeda(c.valor)}). Pagando antes você evita atraso. ${_textoPix()}',
        chavePix: chavePix?.valor,
      );
    }
    notifyListeners();
    return lista.length;
  }

  /// Mensalidades pendentes que vencem nos próximos [dias].
  int vencendoEm(int dias) {
    final hoje = soData(DateTime.now());
    final limite = hoje.add(Duration(days: dias));
    return cobrancas
        .where((c) => c.status(hoje) == StatusCobranca.pendente && !c.vencimento.isBefore(hoje) && !c.vencimento.isAfter(limite))
        .length;
  }

  // ------------------------------------------------------- central de avisos

  final avisos = <Aviso>[];

  /// Conta do responsável usando o app agora (na demonstração, a Mariana).
  String contaResponsavelId = 'demo-mariana';

  Aviso notificarMotorista(TipoAviso tipo, String titulo, String texto) {
    final a = Aviso(id: 'av${_seq++}', paraMotorista: true, tipo: tipo, titulo: titulo, texto: texto);
    avisos.add(a);
    return a;
  }

  /// [alunoIds] vazio = todas as famílias.
  Aviso notificarResponsaveis(List<String> alunoIds, TipoAviso tipo, String titulo, String texto, {String? chavePix}) {
    final a = Aviso(
      id: 'av${_seq++}',
      paraMotorista: false,
      tipo: tipo,
      titulo: titulo,
      texto: texto,
      alunoIds: alunoIds,
      chavePix: chavePix,
    );
    avisos.add(a);
    return a;
  }

  List<Aviso> get avisosMotorista => avisos.where((a) => a.paraMotorista).toList().reversed.toList();

  List<Aviso> get avisosResponsavel => avisos
      .where((a) => !a.paraMotorista && (a.alunoIds.isEmpty || a.alunoIds.any(filhosDoResponsavel.contains)))
      .toList()
      .reversed
      .toList();

  int get naoLidosMotorista => avisosMotorista.where((a) => !a.lido).length;
  int get naoLidosResponsavel => avisosResponsavel.where((a) => !a.lido).length;

  void marcarAvisoLido(Aviso a) {
    a.lido = true;
    notifyListeners();
  }

  void marcarAvisosLidos({required bool motorista}) {
    for (final a in motorista ? avisosMotorista : avisosResponsavel) {
      a.lido = true;
    }
    notifyListeners();
  }

  // ----------------------------------------------------------- emergência

  DateTime? emergenciaEm;

  void dispararEmergencia() {
    emergenciaEm = DateTime.now();
    final v = viagem;
    if (v != null) {
      notificarResponsaveis(
        v.situacoes.keys.toList(),
        TipoAviso.sistema,
        'Alerta de emergência',
        '${primeiroNome(nomeMotorista)} acionou um alerta durante ${v.trajeto.nome}. Ligue para o motorista.',
      );
    }
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
    _sessaoMudou();
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
    return ausencias.where((a) => a.alunoId == alunoId && !a.data.isBefore(hoje)).toList()..sort((a, b) => a.data.compareTo(b.data));
  }

  List<Aluno> alunosDo(Trajeto t) => t.alunoIds.map(aluno).where((a) => a.ativo).toList();

  List<Aluno> get aniversariantesDaSemana => alunosAtivos.where((a) => a.aniversarioNaSemana(DateTime.now())).toList();

  // ------------------------------------------------------------- financeiro

  List<Cobranca> cobrancasDoMes(DateTime mes) =>
      cobrancas.where((c) => c.competencia.year == mes.year && c.competencia.month == mes.month).toList()
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

  List<Cobranca> get informadas => cobrancas.where((c) => c.status(DateTime.now()) == StatusCobranca.informada).toList();

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
    final a = aluno(c.alunoId);
    notificarMotorista(
      TipoAviso.pagamento,
      'Pagamento para confirmar',
      '${a.responsavel.nome} informou o pagamento de ${a.primeiro} (${mesAno(c.competencia)}, ${moeda(c.valor)}).',
    );
    notifyListeners();
  }

  /// Gera as cobranças que faltam no mês. Retorna quantas foram criadas.
  int gerarCobrancas(DateTime mes) {
    var criadas = 0;
    final comp = DateTime(mes.year, mes.month, 1);
    for (final a in alunosAtivos) {
      final existe = cobrancas.any((c) => c.alunoId == a.id && c.competencia.year == comp.year && c.competencia.month == comp.month);
      if (existe) continue;
      cobrancas.add(
        Cobranca(
          id: 'c${_seq++}',
          alunoId: a.id,
          competencia: comp,
          vencimento: DateTime(comp.year, comp.month, a.diaVencimento),
          valor: a.valorMensal,
        ),
      );
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
    Endereco? enderecoCompleto,
  }) {
    final r = math.Random(nome.hashCode);
    final local = enderecoCompleto != null && enderecoCompleto.temLocal
        ? deLatLng(enderecoCompleto.latitude!, enderecoCompleto.longitude!)
        : null;
    final aluno = Aluno(
      id: 'a${_seq++}',
      nome: nome,
      serie: serie,
      escolaId: escolaId,
      turno: turno,
      responsavel: responsavel,
      endereco: endereco,
      posicao: local ?? Offset(0.12 + r.nextDouble() * 0.6, 0.3 + r.nextDouble() * 0.55),
      valorMensal: valorMensal,
      diaVencimento: diaVencimento,
      nascimento: nascimento,
      cuidados: cuidados,
    )..enderecoCompleto = enderecoCompleto;
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

  /// A ausência (e a volta atrás) só pode mudar antes da rota daquele sentido começar.
  bool ausenciaTravada(String alunoId, DateTime dia, Sentido sentido) {
    if (!mesmoDia(dia, DateTime.now())) return false;
    final v = viagem;
    for (final t in trajetos) {
      if (t.sentido != sentido || !alunosDoDia(t).any((a) => a.id == alunoId)) continue;
      if (concluidosHoje.contains(t.id)) return true;
      if (v != null && !v.encerrada && v.trajeto.id == t.id) return true;
    }
    return false;
  }

  /// Registra a ausência nos sentidos ainda liberados. Retorna os sentidos aceitos
  /// (vazio = a rota já começou e é preciso falar direto com o motorista).
  List<Sentido> avisarAusencia({required String alunoId, required DateTime data, Sentido? sentido, String motivo = ''}) {
    final pedidos = sentido == null ? Sentido.values : [sentido];
    final liberados = pedidos.where((x) => !ausenciaTravada(alunoId, data, x)).toList();
    if (liberados.isEmpty) return liberados;
    notificarMotorista(
      TipoAviso.ausencia,
      'Ausência avisada',
      '${aluno(alunoId).primeiro} não vai ${mesmoDia(data, DateTime.now()) ? 'hoje' : 'em ${dataCurta(data)}'}'
          '${liberados.length == 1 ? ' (só ${liberados.single.rotulo.toLowerCase()})' : ''}${motivo.isEmpty ? '' : ' · $motivo'}.',
    );
    ausencias.add(
      Ausencia(
        id: 'aus${_seq++}',
        alunoId: alunoId,
        data: soData(data),
        sentido: liberados.length == Sentido.values.length ? null : liberados.single,
        motivo: motivo,
      ),
    );
    notifyListeners();
    return liberados;
  }

  /// "Marcar presença": desfaz a ausência, se a rota ainda não começou.
  bool removerAusencia(Ausencia a) {
    final sentidos = a.sentido == null ? Sentido.values : [a.sentido!];
    if (sentidos.any((x) => ausenciaTravada(a.alunoId, a.data, x))) return false;
    ausencias.remove(a);
    notifyListeners();
    return true;
  }

  // ------------------------------------------------------- rota do dia

  /// Ajustes de hoje, por rota. Zeram sozinhos quando o dia muda.
  final _ajustes = <String, AjusteDoDia>{};
  DateTime _diaDosAjustes = soData(DateTime.now());

  AjusteDoDia ajusteDeHoje(Trajeto t) {
    final hoje = soData(DateTime.now());
    if (hoje != _diaDosAjustes) {
      _ajustes.clear();
      _diaDosAjustes = hoje;
    }
    return _ajustes.putIfAbsent(t.id, AjusteDoDia.new);
  }

  /// Quem vai hoje: a rota padrão, menos quem saiu só hoje, mais quem entrou só hoje.
  List<Aluno> alunosDoDia(Trajeto t) {
    final ajuste = ajusteDeHoje(t);
    final base = alunosDo(t).where((a) => !ajuste.removidos.contains(a.id));
    final extras = ajuste.incluidos.where((id) => !t.alunoIds.contains(id)).map(aluno).where((a) => a.ativo);
    return [...base, ...extras];
  }

  /// Liga/desliga um aluno só na rota de hoje.
  void alternarAlunoHoje(Trajeto t, String alunoId) {
    final ajuste = ajusteDeHoje(t);
    final naPadrao = t.alunoIds.contains(alunoId);
    final vaiHoje = alunosDoDia(t).any((a) => a.id == alunoId);
    if (vaiHoje) {
      naPadrao ? ajuste.removidos.add(alunoId) : ajuste.incluidos.remove(alunoId);
    } else {
      naPadrao ? ajuste.removidos.remove(alunoId) : ajuste.incluidos.add(alunoId);
    }
    notifyListeners();
  }

  void desfazerAjustesDeHoje(Trajeto t) {
    _ajustes.remove(t.id);
    notifyListeners();
  }

  /// Transforma a rota de hoje na nova rota padrão.
  void salvarDiaComoPadrao(Trajeto t) {
    final ajuste = ajusteDeHoje(t);
    t.alunoIds.removeWhere(ajuste.removidos.contains);
    for (final id in ajuste.incluidos) {
      if (!t.alunoIds.contains(id)) t.alunoIds.add(id);
    }
    _ajustes.remove(t.id);
    otimizarOrdem(t, notificar: false);
    notifyListeners();
  }

  // ------------------------------------------------------------ gestão

  Veiculo salvarVeiculo({
    Veiculo? existente,
    required String apelido,
    required String modelo,
    required String placa,
    required int capacidade,
  }) {
    final v = existente ?? Veiculo(id: 'v${_seq++}', apelido: apelido, modelo: modelo, placa: placa, capacidade: capacidade);
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

  /// A van principal fica em primeiro; as outras são reservas do mesmo motorista.
  void tornarPrincipal(Veiculo v) {
    veiculos
      ..remove(v)
      ..insert(0, v);
    notifyListeners();
  }

  Veiculo veiculoDe(Trajeto t) => veiculos.firstWhere((v) => v.id == t.veiculoId, orElse: () => veiculo);

  Escola salvarEscola({
    Escola? existente,
    required String nome,
    required String endereco,
    required int entrada,
    required int saida,
    Endereco? enderecoCompleto,
  }) {
    final r = math.Random(nome.hashCode);
    final e =
        existente ??
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
      ..endereco = enderecoCompleto?.resumo ?? endereco
      ..entrada = entrada
      ..saida = saida;
    if (enderecoCompleto != null) {
      e.enderecoCompleto = enderecoCompleto;
      if (enderecoCompleto.temLocal) e.posicao = deLatLng(enderecoCompleto.latitude!, enderecoCompleto.longitude!);
    }
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

  void atualizarAluno(
    Aluno a, {
    String? nome,
    String? endereco,
    String? escolaId,
    Turno? turno,
    double? valorMensal,
    int? diaVencimento,
    String? cuidados,
    Endereco? enderecoCompleto,
  }) {
    final mudouRota = (escolaId != null && escolaId != a.escolaId) || (turno != null && turno != a.turno);
    if (enderecoCompleto != null) {
      a
        ..enderecoCompleto = enderecoCompleto
        ..endereco = enderecoCompleto.resumo;
      if (enderecoCompleto.temLocal) a.posicao = deLatLng(enderecoCompleto.latitude!, enderecoCompleto.longitude!);
      for (final t in trajetos.where((t) => t.alunoIds.contains(a.id))) {
        otimizarOrdem(t, notificar: false);
      }
    }
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
    return t.sentido == Sentido.ida ? [t.garagem, ...casas, ...escolasPos] : [t.garagem, ...escolasPos, ...casas];
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
    for (final a in alunosDoDia(t)) {
      if (situacoes[a.id] == SituacaoAluno.avisado) continue;
      porEndereco.putIfAbsent(a.posicao, () => []).add(a);
    }
    for (final grupo in porEndereco.values) {
      casas.add(
        Parada(
          tipo: TipoParada.casa,
          titulo: grupo.map((a) => a.primeiro).join(' e '),
          subtitulo: grupo.first.endereco,
          posicao: grupo.first.posicao,
          alunoIds: grupo.map((a) => a.id).toList(),
        ),
      );
    }
    final presentes = alunosDoDia(t).where((a) => situacoes[a.id] != SituacaoAluno.avisado);
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

  // ------------------------------------------- execução em outro aparelho

  /// Vans desta conta em viagem em outro celular agora (ex.: o motorista trocou de aparelho).
  /// Cada van pertence a um só motorista; nenhuma é compartilhada com outros.
  final execucoesRemotas = <String, ExecucaoRemota>{};

  /// Motivo para pedir confirmação antes de iniciar (null = pode iniciar direto).
  String? conflitoAoIniciar(Trajeto t) {
    final v = viagem;
    if (v != null && !v.encerrada && v.trajeto.id != t.id) {
      return 'Você já está em viagem (${v.trajeto.nome}). Ela será encerrada para iniciar ${t.nome}.';
    }
    final remota = execucoesRemotas[t.veiculoId];
    if (remota != null) {
      return 'Esta van já está em viagem ("${remota.trajetoNome}") em ${remota.quem} desde ${hora(remota.desde)}. '
          'Iniciar aqui também pode confundir a localização e os avisos das famílias.';
    }
    return null;
  }

  /// Este aparelho assume a van; o outro deixa de transmitir.
  void assumirVan(String veiculoId) {
    execucoesRemotas.remove(veiculoId);
    notifyListeners();
  }

  /// Durante a viagem: se o GPS desligar, a posição para de ir para as famílias.
  bool gpsDesligado = false;
  StreamSubscription<bool>? _gpsAssinatura;

  void _monitorarGps() {
    _gpsAssinatura?.cancel();
    gpsDesligado = false;
    try {
      _gpsAssinatura = localizacao.gpsLigado.listen((ligado) {
        gpsDesligado = !ligado;
        sinalFraco = !ligado;
        if (ligado) _enviarLocalizacao();
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {
      // Plataforma sem aviso de GPS (ex.: navegador): segue sem monitorar.
    }
  }

  void iniciarViagem(Trajeto t) {
    encerrarViagem(silencioso: true);
    execucoesRemotas.remove(t.veiculoId);
    sinalFraco = false;
    localizacaoAtrasada = false;
    ultimaLocalizacaoEm = DateTime.now();
    aproximacaoAvisada.clear();
    final situacoes = <String, SituacaoAluno>{
      for (final a in alunosDoDia(t)) a.id: ausenciaHoje(a.id, t.sentido) != null ? SituacaoAluno.avisado : SituacaoAluno.aguardando,
    };
    final v = Viagem(trajeto: t, paradas: _montarParadas(t, situacoes), situacoes: situacoes);
    v.eventos.insert(0, EventoViagem(TipoEvento.partida, 'Viagem ${t.nome} iniciada'));
    final avisados = situacoes.values.where((s) => s == SituacaoAluno.avisado).length;
    if (avisados > 0) {
      v.eventos.insert(0, EventoViagem(TipoEvento.aviso, '$avisados aluno(s) com ausência avisada — paradas puladas'));
    }
    viagem = v;
    posicaoVan.value = v.posicao;
    posicaoCompartilhada.value = v.posicao;
    _anunciarProxima(v);
    _relogio = Timer.periodic(const Duration(milliseconds: 50), (_) => _avancar());
    _monitorarGps();
    notificarResponsaveis(
      alunosDoDia(t).map((a) => a.id).toList(),
      TipoAviso.viagem,
      'A van saiu',
      '${t.nome}: acompanhe ao vivo no mapa.',
    );
    notifyListeners();
  }

  // ------------------------------------------------ sinal e aproximação

  /// Demonstração: simula o celular do motorista sem internet/GPS.
  bool sinalFraco = false;
  DateTime? ultimaLocalizacaoEm;
  bool localizacaoAtrasada = false;
  static const limiteAtraso = Duration(seconds: 20);

  void alternarSinalFraco() {
    sinalFraco = !sinalFraco;
    if (!sinalFraco) _enviarLocalizacao();
    notifyListeners();
  }

  void _enviarLocalizacao() {
    final v = viagem;
    if (v == null) return;
    ultimaLocalizacaoEm = DateTime.now();
    posicaoCompartilhada.value = v.posicao;
    if (localizacaoAtrasada) {
      localizacaoAtrasada = false;
      notifyListeners();
    }
  }

  /// Segundos desde a última localização recebida pelas famílias.
  int get segundosSemLocalizacao => ultimaLocalizacaoEm == null ? 0 : DateTime.now().difference(ultimaLocalizacaoEm!).inSeconds;

  /// Aviso manual do motorista: "estou chegando".
  final aproximacaoAvisada = <String, DateTime>{};

  void notificarAproximacao(Parada p) {
    final v = viagem;
    if (v == null) return;
    for (final id in p.alunoIds) {
      aproximacaoAvisada[id] = DateTime.now();
    }
    v.eventos.insert(0, EventoViagem(TipoEvento.aviso, 'Responsáveis de ${p.titulo} avisados: van chegando'));
    notificarResponsaveis(p.alunoIds, TipoAviso.viagem, 'A van está chegando! 🚐', 'Hora de descer com a mochila.');
    notifyListeners();
  }

  /// Paradas que a van ainda faz antes da casa do aluno (null = não se aplica).
  int? paradasAte(String alunoId) {
    final v = viagem;
    if (v == null || v.encerrada) return null;
    final idx = v.paradas.indexWhere((p) => p.tipo == TipoParada.casa && p.alunoIds.contains(alunoId));
    if (idx < 0) return null;
    final proxima = v.emMovimento ? v.posicao.floor() + 1 : v.posicao.round();
    return math.max(0, idx - proxima);
  }

  void _avancar() {
    final v = viagem;
    if (v == null || v.encerrada) return;
    final alvo = v.posicao.floor() + 1;
    final andando = v.emMovimento && alvo < v.paradas.length;
    if (andando) {
      v.posicao = math.min(alvo.toDouble(), v.posicao + 0.012 * velocidadeSimulacao);
      posicaoVan.value = v.posicao;
    }
    // A cada quadro o celular "envia" a localização; sem sinal, as famílias param de receber.
    if (!sinalFraco) {
      _enviarLocalizacao();
    } else if (!localizacaoAtrasada && segundosSemLocalizacao >= limiteAtraso.inSeconds) {
      localizacaoAtrasada = true;
      notifyListeners();
    }
    if (andando && v.posicao >= alvo) {
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
      v.eventos.insert(0, EventoViagem(TipoEvento.aviso, 'Responsáveis de ${p.titulo} avisados: van a caminho'));
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
        v.eventos.insert(
          0,
          EventoViagem(
            s == SituacaoAluno.entregue ? TipoEvento.desembarque : TipoEvento.embarque,
            '${aluno(id).primeiro} ${s == SituacaoAluno.entregue ? 'desembarcou' : 'embarcou'}',
            alunoId: id,
          ),
        );
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
    _gpsAssinatura?.cancel();
    gpsDesligado = false;
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
    posicaoCompartilhada.dispose();
    _relogio?.cancel();
    _seguirDepois?.cancel();
    _gpsAssinatura?.cancel();
    super.dispose();
  }
}

/// Disponibiliza a store para a árvore e reconstrói quem depende dela.
class VanScope extends InheritedNotifier<VanStore> {
  const VanScope({super.key, required VanStore store, required super.child}) : super(notifier: store);

  static VanStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<VanScope>()!.notifier!;

  static VanStore read(BuildContext context) => context.getInheritedWidgetOfExactType<VanScope>()!.notifier!;
}
