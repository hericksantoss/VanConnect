import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/tema.dart';
import '../componentes/ui.dart';
import 'conteudo.dart';

/// Controla quando cada tutorial aparece.
///
/// - Aparece quando a pessoa toca na aba (nunca sozinho na abertura do app).
/// - No máximo uma vez por uso do app, para não atrapalhar.
/// - "Não mostrar novamente" fica salvo no aparelho.
class Tutoriais {
  Tutoriais._(this._prefs);

  static Tutoriais? _instancia;

  /// Carrega as preferências salvas. Chamado uma vez no `main`.
  static Future<void> iniciar() async {
    _instancia = Tutoriais._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;
  final _vistosNesteUso = <String>{};

  static String _chavePref(String tutorial) => 'tutorial.$tutorial.oculto';

  bool _oculto(String chave) => _prefs.getBool(_chavePref(chave)) ?? false;

  /// Mostra o tutorial da aba se ele não foi ocultado nem visto agora há pouco.
  static Future<void> aoAbrirAba(BuildContext context, String chave) async {
    final t = _instancia;
    final tutorial = tutoriais[chave];
    if (t == null || tutorial == null || t._oculto(chave) || t._vistosNesteUso.contains(chave)) return;
    t._vistosNesteUso.add(chave);

    // Deixa a troca de aba terminar antes do pop-up subir.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!context.mounted) return;

    final naoMostrar = await mostrarTutorial(context, tutorial);
    if (naoMostrar) await t._prefs.setBool(_chavePref(chave), true);
  }

  /// Volta a exibir todos os tutoriais.
  static Future<void> reativarTodos() async {
    final t = _instancia;
    if (t == null) return;
    for (final chave in tutoriais.keys) {
      await t._prefs.remove(_chavePref(chave));
    }
    t._vistosNesteUso.clear();
  }

  /// Quantos tutoriais estão marcados como "não mostrar novamente".
  static int get ocultos => _instancia == null ? 0 : tutoriais.keys.where(_instancia!._oculto).length;
}

/// Abre o pop-up. Retorna true se a caixinha "Não mostrar novamente" ficou marcada.
Future<bool> mostrarTutorial(BuildContext context, Tutorial tutorial) async {
  final resultado = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar tutorial',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => _PopupTutorial(tutorial: tutorial),
    transitionBuilder: (_, anim, _, child) {
      final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curva), child: child),
        ),
      );
    },
  );
  return resultado ?? false;
}

class _PopupTutorial extends StatefulWidget {
  const _PopupTutorial({required this.tutorial});

  final Tutorial tutorial;

  @override
  State<_PopupTutorial> createState() => _PopupTutorialState();
}

class _PopupTutorialState extends State<_PopupTutorial> {
  final _paginas = PageController();
  int _atual = 0;
  bool _naoMostrar = false;

  List<PassoTutorial> get _passos => widget.tutorial.passos;
  bool get _ultimo => _atual == _passos.length - 1;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _irPara(int i) => _paginas.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);

  void _fechar() => Navigator.of(context).pop(_naoMostrar);

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: p.cartao,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(children: [
                    Icon(CupertinoIcons.lightbulb_fill, size: 16, color: p.azul),
                    const SizedBox(width: 6),
                    Text('Como usar · ${widget.tutorial.aba}',
                        style: TextStyle(color: p.azul, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const Spacer(),
                    Text('${_atual + 1}/${_passos.length}', style: TextStyle(color: p.textoSuave, fontSize: 13)),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(36, 36),
                      onPressed: _fechar,
                      child: Icon(CupertinoIcons.xmark_circle_fill, color: p.cinza.withValues(alpha: 0.6), size: 26),
                    ),
                  ]),
                ),
                // Passos (deslizar para os lados)
                SizedBox(
                  height: 330,
                  child: PageView.builder(
                    controller: _paginas,
                    itemCount: _passos.length,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _atual = i);
                    },
                    itemBuilder: (_, i) => _Passo(passo: _passos[i], ativo: i == _atual),
                  ),
                ),
                // Indicador de páginas (tocável)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _passos.length; i++)
                      GestureDetector(
                        onTap: () => _irPara(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                          width: i == _atual ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _atual ? p.azul : p.preenchimento,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                  ],
                ),
                // Caixinha "Não mostrar novamente"
                Tocavel(
                  aoTocar: () => setState(() => _naoMostrar = !_naoMostrar),
                  escala: 0.98,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _naoMostrar ? p.azul : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _naoMostrar ? p.azul : p.cinza.withValues(alpha: 0.6), width: 1.6),
                          ),
                          child: _naoMostrar ? const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 10),
                        Text('Não mostrar novamente', style: TextStyle(color: p.texto, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                // Botões
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _atual == 0
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Botao('Voltar', estilo: EstiloBotao.secundario, aoTocar: () => _irPara(_atual - 1)),
                            ),
                    ),
                    Expanded(
                      child: Botao(
                        _ultimo ? 'Entendi' : 'Próximo',
                        icone: _ultimo ? CupertinoIcons.checkmark_alt : CupertinoIcons.arrow_right,
                        aoTocar: _ultimo ? _fechar : () => _irPara(_atual + 1),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.passo, required this.ativo});

  final PassoTutorial passo;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    // Rolável: textos longos ou fonte grande do sistema nunca estouram o pop-up.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Ilustração: ícone com "ondas" que pulsam quando o passo entra.
          TweenAnimationBuilder<double>(
            key: ValueKey(ativo),
            tween: Tween(begin: ativo ? 0.6 : 1, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.elasticOut,
            builder: (_, escala, filho) => Transform.scale(scale: escala, child: filho),
            child: SizedBox(
              width: 116,
              height: 116,
              child: Stack(alignment: Alignment.center, children: [
                Container(decoration: BoxDecoration(shape: BoxShape.circle, color: p.suave(p.azul).withValues(alpha: 0.08))),
                Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, color: p.suave(p.azul))),
                IconeApp(passo.icone, cor: p.azul, tamanho: 58, solido: true),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(passo.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.texto)),
          const SizedBox(height: 8),
          Text(passo.texto, textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave, fontSize: 15, height: 1.35)),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, d) in passo.destaques.indexed)
                AnimatedOpacity(
                  opacity: ativo ? 1 : 0,
                  duration: Duration(milliseconds: 300 + i * 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.fundo,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: p.separador),
                    ),
                    child: Text(d, style: TextStyle(color: p.texto, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
