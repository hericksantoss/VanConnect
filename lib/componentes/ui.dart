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
        child: AnimatedOpacity(
          opacity: _pressionado ? 0.75 : 1,
          duration: const Duration(milliseconds: 140),
          child: widget.child,
        ),
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

/// Página com título grande que encolhe ao rolar e barra translúcida (blur).
class PaginaIOS extends StatelessWidget {
  const PaginaIOS({
    super.key,
    required this.titulo,
    required this.filhos,
    this.acao,
    this.voltar = false,
    this.rodape,
  });

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
          CupertinoSliverNavigationBar(
            largeTitle: Text(titulo),
            backgroundColor: p.fundo.withValues(alpha: 0.82),
            border: null,
            automaticallyImplyLeading: voltar,
            previousPageTitle: voltar ? 'Voltar' : null,
            trailing: acao,
            stretch: true,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList(delegate: SliverChildListDelegate(filhos)),
          ),
        ],
      ),
      bottomNavigationBar: rodape,
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
              child: Text(titulo!.toUpperCase(),
                  style: TextStyle(color: p.textoSuave, fontSize: 12.5, letterSpacing: 0.2, fontWeight: FontWeight.w500)),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: p.cartao,
              child: Column(
                children: [
                  for (var i = 0; i < filhos.length; i++) ...[
                    if (i > 0) Padding(padding: EdgeInsets.only(left: recuo), child: Divider(color: p.separador)),
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
  const Linha({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.inicio,
    this.fim,
    this.aoTocar,
    this.seta,
    this.corTitulo,
  });

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
                  Text(titulo,
                      style: TextStyle(fontSize: 16.5, letterSpacing: -0.3, color: corTitulo ?? p.texto, fontWeight: FontWeight.w500)),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitulo!, style: TextStyle(fontSize: 13.5, color: p.textoSuave), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (fim != null) ...[const SizedBox(width: 8), fim!],
            if (mostrarSeta) ...[
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_right, size: 16, color: p.cinza.withValues(alpha: 0.7)),
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
      child: Text(iniciais(nome),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: tamanho * 0.38)),
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
          Text(texto, style: TextStyle(color: cor, fontSize: 12.5, fontWeight: FontWeight.w600)),
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
              Text(texto,
                  style: TextStyle(color: frente, fontSize: compacto ? 15 : 17, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
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
          Text(titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          if (texto != null) ...[
            const SizedBox(height: 4),
            Text(texto!, style: TextStyle(color: p.textoSuave), textAlign: TextAlign.center),
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
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

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
        IconeApp(CupertinoIcons.bus, cor: Paleta.azulMarca, tamanho: tamanho * 1.25, solido: true),
        SizedBox(width: tamanho * 0.35),
        Text('Van', style: TextStyle(fontSize: tamanho, fontWeight: FontWeight.w800, color: corVan, letterSpacing: -1)),
        Text('Connect',
            style: TextStyle(fontSize: tamanho, fontWeight: FontWeight.w800, color: p.escuro || sobreEscuro ? const Color(0xFF5AB0FF) : Paleta.azulMarca, letterSpacing: -1)),
        Padding(
          padding: EdgeInsets.only(bottom: tamanho * 0.7),
          child: Icon(CupertinoIcons.wifi, size: tamanho * 0.6, color: p.escuro || sobreEscuro ? const Color(0xFF5AB0FF) : Paleta.azulMarca),
        ),
      ],
    );
  }
}

/// Barra de abas translúcida com blur, como no iPhone.
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
            CupertinoTabBar(
              currentIndex: indice,
              onTap: (i) {
                HapticFeedback.selectionClick();
                aoMudar(i);
              },
              items: itens,
              activeColor: p.azul,
              inactiveColor: p.cinza,
              iconSize: 26,
              height: 54,
              backgroundColor: p.cartao.withValues(alpha: p.escuro ? 0.8 : 0.88),
              border: Border(top: BorderSide(color: p.separador, width: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

void avisar(BuildContext context, String texto, {IconData icone = CupertinoIcons.checkmark_circle_fill, Color? cor}) {
  HapticFeedback.lightImpact();
  final p = context.cores;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 2600),
      content: Row(
        children: [
          Icon(icone, color: cor ?? p.verde, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    ));
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String acao,
  bool destrutiva = false,
}) async {
  final ok = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => CupertinoAlertDialog(
      title: Text(titulo),
      content: Padding(padding: const EdgeInsets.only(top: 6), child: Text(mensagem)),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        CupertinoDialogAction(
          isDefaultAction: !destrutiva,
          isDestructiveAction: destrutiva,
          onPressed: () => Navigator.pop(context, true),
          child: Text(acao),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class OpcaoAcao<T> {
  const OpcaoAcao(this.rotulo, this.valor, {this.destrutiva = false});

  final String rotulo;
  final T valor;
  final bool destrutiva;
}

/// Folha de ações do iOS (escolhas rápidas vindas de baixo).
Future<T?> escolherAcao<T>(BuildContext context, {String? titulo, String? mensagem, required List<OpcaoAcao<T>> opcoes}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: titulo == null ? null : Text(titulo),
      message: mensagem == null ? null : Text(mensagem),
      actions: [
        for (final o in opcoes)
          CupertinoActionSheetAction(
            isDestructiveAction: o.destrutiva,
            onPressed: () => Navigator.pop(context, o.valor),
            child: Text(o.rotulo),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
    ),
  );
}

/// Abre uma página com a transição lateral do iOS.
Future<T?> abrir<T>(BuildContext context, Widget pagina) =>
    Navigator.of(context).push<T>(CupertinoPageRoute(builder: (_) => pagina));

/// Abre uma folha (sheet) que sobe de baixo, como os modais do iOS.
Future<T?> abrirFolha<T>(BuildContext context, Widget conteudo) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => conteudo,
    );

/// Controle segmentado do iOS, já com as cores do tema.
class Segmentos<T extends Object> extends StatelessWidget {
  const Segmentos({super.key, required this.valor, required this.opcoes, required this.aoMudar});

  final T valor;
  final Map<T, String> opcoes;
  final ValueChanged<T> aoMudar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: valor,
        backgroundColor: p.preenchimento,
        thumbColor: p.escuro ? p.elevado : Colors.white,
        onValueChanged: (v) {
          if (v != null) {
            HapticFeedback.selectionClick();
            aoMudar(v);
          }
        },
        children: {
          for (final e in opcoes.entries)
            e.key: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(e.value, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.texto, fontSize: 14)),
            ),
        },
      ),
    );
  }
}

/// Roleta de horário do iOS. Retorna minutos desde meia-noite (ou null se cancelar).
Future<int?> escolherHorario(BuildContext context, int minutos) async {
  var escolhido = minutos;
  final ok = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (ctx) => Container(
      height: 300,
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(children: [
              CupertinoButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx, false)),
              const Spacer(),
              CupertinoButton(child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)), onPressed: () => Navigator.pop(ctx, true)),
            ]),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(brightness: context.cores.escuro ? Brightness.dark : Brightness.light),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 5,
                  initialDateTime: DateTime(2000, 1, 1, minutos ~/ 60, (minutos % 60) ~/ 5 * 5),
                  onDateTimeChanged: (d) => escolhido = d.hour * 60 + d.minute,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true ? escolhido : null;
}

