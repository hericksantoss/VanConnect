import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/formatos.dart';
import '../app/tema.dart';

/// Resposta ao toque estilo iOS: encolhe levemente e vibra de leve.
class Tocavel extends StatefulWidget {
  const Tocavel({super.key, required this.child, this.aoTocar, this.escala = 0.97, this.haptico = true});

  final Widget child;
  final VoidCallback? aoTocar;
  final double escala;
  final bool haptico;

  @override
  State<Tocavel> createState() => _TocavelState();
}

class _TocavelState extends State<Tocavel> {
  bool _pressionado = false;

  void _definir(bool v) {
    if (widget.aoTocar != null && v != _pressionado) setState(() => _pressionado = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _definir(true),
      onTapUp: (_) => _definir(false),
      onTapCancel: () => _definir(false),
      onTap: widget.aoTocar == null
          ? null
          : () {
              if (widget.haptico) HapticFeedback.selectionClick();
              widget.aoTocar!();
            },
      child: AnimatedScale(
        scale: _pressionado ? widget.escala : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(opacity: _pressionado ? 0.75 : 1, duration: const Duration(milliseconds: 140), child: widget.child),
      ),
    );
  }
}

/// Ícone em "squircle" no estilo iOS, com fundo suave da própria cor.
class IconeApp extends StatelessWidget {
  const IconeApp(this.icone, {super.key, required this.cor, this.tamanho = 30, this.solido = false});

  final IconData icone;
  final Color cor;
  final double tamanho;

  /// Fundo cheio (para destaque); por padrão é suave, minimalista.
  final bool solido;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: ShapeDecoration(
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(tamanho * 0.5)),
        color: solido ? cor : p.suave(cor),
      ),
      child: Icon(icone, color: solido ? Colors.white : cor, size: tamanho * 0.56),
    );
  }
}

/// Página com título grande que encolhe ao rolar (igual no Android e no iPhone).
class PaginaIOS extends StatelessWidget {
  const PaginaIOS({super.key, required this.titulo, required this.filhos, this.acao, this.voltar = false, this.rodape});

  final String titulo;
  final List<Widget> filhos;
  final Widget? acao;
  final bool voltar;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Scaffold(
      backgroundColor: p.fundo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: p.fundo,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: voltar ? 64 : 0,
            leading: voltar ? const BotaoVoltar() : null,
            actions: [?acao, const SizedBox(width: 12)],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList(delegate: SliverChildListDelegate(filhos)),
          ),
        ],
      ),
      bottomNavigationBar: rodape,
    );
  }
}

/// Botão de voltar redondo e suave.
class BotaoVoltar extends StatelessWidget {
  const BotaoVoltar({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Center(
      child: Tocavel(
        aoTocar: () => Navigator.of(context).maybePop(),
        escala: 0.9,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.cartao,
            shape: BoxShape.circle,
            border: Border.all(color: p.separador),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: p.texto),
        ),
      ),
    );
  }
}

/// Grupo de linhas com cantos arredondados (lista "inset grouped" do iOS).
class Secao extends StatelessWidget {
  const Secao({super.key, this.titulo, required this.filhos, this.rodape, this.recuo = 58});

  final String? titulo;
  final List<Widget> filhos;
  final String? rodape;
  final double recuo;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
              child: Text(
                titulo!.toUpperCase(),
                style: TextStyle(color: p.textoSuave, fontSize: 12.5, letterSpacing: 0.2, fontWeight: FontWeight.w500),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: p.cartao,
              child: Column(
                children: [
                  for (var i = 0; i < filhos.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: EdgeInsets.only(left: recuo),
                        child: Divider(color: p.separador),
                      ),
                    filhos[i],
                  ],
                ],
              ),
            ),
          ),
          if (rodape != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
              child: Text(rodape!, style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class Linha extends StatelessWidget {
  const Linha({super.key, required this.titulo, this.subtitulo, this.inicio, this.fim, this.aoTocar, this.seta, this.corTitulo});

  final String titulo;
  final String? subtitulo;
  final Widget? inicio;
  final Widget? fim;
  final VoidCallback? aoTocar;
  final bool? seta;
  final Color? corTitulo;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final mostrarSeta = seta ?? aoTocar != null;
    return Tocavel(
      aoTocar: aoTocar,
      escala: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (inicio != null) ...[inicio!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 16.5, letterSpacing: -0.3, color: corTitulo ?? p.texto, fontWeight: FontWeight.w500),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo!,
                      style: TextStyle(fontSize: 13.5, color: p.textoSuave),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (fim != null) ...[const SizedBox(width: 8), fim!],
            if (mostrarSeta) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 22, color: p.cinza.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.nome, {super.key, this.tamanho = 40});

  final String nome;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final cor = corDoNome(nome, p);
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(cor, Colors.white, 0.25)!, cor],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        iniciais(nome),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: tamanho * 0.38),
      ),
    );
  }
}

