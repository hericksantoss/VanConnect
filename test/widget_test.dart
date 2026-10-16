import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:van_connect/dominio/modelos.dart';
import 'package:van_connect/estado/van_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_connect/main.dart';
import 'package:van_connect/tutoriais/conteudo.dart';
import 'package:van_connect/tutoriais/tutoriais.dart';

void main() {
  testWidgets('entra como motorista e vê a próxima viagem', (tester) async {
    final store = VanStore();
    await tester.pumpWidget(VanConnectApp(store: store));
    expect(find.text('Sou motorista'), findsOneWidget);

    await tester.tap(find.text('Sou motorista'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Iniciar viagem'), findsOneWidget);
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
    store.solicitarVinculo(nomeAluno: 'Pedro Costa', escolaId: 'e1', turno: Turno.manha, endereco: 'Rua Aurora, 45');
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

    test('bloqueio em dois aparelhos', () {
      final store = VanStore();
      final t3 = rota(store, 't3'); // Azulzinha, em uso pelo auxiliar na demonstração
      expect(store.conflitoAoIniciar(t3), contains('Paulo'));
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
}