/// Folha de formulário no padrão iOS: Cancelar · Título · Salvar.
class Formulario extends StatelessWidget {
  const Formulario({
    super.key,
    required this.titulo,
    required this.campos,
    required this.aoSalvar,
    this.podeSalvar = true,
    this.aoExcluir,
  });

  final String titulo;
  final List<Widget> campos;
  final VoidCallback aoSalvar;
  final bool podeSalvar;
  final VoidCallback? aoExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              Expanded(
                child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: podeSalvar ? aoSalvar : null,
                child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 8),
            ...campos,
            if (aoExcluir != null)
              Secao(
                recuo: 14,
                filhos: [
                  Linha(
                    titulo: 'Excluir',
                    corTitulo: p.vermelho,
                    seta: false,
                    aoTocar: () async {
                      if (await confirmar(context, titulo: 'Excluir?', mensagem: 'Essa ação não pode ser desfeita.', acao: 'Excluir', destrutiva: true)) {
                        aoExcluir!();
                      }
                    },
                  ),
                ],
              ),
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
  });

  final TextEditingController controle;
  final String rotulo;
  final IconData icone;
  final VoidCallback? aoMudar;
  final TextInputType? teclado;
  final bool maiusculas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controle,
        keyboardType: teclado,
        textCapitalization: maiusculas
            ? TextCapitalization.characters
            : (teclado == null ? TextCapitalization.sentences : TextCapitalization.none),
        onChanged: (_) => aoMudar?.call(),
        decoration: InputDecoration(hintText: rotulo, prefixIcon: Icon(icone, size: 20)),
      ),
    );
  }
}