class Selo extends StatelessWidget {
  const Selo(this.texto, {super.key, required this.cor, this.icone});

  final String texto;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: p.suave(cor), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 12, color: cor), const SizedBox(width: 4)],
          Text(
            texto,
            style: TextStyle(color: cor, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

enum EstiloBotao { primario, secundario, destrutivo, claro }

class Botao extends StatelessWidget {
  const Botao(this.texto, {super.key, this.aoTocar, this.icone, this.estilo = EstiloBotao.primario, this.compacto = false});

  final String texto;
  final VoidCallback? aoTocar;
  final IconData? icone;
  final EstiloBotao estilo;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final (fundo, frente) = switch (estilo) {
      EstiloBotao.primario => (p.azul, Colors.white),
      EstiloBotao.secundario => (p.suave(p.azul), p.azul),
      EstiloBotao.destrutivo => (p.suave(p.vermelho), p.vermelho),
      EstiloBotao.claro => (Colors.white, Paleta.azulMarca),
    };
    final ativo = aoTocar != null;
    return Tocavel(
      aoTocar: aoTocar,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ativo ? 1 : 0.4,
        child: Container(
          height: compacto ? 40 : 52,
          padding: EdgeInsets.symmetric(horizontal: compacto ? 16 : 20),
          decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(compacto ? 12 : 15)),
          child: Row(
            mainAxisSize: compacto ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icone != null) ...[Icon(icone, color: frente, size: compacto ? 17 : 20), const SizedBox(width: 8)],
              Text(
                texto,
                style: TextStyle(color: frente, fontSize: compacto ? 15 : 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.aoTocar, this.padding = const EdgeInsets.all(16), this.cor});

  final Widget child;
  final VoidCallback? aoTocar;
  final EdgeInsets padding;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final caixa = Container(
      padding: padding,
      decoration: BoxDecoration(color: cor ?? p.cartao, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
    return aoTocar == null ? caixa : Tocavel(aoTocar: aoTocar, child: caixa);
  }
}

class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.titulo, this.texto});

  final IconData icone;
  final String titulo;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icone, size: 44, color: p.cinza),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (texto != null) ...[
            const SizedBox(height: 4),
            Text(
              texto!,
              style: TextStyle(color: p.textoSuave),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class PontoAoVivo extends StatefulWidget {
  const PontoAoVivo({super.key, this.cor});

  final Color? cor;

  @override
  State<PontoAoVivo> createState() => _PontoAoVivoState();
}

class _PontoAoVivoState extends State<PontoAoVivo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.cor ?? context.cores.verde, shape: BoxShape.circle),
      ),
    );
  }
}

/// Logotipo "Van Connect" desenhado em código (funciona no claro e no escuro).
class LogoVanConnect extends StatelessWidget {
  const LogoVanConnect({super.key, this.tamanho = 30, this.sobreEscuro = false});

  final double tamanho;
  final bool sobreEscuro;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final corVan = sobreEscuro || p.escuro ? Colors.white : Paleta.marinhoMarca;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tamanho * 0.34),
          child: Image.asset('assets/icone.png', width: tamanho * 1.3, height: tamanho * 1.3, filterQuality: FilterQuality.medium),
        ),
        SizedBox(width: tamanho * 0.35),
        Text(
          'Van',
          style: TextStyle(fontSize: tamanho, fontWeight: FontWeight.w800, color: corVan, letterSpacing: -1),
        ),
        Text(
          'Connect',
          style: TextStyle(
            fontSize: tamanho,
            fontWeight: FontWeight.w800,
            color: p.escuro || sobreEscuro ? const Color(0xFF5AB0FF) : Paleta.azulMarca,
            letterSpacing: -1,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: tamanho * 0.7),
          child: Icon(
            CupertinoIcons.wifi,
            size: tamanho * 0.6,
            color: p.escuro || sobreEscuro ? const Color(0xFF5AB0FF) : Paleta.azulMarca,
          ),
        ),
      ],
    );
  }
}

/// Barra de abas suave: ícone com "pílula" atrás do item ativo.
class BarraAbas extends StatelessWidget {
  const BarraAbas({super.key, required this.indice, required this.aoMudar, required this.itens, this.topo});

