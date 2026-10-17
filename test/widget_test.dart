import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:van_connect/dominio/modelos.dart';
import 'package:van_connect/estado/van_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_connect/app/validacoes.dart';
import 'package:van_connect/componentes/mascaras.dart';
import 'package:van_connect/main.dart';
import 'package:van_connect/servicos/autenticacao_servico.dart';
import 'package:van_connect/servicos/endereco_servico.dart';
import 'package:van_connect/servicos/localizacao_servico.dart';
import 'package:van_connect/servicos/sessao_salva.dart';
import 'package:van_connect/tutoriais/conteudo.dart';
import 'package:van_connect/tutoriais/tutoriais.dart';

void main() {
  testWidgets('entra como motorista e vê a próxima viagem', (tester) async {
    final store = VanStore();
    await tester.pumpWidget(VanConnectApp(store: store));
    expect(find.text('Sou motorista'), findsOneWidget);

    // Conta (Google simulado) → dados pessoais → van → app do motorista.
    await tester.tap(find.text('Sou motorista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome completo'), 'Carlos Lima');
    await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'carlos@exemplo.com');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Seus dados'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'CPF'), '52998224724');
    await tester.enterText(find.widgetWithText(TextField, 'RG'), '12.345.678-9');
    await tester.enterText(find.widgetWithText(TextField, 'WhatsApp'), '11977776666');
    await tester.ensureVisible(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('CPF inválido — confira os números'), findsOneWidget, reason: 'dígito verificador errado');

    await tester.enterText(find.widgetWithText(TextField, '529.982.247-24'), '52998224725');
    await tester.ensureVisible(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Sua van'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'Modelo e ano (ex.: Sprinter 2020)'), 'Ducato 2021');
    await tester.enterText(find.widgetWithText(TextField, 'Placa'), 'abc1d23');
    await tester.ensureVisible(find.text('Concluir cadastro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir cadastro'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Iniciar viagem'), findsOneWidget);
    expect(store.nomeMotorista, 'Carlos Lima');
    expect(store.cpfMotorista, '52998224725');
    expect(store.veiculo.placa, 'ABC1D23');
    expect(store.conta?.provedor, ProvedorLogin.google);
  });

  testWidgets('responsável cria a conta e só entra com o código da van', (tester) async {
    final store = VanStore();
    final convite = store.gerarConvite(['a3']);
    await tester.pumpWidget(VanConnectApp(store: store));
    await tester.tap(find.text('Sou responsável'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar com Facebook'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome completo'), 'Rafael Almeida');
    await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'rafael@exemplo.com');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Sem código não há app: a tela pede o convite ou o VAN-….
    expect(find.text('Código da van'), findsOneWidget);
    expect(store.perfil, isNull);
    await tester.enterText(find.byType(TextField), 'K00-000');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Convite não encontrado'), findsOneWidget);

    await tester.enterText(find.byType(TextField), convite.codigo);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Aceitar convite'), findsOneWidget);
    expect(store.conta?.provedor, ProvedorLogin.facebook);
  });

  testWidgets('modo escuro troca a paleta', (tester) async {
    final store = VanStore()..definirTema(ThemeMode.dark);
    await tester.pumpWidget(VanConnectApp(store: store));
    await tester.pump(const Duration(milliseconds: 600));
    final contexto = tester.element(find.text('Sou responsável'));
    expect(Theme.of(contexto).brightness, Brightness.dark);
  });

  test('viagem pula ausência avisada e agrupa irmãos', () {
    final store = VanStore();
    store.iniciarViagem(store.trajetos.firstWhere((t) => t.id == 't1'));
    final v = store.viagem!;
    expect(v.situacoes['a6'], SituacaoAluno.avisado);
    expect(v.paradas.any((p) => p.alunoIds.contains('a6') && p.tipo == TipoParada.casa), isFalse);
    expect(v.paradas.first.alunoIds, containsAll(['a1', 'a2']));
    store.dispose();
  });

  test('código da van aceita variações de digitação', () {
    final store = VanStore();
    expect(store.codigoValido('van 4821'), isTrue);
    expect(store.codigoValido('VAN4821'), isTrue);
    expect(store.codigoValido('VAN-1111'), isFalse);
  });

  test('pedido aprovado vira aluno, entra na rota e no perfil do responsável', () {
    final store = VanStore();
    store.solicitarVinculo(nomeAluno: 'Pedro Costa', escolaInformada: 'colegio horizonte', turno: Turno.manha);
    final pedido = store.solicitacoesDoResponsavel.single;
    final rotas = store.aprovar(pedido);
    expect(rotas, isNotEmpty);
    expect(store.filhosDoResponsavel.length, 3);
    expect(store.solicitacoes.contains(pedido), isFalse);
  });

  test('otimizar ordem nunca aumenta o percurso', () {
    final store = VanStore();
    final t = store.trajetos.first;
    t.alunoIds.setAll(0, t.alunoIds.reversed.toList());
    final antes = store.km(t);
    store.otimizarOrdem(t);
    expect(store.km(t), lessThanOrEqualTo(antes));
  });

  test('cadastros: van, escola e rota nova com alunos do turno', () {
    final store = VanStore();
    store.salvarVeiculo(apelido: 'Van 2', modelo: 'Master', placa: 'abc1d23', capacidade: 12);
    expect(store.veiculos.length, 3);
    expect(store.veiculos.last.placa, 'ABC1D23');

    final e = store.salvarEscola(nome: 'Escola Nova', endereco: 'Rua X', entrada: 420, saida: 720);
    expect(store.removerEscola(e), isTrue);

    final t = store.criarTrajeto(turno: Turno.tarde, sentido: Sentido.ida, saida: 750, escolaId: 'e2');
    expect(t.alunoIds, containsAll(['a8', 'a9', 'a10']));
  });

  test('mudar aluno de turno move ele entre as rotas', () {
    final store = VanStore();
    final lucas = store.aluno('a1');
    store.atualizarAluno(lucas, turno: Turno.tarde, escolaId: 'e2');
    expect(store.trajetos.firstWhere((t) => t.id == 't1').alunoIds.contains('a1'), isFalse);
    expect(store.trajetos.firstWhere((t) => t.id == 't3').alunoIds.contains('a1'), isTrue);
  });

  test('há tutorial para todas as abas dos dois perfis', () {
    for (final aba in ['inicio', 'rotas', 'financas', 'gestao']) {
      expect(tutoriais['motorista.$aba']?.passos, isNotEmpty);
    }
    for (final aba in ['mapa', 'filhos', 'avisos', 'pagamentos', 'ajustes']) {
      expect(tutoriais['responsavel.$aba']?.passos, isNotEmpty);
    }
  });

  testWidgets('tutorial aparece ao tocar na aba e respeita "Não mostrar novamente"', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Tutoriais.iniciar();
    final store = VanStore()..escolherPerfil(Perfil.motorista);
    await tester.pumpWidget(VanConnectApp(store: store));
    await tester.pump(const Duration(milliseconds: 600));

    // Nada aparece ao abrir o app.
    expect(find.textContaining('Como usar'), findsNothing);

    await tester.tap(find.text('Rotas').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Como usar · Rotas'), findsOneWidget);

    await tester.tap(find.text('Não mostrar novamente'));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Como usar · Rotas'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('tutorial.motorista.rotas.oculto'), isTrue);
    expect(Tutoriais.ocultos, 1);

    await Tutoriais.reativarTodos();
    expect(Tutoriais.ocultos, 0);
  });

  group('convite da família', () {
    test('irmãos vão juntos e o código tem 6 caracteres sem ambiguidade', () {
      final store = VanStore();
      expect(store.familiaDe(store.aluno('a1')).map((a) => a.id), containsAll(['a1', 'a2']));
      final c = store.gerarConvite(['a3']);
      expect(c.codigo, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
      expect(c.codigoFormatado, contains('-'));
    });

    test('aceitar conecta a família sem aprovação e o convite não pode ser reusado', () {
      final store = VanStore();
      final c = store.gerarConvite(['a3']);
      expect(store.aluno('a3').familiaConectada, isFalse);

      final achado = store.buscarConvite(' ${c.codigo.substring(0, 3).toLowerCase()} ${c.codigo.substring(3)} ');
      expect(achado, same(c));

      store.aceitarConvite(achado!);
      expect(store.aluno('a3').familiaConectada, isTrue);
      expect(store.filhosDoResponsavel, contains('a3'));
      expect(store.solicitacoes.where((s) => s.nomeAluno.contains('Theo')), isEmpty);
      expect(store.buscarConvite(c.codigo), isNull);
    });

    test('cancelado ou vencido não vale; gerar de novo substitui o anterior', () {
      final store = VanStore();
      final c1 = store.gerarConvite(['a4']);
      expect(store.gerarConvite(['a4']), same(c1));

      final c2 = store.gerarConvite(['a4', 'a5']);
      expect(c1.cancelado, isTrue);
      expect(store.buscarConvite(c1.codigo), isNull);

      store.cancelarConvite(c2);
      expect(store.buscarConvite(c2.codigo), isNull);

      final c3 = store.gerarConvite(['a7']);
      expect(c3.valido(DateTime.now().add(VanStore.validadeConvite + const Duration(minutes: 1))), isFalse);
    });

    test('código geral continua indo para aprovação', () {
      expect(VanStore.pareceCodigoGeral('van-4821'), isTrue);
      expect(VanStore.pareceCodigoGeral('K7P-2QX'), isFalse);
    });
  });

  group('ideias do Van Escola', () {
    Trajeto rota(VanStore s, String id) => s.trajetos.firstWhere((t) => t.id == id);

    test('rota do dia muda só hoje e pode virar padrão', () {
      final store = VanStore();
      final t1 = rota(store, 't1');
      store.alternarAlunoHoje(t1, 'a3'); // Theo não vai hoje
      store.alternarAlunoHoje(t1, 'a8'); // Sofia vai só hoje
      final hoje = store.alunosDoDia(t1).map((a) => a.id);
      expect(hoje, isNot(contains('a3')));
      expect(hoje, contains('a8'));
      expect(t1.alunoIds, contains('a3'));
      expect(t1.alunoIds, isNot(contains('a8')));

      store.iniciarViagem(t1);
      expect(store.viagem!.situacoes.keys, containsAll(['a8']));
      expect(store.viagem!.situacoes.keys, isNot(contains('a3')));
      store.descartarViagem();

      store.salvarDiaComoPadrao(t1);
      expect(t1.alunoIds, contains('a8'));
      expect(t1.alunoIds, isNot(contains('a3')));
      expect(store.ajusteDeHoje(t1).vazio, isTrue);
    });

    test('ausência e "marcar presença" travam quando a rota começa', () {
      final store = VanStore();
      final hoje = DateTime.now();
      store.iniciarViagem(rota(store, 't1')); // manhã · ida em andamento

      expect(store.avisarAusencia(alunoId: 'a3', data: hoje, sentido: Sentido.ida), isEmpty);
      expect(store.avisarAusencia(alunoId: 'a3', data: hoje), [Sentido.volta]);

      final daLaura = store.ausencias.firstWhere((a) => a.alunoId == 'a6'); // semente: ida de hoje
      expect(store.removerAusencia(daLaura), isFalse);

      final amanha = hoje.add(const Duration(days: 1));
      expect(store.avisarAusencia(alunoId: 'a3', data: amanha), Sentido.values);
      store.dispose();
    });

    test('paradas restantes e aviso de aproximação', () {
      final store = VanStore();
      store.iniciarViagem(rota(store, 't1'));
      final v = store.viagem!;
      expect(store.paradasAte('a1'), 0); // casa dos irmãos é a primeira parada
      final ultimaCasa = v.paradas.lastWhere((p) => p.tipo == TipoParada.casa);
      expect(store.paradasAte(ultimaCasa.alunoIds.first), greaterThan(0));

      store.notificarAproximacao(v.paradas.first);
      expect(store.aproximacaoAvisada.keys, containsAll(['a1', 'a2']));
      expect(v.eventos.first.texto, contains('van chegando'));
      store.dispose();
    });

    testWidgets('sem sinal: famílias ficam com a última posição recebida', (tester) async {
      final store = VanStore();
      store.iniciarViagem(rota(store, 't1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.posicaoCompartilhada.value, store.posicaoVan.value);

      store.alternarSinalFraco();
      final congelada = store.posicaoCompartilhada.value;
      await tester.pump(const Duration(milliseconds: 500));
      expect(store.posicaoVan.value, greaterThan(congelada));
      expect(store.posicaoCompartilhada.value, congelada);

      store.alternarSinalFraco();
      expect(store.posicaoCompartilhada.value, store.posicaoVan.value);
      store.descartarViagem();
    });

    test('bloqueio da mesma van em dois celulares', () {
      final store = VanStore();
      final t3 = rota(store, 't3');
      // A mesma conta com a van em viagem em outro celular.
      store.execucoesRemotas[t3.veiculoId] = ExecucaoRemota(quem: 'outro celular', desde: DateTime.now(), trajetoNome: 'Tarde · Ida');
      expect(store.conflitoAoIniciar(t3), contains('outro celular'));
      store.assumirVan(t3.veiculoId);
      expect(store.conflitoAoIniciar(t3), isNull);

      store.iniciarViagem(rota(store, 't1'));
      expect(store.conflitoAoIniciar(rota(store, 't2')), contains('já está em viagem'));
      store.dispose();
    });

    test('convite é login e respeita o escopo', () {
      final store = VanStore();
      final avo = store.gerarConvite(['a3'], escopo: Escopo.leitura, nomeConvidado: 'Avó Lúcia');
      final pai = store.gerarConvite(['a3']);
      expect(avo.cancelado, isFalse, reason: 'convite de outro familiar não substitui o do responsável');

      store.entrarComConvite(avo);
      expect(store.perfil, Perfil.responsavel);
      expect(store.filhosDoResponsavel, ['a3']);
      expect(store.nomeSessao, 'Avó Lúcia');
      expect(store.podeAgir, isFalse);

      store.entrarComConvite(pai);
      expect(store.nomeSessao, 'Rafael Almeida');
      expect(store.podeAgir, isTrue);
    });
  });

  group('conta e cadastro', () {
    const carlos = ContaUsuario(id: 'google-carlos', nome: 'Carlos Lima', email: 'carlos@exemplo.com', provedor: ProvedorLogin.google);
    const paula = ContaUsuario(id: 'google-paula', nome: 'Paula Reis', email: 'paula@exemplo.com', provedor: ProvedorLogin.google);

    void cadastrar(VanStore store) => store.concluirCadastroMotorista(
      conta: carlos,
      nome: 'Carlos Lima',
      cpf: '52998224725',
      rg: '123456789',
      cnh: '',
      telefone: '(11) 97777-6666',
      apelidoVan: 'Van amarela',
      modeloVan: 'Ducato 2021',
      placa: 'abc1d23',
      lugares: 16,
    );

    test('CPF, placa, telefone e máscaras', () {
      expect(cpfValido('529.982.247-25'), isTrue);
      expect(cpfValido('529.982.247-24'), isFalse);
      expect(cpfValido('111.111.111-11'), isFalse);
      expect(placaValida('abc1d23'), isTrue);
      expect(placaValida('ABC-1234'), isTrue);
      expect(placaValida('AB-12345'), isFalse);
      expect(formatarPlaca('abc1234'), 'ABC-1234');
      expect(telefoneValido('(11) 98888-1020'), isTrue);
      expect(telefoneValido('98888-1020'), isFalse);
      TextEditingValue digitar(TextInputFormatter f, String t) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t));
      expect(digitar(Mascara.cpf, '52998224725').text, '529.982.247-25');
      expect(digitar(Mascara.telefone, '11988881020').text, '(11) 98888-1020');
      expect(digitar(Mascara.telefone, '1133334444').text, '(11) 3333-4444');
      expect(digitar(MascaraPlaca(), 'abc1234').text, 'ABC-1234');
      expect(digitar(MascaraPlaca(), 'abc1d23').text, 'ABC1D23');
    });

    test('cadastro do motorista vira a van principal e dá boas-vindas', () {
      final store = VanStore();
      cadastrar(store);
      expect(store.perfil, Perfil.motorista);
      expect(store.veiculo.id, 'v1', reason: 'as rotas continuam ligadas à van principal');
      expect(store.veiculo.placa, 'ABC1D23');
      expect(store.veiculo.capacidade, 16);
      expect(store.veiculos, hasLength(1), reason: 'nenhuma van de outro motorista');
      expect(store.trajetos.every((t) => t.veiculoId == store.veiculo.id), isTrue);
      expect(store.motoristaCadastrado(carlos), isTrue);
      expect(store.motoristaCadastrado(paula), isFalse);
      expect(store.avisosMotorista.first.titulo, contains('Carlos'));
    });

    test('responsável novo espera a aprovação e a conta lembra os filhos', () {
      final store = VanStore();
      store.comecarSessaoResponsavel(paula);
      expect(store.filhosDoResponsavel, isEmpty);
      store.solicitarVinculo(nomeAluno: 'Bia Reis', escolaInformada: 'colegio horizonte', turno: Turno.manha);
      store.escolherPerfil(Perfil.responsavel);
      expect(store.aguardandoAprovacao, isTrue);

      final pedido = store.solicitacoesDoResponsavel.single;
      expect(pedido.contaId, paula.id);
      store.aprovar(pedido);
      expect(store.aguardandoAprovacao, isFalse);
      final bia = store.filhosDoResponsavel.single;
      expect(store.aluno(bia).nome, 'Bia Reis');

      store.sair();
      expect(store.perfil, isNull);
      store.comecarSessaoResponsavel(paula);
      expect(store.filhosDoResponsavel, [bia], reason: 'mesma conta, mesmos filhos');
      store.comecarSessaoResponsavel(carlos);
      expect(store.filhosDoResponsavel, isEmpty, reason: 'outra conta precisa do próprio código');
    });

    test('sessão fica salva no aparelho até sair', () async {
      SharedPreferences.setMockInitialValues({});
      await SessaoSalva.iniciar();
      final a = VanStore();
      cadastrar(a);
      await SessaoSalva.salvar(a);

      final b = VanStore();
      SessaoSalva.restaurar(b);
      expect(b.perfil, Perfil.motorista);
      expect(b.conta?.email, 'carlos@exemplo.com');
      expect(b.nomeMotorista, 'Carlos Lima');
      expect(b.veiculo.placa, 'ABC1D23');

      b.sair();
      await SessaoSalva.salvar(b);
      final c = VanStore();
      SessaoSalva.restaurar(c);
      expect(c.perfil, isNull);
    });
  });

  group('endereço, GPS, Pix e pedidos', () {
    test('CEP pelo ViaCEP: encontrado, inexistente e sem internet', () async {
      final servico = EnderecoServico(
        cliente: MockClient((req) async {
          final cep = req.url.pathSegments[1];
          if (cep == '01310100') {
            final corpo = {
              'cep': '01310-100',
              'logradouro': 'Avenida Paulista',
              'bairro': 'Bela Vista',
              'localidade': 'São Paulo',
              'uf': 'SP',
            };
            return http.Response.bytes(utf8.encode(jsonEncode(corpo)), 200);
          }
          if (cep == '99999999') return http.Response('{"erro": "true"}', 200);
          throw http.ClientException('sem internet');
        }),
      );
      final d = await servico.buscarCep('01310-100');
      expect(d.logradouro, 'Avenida Paulista');
      expect(d.cidade, 'São Paulo');
      expect(d.uf, 'SP');
      await expectLater(
        servico.buscarCep('99999-999'),
        throwsA(isA<ErroEndereco>().having((e) => e.mensagem, 'mensagem', 'CEP não encontrado.')),
      );
      await expectLater(
        servico.buscarCep('123'),
        throwsA(isA<ErroEndereco>().having((e) => e.mensagem, 'mensagem', contains('8 números'))),
      );
      await expectLater(
        servico.buscarCep('11111-111'),
        throwsA(isA<ErroEndereco>().having((e) => e.mensagem, 'mensagem', contains('Sem conexão'))),
      );
    });

    test('localização: permissão e GPS desligado no meio da viagem', () async {
      final gps = LocalizacaoFalsa(SituacaoGps.semPermissao);
      expect(await gps.verificar(), SituacaoGps.semPermissao);
      expect(await gps.verificar(pedirPermissao: true), SituacaoGps.pronto);

      final store = VanStore(localizacao: gps);
      store.iniciarViagem(store.trajetos.firstWhere((t) => t.id == 't1'));
      expect(store.gpsDesligado, isFalse);
      gps.mudar(SituacaoGps.desligado);
      await Future<void>.delayed(Duration.zero);
      expect(store.gpsDesligado, isTrue, reason: 'o motorista vê o aviso para ligar a localização');
      gps.mudar(SituacaoGps.pronto);
      await Future<void>.delayed(Duration.zero);
      expect(store.gpsDesligado, isFalse);
      store.dispose();
    });

    test('chave Pix nova avisa e vai junto na cobrança e no lembrete', () {
      final store = VanStore();
      store.salvarChavePix(const ChavePix(tipo: TipoChavePix.email, valor: 'rogerio@pix.com', titular: 'Rogério Nunes'));
      expect(store.avisosMotorista.first.titulo, 'Nova chave Pix adicionada');
      store.salvarChavePix(const ChavePix(tipo: TipoChavePix.email, valor: 'rogerio@pix.com', titular: 'Rogério Nunes'));
      expect(store.avisosMotorista.first.titulo, 'Chave Pix atualizada');

      final atrasadas = store.atrasadas;
      expect(atrasadas, isNotEmpty, reason: 'a demonstração tem mensalidades atrasadas');
      expect(store.cobrarAtrasadas(), atrasadas.length);

      store.filhosDoResponsavel
        ..clear()
        ..add(atrasadas.first.alunoId);
      final cobranca = store.avisosResponsavel.firstWhere((a) => a.tipo == TipoAviso.cobranca);
      expect(cobranca.chavePix, 'rogerio@pix.com');
      expect(cobranca.texto, contains('rogerio@pix.com'));

      final vencendo = store.vencendoEm(40);
      expect(store.lembrarAntesDoVencimento(dias: 40), vencendo);
      expect(store.avisos.where((a) => a.tipo == TipoAviso.lembrete), hasLength(vencendo));

      expect(store.naoLidosResponsavel, greaterThan(0));
      store.marcarAvisosLidos(motorista: false);
      expect(store.naoLidosResponsavel, 0);
    });

    test('pedido com escola errada: motorista corrige e só aprova com o colégio confirmado', () {
      final store = VanStore();
      final pedido = store.solicitacoes.firstWhere((x) => x.id == 's1');
      expect(pedido.escolaId, isNull, reason: '"Colegio Horisonte" não bate com nenhum colégio');
      expect(() => store.aprovar(pedido), throwsStateError);

      final escola = store.escolas.first;
      store.atualizarSolicitacao(pedido, nomeAluno: 'Benício Prado Lima', escolaId: escola.id, turno: Turno.tarde);
      expect(pedido.escolaInformada, 'Colegio Horisonte', reason: 'o que a família escreveu fica registrado');
      store.aprovar(pedido);
      final novo = store.alunos.last;
      expect(novo.nome, 'Benício Prado Lima');
      expect(novo.escolaId, escola.id);
      expect(novo.turno, Turno.tarde);
    });

    test('pedido da família acha o colégio mesmo sem acento', () {
      final store = VanStore();
      expect(store.escolaParecida('colegio   HORIZONTE')?.nome, 'Colégio Horizonte');
      expect(store.escolaParecida('Colégio Horisonte'), isNull);
    });
  });
}
