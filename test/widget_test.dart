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
    expect(store.veiculos.length, 2);
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
}