  final int indice;
  final ValueChanged<int> aoMudar;
  final List<BottomNavigationBarItem> itens;
  final Widget? topo;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?topo,
            Container(
              decoration: BoxDecoration(
                color: p.cartao.withValues(alpha: p.escuro ? 0.85 : 0.92),
                border: Border(top: BorderSide(color: p.separador, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      for (final (i, item) in itens.indexed)
                        Expanded(
                          child: Tocavel(
                            escala: 0.92,
                            aoTocar: () {
                              HapticFeedback.selectionClick();
                              aoMudar(i);
                            },
                            child: _ItemAba(item: item, ativo: i == indice),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemAba extends StatelessWidget {
  const _ItemAba({required this.item, required this.ativo});

  final BottomNavigationBarItem item;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final cor = ativo ? p.azul : p.cinza;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: ativo ? p.suave(p.azul) : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: IconTheme(
            data: IconThemeData(color: cor, size: 24),
            child: ativo ? item.activeIcon : item.icon,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: cor, fontWeight: ativo ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }
}

void avisar(BuildContext context, String texto, {IconData icone = CupertinoIcons.checkmark_circle_fill, Color? cor}) {
  HapticFeedback.lightImpact();
  final p = context.cores;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2600),
        content: Row(
          children: [
            Icon(icone, color: cor ?? p.verde, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
}

/// Diálogo de confirmação suave, igual no Android e no iPhone.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String acao,
  bool destrutiva = false,
  String cancelar = 'Cancelar',
}) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) {
      final p = ctx.cores;
      final cor = destrutiva ? p.vermelho : p.azul;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: p.cartao,
              borderRadius: BorderRadius.circular(26),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: p.suave(cor), shape: BoxShape.circle),
                      child: Icon(destrutiva ? Icons.warning_amber_rounded : Icons.help_outline_rounded, color: cor, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: p.texto),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textoSuave, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _BotaoDialogo(
                            cancelar,
                            cor: p.textoSuave,
                            fundo: p.preenchimento,
                            aoTocar: () => Navigator.pop(ctx, false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotaoDialogo(acao, cor: Colors.white, fundo: cor, aoTocar: () => Navigator.pop(ctx, true)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
  return ok ?? false;
}

class _BotaoDialogo extends StatelessWidget {
  const _BotaoDialogo(this.texto, {required this.cor, required this.fundo, required this.aoTocar});

  final String texto;
  final Color cor;
  final Color fundo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Tocavel(
    aoTocar: aoTocar,
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 15.5),
      ),
    ),
  );
}

class OpcaoAcao<T> {
  const OpcaoAcao(this.rotulo, this.valor, {this.destrutiva = false, this.icone});

  final String rotulo;
  final T valor;
  final bool destrutiva;
  final IconData? icone;
}

/// Lista de escolhas que sobe de baixo, em cartão suave.
Future<T?> escolherAcao<T>(BuildContext context, {String? titulo, String? mensagem, required List<OpcaoAcao<T>> opcoes}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final p = ctx.cores;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo != null)
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.texto),
              ),
            if (mensagem != null) ...[
              const SizedBox(height: 4),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textoSuave),
              ),
            ],
            Secao(
              recuo: 16,
              filhos: [
                for (final o in opcoes)
                  Linha(
                    inicio: o.icone == null ? null : IconeApp(o.icone!, cor: o.destrutiva ? p.vermelho : p.azul),
                    titulo: o.rotulo,
                    corTitulo: o.destrutiva ? p.vermelho : null,
                    seta: false,
                    aoTocar: () => Navigator.pop(ctx, o.valor),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _BotaoDialogo('Cancelar', cor: p.textoSuave, fundo: p.preenchimento, aoTocar: () => Navigator.pop(ctx)),
          ],
        ),
      );
    },
  );
}

/// Abre uma página com a transição padrão de cada sistema.
Future<T?> abrir<T>(BuildContext context, Widget pagina) => Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => pagina));

/// Abre uma folha (sheet) que sobe de baixo.
Future<T?> abrirFolha<T>(BuildContext context, Widget conteudo) =>
    showModalBottomSheet<T>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => conteudo);

/// Seletor segmentado em "pílula", com o marcador deslizando entre as opções.
class Segmentos<T extends Object> extends StatelessWidget {
  const Segmentos({super.key, required this.valor, required this.opcoes, required this.aoMudar});

  final T valor;
  final Map<T, String> opcoes;
  final ValueChanged<T> aoMudar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final chaves = opcoes.keys.toList();
    final indice = chaves.indexOf(valor).clamp(0, chaves.length - 1);
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.preenchimento, borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (context, c) {
          final largura = c.maxWidth / chaves.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: largura * indice,
                top: 0,
                bottom: 0,
                width: largura,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.escuro ? p.elevado : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, k) in chaves.indexed)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (k == valor) return;
                          HapticFeedback.selectionClick();
                          aoMudar(k);
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              opcoes[k]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i == indice ? p.texto : p.textoSuave,
                                fontWeight: i == indice ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chave liga/desliga suave (mesmo visual no Android e no iPhone).
class Chave extends StatelessWidget {
  const Chave({super.key, required this.valor, required this.aoMudar});

  final bool valor;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Tocavel(
      escala: 0.95,
      aoTocar: () => aoMudar(!valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: valor ? p.azul : p.preenchimento, borderRadius: BorderRadius.circular(99)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Escolha de horário em grade (hora e minutos), sem roleta.
/// Retorna minutos desde meia-noite, ou null se cancelar.
Future<int?> escolherHorario(BuildContext context, int minutos) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _GradeHorario(inicial: minutos),
  );
}

class _GradeHorario extends StatefulWidget {
  const _GradeHorario({required this.inicial});

  final int inicial;

  @override
  State<_GradeHorario> createState() => _GradeHorarioState();
}

class _GradeHorarioState extends State<_GradeHorario> {
  late int _hora = widget.inicial ~/ 60;
  late int _minuto = (widget.inicial % 60) ~/ 5 * 5;

  Widget _opcao(String texto, bool marcado, VoidCallback aoTocar) {
    final p = context.cores;
    return Tocavel(
      escala: 0.92,
      aoTocar: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: marcado ? p.azul : p.preenchimento, borderRadius: BorderRadius.circular(12)),
        child: Text(
          texto,
          style: TextStyle(color: marcado ? Colors.white : p.texto, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${doisDigitos(_hora)}:${doisDigitos(_minuto)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1, color: p.texto),
          ),
          const SizedBox(height: 12),
          Text(
            'Hora',
            style: TextStyle(color: p.textoSuave, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.5,
            children: [for (var h = 0; h < 24; h++) _opcao(doisDigitos(h), h == _hora, () => setState(() => _hora = h))],
          ),
          const SizedBox(height: 14),
          Text(
            'Minutos',
            style: TextStyle(color: p.textoSuave, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.5,
            children: [for (var m = 0; m < 60; m += 5) _opcao(doisDigitos(m), m == _minuto, () => setState(() => _minuto = m))],
          ),
          const SizedBox(height: 18),
          Botao('Confirmar', icone: Icons.check_rounded, aoTocar: () => Navigator.pop(context, _hora * 60 + _minuto)),
        ],
      ),
    );
  }
}

/// Folha de formulário: título com botão de fechar e "Salvar" grande no fim.
class Formulario extends StatelessWidget {
  const Formulario({
    super.key,
    required this.titulo,
    required this.campos,
    required this.aoSalvar,
    this.podeSalvar = true,
    this.aoExcluir,
    this.rotuloSalvar = 'Salvar',
  });

  final String titulo;
  final List<Widget> campos;
  final VoidCallback aoSalvar;
  final bool podeSalvar;
  final VoidCallback? aoExcluir;
  final String rotuloSalvar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.texto),
                  ),
                ),
                Tocavel(
                  aoTocar: () => Navigator.pop(context),
                  escala: 0.9,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: p.preenchimento, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 20, color: p.textoSuave),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...campos,
            const SizedBox(height: 16),
            Botao(rotuloSalvar, icone: Icons.check_rounded, aoTocar: podeSalvar ? aoSalvar : null),
            if (aoExcluir != null) ...[
              const SizedBox(height: 10),
              Botao(
                'Excluir',
                estilo: EstiloBotao.destrutivo,
                icone: Icons.delete_outline_rounded,
                aoTocar: () async {
                  if (await confirmar(
                    context,
                    titulo: 'Excluir?',
                    mensagem: 'Essa ação não pode ser desfeita.',
                    acao: 'Excluir',
                    destrutiva: true,
                  )) {
                    aoExcluir!();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.controle,
    required this.rotulo,
    required this.icone,
    this.aoMudar,
    this.teclado,
    this.maiusculas = false,
    this.formatadores,
    this.erro,
    this.oculto = false,
    this.nomes = false,
  });

  final TextEditingController controle;
  final String rotulo;
  final IconData icone;
  final VoidCallback? aoMudar;
  final TextInputType? teclado;
  final bool maiusculas;
  final List<TextInputFormatter>? formatadores;

  /// Mensagem de erro embaixo do campo (null = sem erro).
  final String? erro;

  /// Campo de senha.
  final bool oculto;

  /// Nomes próprios: primeira letra de cada palavra maiúscula.
  final bool nomes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controle,
        keyboardType: teclado,
        obscureText: oculto,
        inputFormatters: formatadores,
        textCapitalization: maiusculas
            ? TextCapitalization.characters
            : nomes
            ? TextCapitalization.words
            : (teclado == null && !oculto ? TextCapitalization.sentences : TextCapitalization.none),
        onChanged: (_) => aoMudar?.call(),
        decoration: InputDecoration(hintText: rotulo, prefixIcon: Icon(icone, size: 20), errorText: erro, errorMaxLines: 2),
      ),
    );
  }
}
