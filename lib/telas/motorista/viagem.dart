import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/mapa.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

class ViagemTela extends StatelessWidget {
  const ViagemTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final v = store.viagem;
    if (v == null) return Scaffold(backgroundColor: p.fundo);

    final altura = MediaQuery.sizeOf(context).height;
    final familias = v.situacoes.keys.map((id) => store.aluno(id).responsavel.nome).toSet().length;

    return Scaffold(
      backgroundColor: p.fundo,
      body: Stack(
        children: [
          // O mapa escuta só a posição da van: anima a 60 fps sem reconstruir a tela.
          // Só a van e a rota redesenham a cada quadro; as imagens do mapa ficam estáveis.
          MapaTrajeto(
            pontos: [v.trajeto.garagem, ...v.paradas.map((x) => x.posicao)],
            marcadores: [
              MarcadorMapa(v.trajeto.garagem, TipoMarcador.garagem),
              for (final (i, x) in v.paradas.indexed)
                MarcadorMapa(
                  x.posicao,
                  x.tipo == TipoParada.escola ? TipoMarcador.escola : TipoMarcador.casa,
                  concluido: i < v.posicao.round() || (i == v.posicao.round() && !v.emMovimento && v.paradaResolvida(x)),
                ),
            ],
            posicaoAoVivo: store.posicaoVan,
            transmitindo: !v.encerrada && store.compartilharAoIniciar,
            altura: altura * 0.46,
            raio: 0,
            interativo: true,
            margem: const EdgeInsets.fromLTRB(40, 90, 40, 70),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  _BotaoVidro(icone: CupertinoIcons.chevron_down, aoTocar: () => Navigator.pop(context)),
                  const Spacer(),
                  if (!v.encerrada && store.compartilharAoIniciar)
                    _Vidro(
                      child: Row(children: [
                        PontoAoVivo(cor: p.verde),
                        const SizedBox(width: 8),
                        Text('Ao vivo · $familias famílias', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ]),
                    ),
                  const Spacer(),
                  _BotaoVidro(
                    icone: CupertinoIcons.exclamationmark_triangle_fill,
                    cor: p.vermelho,
                    aoTocar: () => _emergencia(context, store),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.58,
            maxChildSize: 0.94,
            snap: true,
            builder: (context, controle) => Container(
              decoration: BoxDecoration(
                color: p.fundo,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20)],
              ),
              child: v.encerrada ? _Resumo(viagem: v, controle: controle) : _Painel(viagem: v, controle: controle),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emergencia(BuildContext context, VanStore store) async {
    final p = context.cores;
    if (store.emergenciaEm != null) {
      if (await confirmar(context, titulo: 'Encerrar emergência?', mensagem: 'As famílias serão avisadas de que está tudo bem.', acao: 'Está tudo bem')) {
        store.encerrarEmergencia();
      }
      return;
    }
    HapticFeedback.heavyImpact();
    if (await confirmar(
      context,
      titulo: 'Alerta de emergência',
      mensagem: 'Enviar agora um alerta para todas as famílias desta viagem?',
      acao: 'Enviar alerta',
      destrutiva: true,
    )) {
      store.dispararEmergencia();
      if (context.mounted) avisar(context, 'Alerta enviado às famílias', icone: CupertinoIcons.exclamationmark_triangle_fill, cor: p.vermelho);
    }
  }
}

class _Vidro extends StatelessWidget {
  const _Vidro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          color: p.cartao.withValues(alpha: 0.72),
          child: DefaultTextStyle.merge(style: TextStyle(color: p.texto), child: child),
        ),
      ),
    );
  }
}

class _BotaoVidro extends StatelessWidget {
  const _BotaoVidro({required this.icone, required this.aoTocar, this.cor});

  final IconData icone;
  final VoidCallback aoTocar;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Tocavel(
      aoTocar: aoTocar,
      escala: 0.9,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 42,
            height: 42,
            color: p.cartao.withValues(alpha: 0.72),
            child: Icon(icone, size: 20, color: cor ?? p.texto),
          ),
        ),
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({required this.viagem, required this.controle});

  final Viagem viagem;
  final ScrollController controle;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final v = viagem;
    final total = v.paradas.length;
    final atual = v.paradaAtual;
    final proximaIdx = v.proximaParada.clamp(0, total - 1);
    final inicioLista = proximaIdx + (atual != null ? 1 : 0);
    final feitas = atual != null ? v.posicao.round() + (v.paradaResolvida(atual) ? 1 : 0) : v.posicao.floor() + 1;

    return ListView(
      controller: controle,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(color: p.cinza.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(9)),
          ),
        ),
        const SizedBox(height: 14),
        if (store.sinalFraco)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Cartao(
              cor: p.suave(p.laranja),
              child: Row(children: [
                Icon(CupertinoIcons.wifi_slash, color: p.laranja),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulando celular sem sinal: as famílias continuam vendo a última posição enviada. '
                    'Toque na antena para voltar.',
                    style: TextStyle(color: p.texto, fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
          ),
        if (store.emergenciaEm != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Cartao(
              cor: p.vermelho,
              child: const Row(children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Emergência ativa — famílias avisadas. Toque no triângulo para encerrar.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.trajeto.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  Text('$feitas de $total paradas · ${v.aBordo} a bordo', style: TextStyle(color: p.textoSuave)),
                ],
              ),
            ),
            // Demonstração: simula o celular perdendo sinal/GPS para ver o aviso no app dos pais.
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: store.alternarSinalFraco,
              child: Icon(
                store.sinalFraco ? CupertinoIcons.wifi_slash : CupertinoIcons.antenna_radiowaves_left_right,
                color: store.sinalFraco ? p.laranja : p.cinza,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                if (await confirmar(context,
                    titulo: 'Encerrar viagem?',
                    mensagem: 'O compartilhamento de localização será desligado.',
                    acao: 'Encerrar',
                    destrutiva: true)) {
                  store.encerrarViagem();
                }
              },
              child: Text('Encerrar', style: TextStyle(color: p.vermelho, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : feitas / total),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, valor, _) => LinearProgressIndicator(
              value: valor,
              minHeight: 6,
              backgroundColor: p.preenchimento,
              color: p.verde,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: atual != null
              ? _CartaoParada(key: ValueKey('p${v.posicao.round()}'), viagem: v, parada: atual)
              : _ACaminho(key: ValueKey('c$proximaIdx'), viagem: v, parada: v.paradas[proximaIdx]),
        ),
        if (inicioLista < total)
          Secao(
            titulo: 'Depois',
            filhos: [
              for (var i = inicioLista; i < total; i++) _LinhaParada(viagem: v, parada: v.paradas[i], ordem: i + 1),
            ],
          ),
        Secao(
          titulo: 'Linha do tempo',
          filhos: [for (final e in v.eventos.take(6)) _LinhaEvento(evento: e)],
        ),
      ],
    );
  }
}

class _ACaminho extends StatelessWidget {
  const _ACaminho({super.key, required this.viagem, required this.parada});

  final Viagem viagem;
  final Parada parada;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final faltam = (viagem.paradas.indexOf(parada) - viagem.posicao).clamp(0.0, 99.0);
    final casa = parada.tipo == TipoParada.casa;
    final avisada = parada.alunoIds.any(store.aproximacaoAvisada.containsKey);
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconeApp(CupertinoIcons.location_fill, cor: p.azul, tamanho: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A caminho de', style: TextStyle(color: p.textoSuave, fontSize: 13)),
                    Text(parada.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(parada.subtitulo, style: TextStyle(color: p.textoSuave)),
                  ],
                ),
              ),
              Text('${(faltam * 4).ceil().clamp(1, 99)} min',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.azul)),
            ],
          ),
          if (casa) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: avisada
                  ? Row(
                      key: const ValueKey('avisada'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.checkmark_seal_fill, color: p.verde, size: 18),
                        const SizedBox(width: 6),
                        Text('Família avisada que você está chegando',
                            style: TextStyle(color: p.verde, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Botao(
                      'Avisar que estou chegando',
                      key: const ValueKey('avisar'),
                      compacto: true,
                      estilo: EstiloBotao.secundario,
                      icone: CupertinoIcons.bell_fill,
                      aoTocar: () {
                        HapticFeedback.mediumImpact();
                        store.notificarAproximacao(parada);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartaoParada extends StatelessWidget {
  const _CartaoParada({super.key, required this.viagem, required this.parada});

  final Viagem viagem;
  final Parada parada;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final ida = viagem.trajeto.sentido == Sentido.ida;
    final escola = parada.tipo == TipoParada.escola;
    final desembarque = (ida && escola) || (!ida && !escola);
    final resolvida = viagem.paradaResolvida(parada);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: p.cartao,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.amarelo, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconeApp(escola ? CupertinoIcons.book_fill : CupertinoIcons.house_fill,
                  cor: escola ? Paleta.marinhoMarca : p.laranja, tamanho: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(desembarque ? 'Desembarque' : 'Embarque',
                        style: TextStyle(color: p.textoSuave, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(escola ? parada.titulo : 'Casa de ${parada.titulo}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final id in parada.alunoIds) _Chamada(aluno: store.aluno(id), viagem: viagem, desembarque: desembarque),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: resolvida
                ? (store.seguirAutomaticamente
                    ? Row(
                        key: const ValueKey('seguindo'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(radius: 8),
                          const SizedBox(width: 10),
                          Text('Seguindo para a próxima…', style: TextStyle(color: p.textoSuave, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Botao('Próxima parada', key: const ValueKey('seguir'), icone: CupertinoIcons.arrow_right, aoTocar: store.seguir))
                : parada.alunoIds.length > 1
                    ? Botao(
                        desembarque ? 'Todos desceram' : 'Todos embarcaram',
                        key: const ValueKey('todos'),
                        estilo: EstiloBotao.secundario,
                        aoTocar: () => store.resolverParadaInteira(parada, desembarque ? SituacaoAluno.entregue : SituacaoAluno.aBordo),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Chamada extends StatelessWidget {
  const _Chamada({required this.aluno, required this.viagem, required this.desembarque});

  final Aluno aluno;
  final Viagem viagem;
  final bool desembarque;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    final s = viagem.situacoes[aluno.id]!;
    final pendente = desembarque ? s == SituacaoAluno.aBordo : s == SituacaoAluno.aguardando;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Avatar(aluno.nome, tamanho: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (aluno.cuidados.isNotEmpty)
                  Row(children: [
                    Icon(CupertinoIcons.heart_circle_fill, size: 13, color: p.vermelho),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(aluno.cuidados,
                          style: TextStyle(color: p.vermelho, fontSize: 12.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: !pendente
                ? _SeloSituacao(s, key: ValueKey(s))
                : desembarque
                    ? _Redondo(
                        key: const ValueKey('desceu'),
                        icone: CupertinoIcons.checkmark_alt,
                        cor: p.verde,
                        cheio: true,
                        aoTocar: () => store.marcar(aluno.id, SituacaoAluno.entregue),
                      )
                    : Row(
                        key: const ValueKey('botoes'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Redondo(icone: CupertinoIcons.xmark, cor: p.vermelho, aoTocar: () => store.marcar(aluno.id, SituacaoAluno.faltou)),
                          const SizedBox(width: 10),
                          _Redondo(
                            icone: CupertinoIcons.checkmark_alt,
                            cor: p.verde,
                            cheio: true,
                            aoTocar: () => store.marcar(aluno.id, SituacaoAluno.aBordo),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _Redondo extends StatelessWidget {
  const _Redondo({super.key, required this.icone, required this.cor, required this.aoTocar, this.cheio = false});

  final IconData icone;
  final Color cor;
  final VoidCallback aoTocar;
  final bool cheio;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Tocavel(
      aoTocar: () {
        HapticFeedback.mediumImpact();
        aoTocar();
      },
      haptico: false,
      escala: 0.88,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: cheio ? cor : p.suave(cor), shape: BoxShape.circle),
        child: Icon(icone, color: cheio ? Colors.white : cor, size: 22),
      ),
    );
  }
}

class _SeloSituacao extends StatelessWidget {
  const _SeloSituacao(this.s, {super.key});

  final SituacaoAluno s;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return switch (s) {
      SituacaoAluno.aBordo => Selo('A bordo', cor: p.azul, icone: CupertinoIcons.bus),
      SituacaoAluno.entregue => Selo('Entregue', cor: p.verde, icone: CupertinoIcons.checkmark_alt),
      SituacaoAluno.faltou => Selo('Não veio', cor: p.vermelho, icone: CupertinoIcons.xmark),
      SituacaoAluno.avisado => Selo('Ausente', cor: p.laranja),
      SituacaoAluno.aguardando => Selo('Aguardando', cor: p.cinza),
    };
  }
}

class _LinhaParada extends StatelessWidget {
  const _LinhaParada({required this.viagem, required this.parada, required this.ordem});

  final Viagem viagem;
  final Parada parada;
  final int ordem;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    final min = ((viagem.paradas.indexOf(parada) - viagem.posicao) * 4).ceil().clamp(1, 999);
    final escola = parada.tipo == TipoParada.escola;
    final cuidado = parada.alunoIds.any((id) => store.aluno(id).cuidados.isNotEmpty);
    return Linha(
      inicio: escola
          ? const IconeApp(CupertinoIcons.book_fill, cor: Paleta.marinhoMarca)
          : Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.preenchimento, shape: BoxShape.circle),
              child: Text('$ordem', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      titulo: parada.titulo,
      subtitulo: escola ? '${parada.alunoIds.length} alunos' : parada.subtitulo,
      fim: Row(mainAxisSize: MainAxisSize.min, children: [
        if (cuidado && !escola) ...[Icon(CupertinoIcons.heart_circle_fill, color: p.vermelho, size: 16), const SizedBox(width: 6)],
        Text('$min min', style: TextStyle(color: p.textoSuave)),
      ]),
    );
  }
}

class _LinhaEvento extends StatelessWidget {
  const _LinhaEvento({required this.evento});

  final EventoViagem evento;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final (icone, cor) = switch (evento.tipo) {
      TipoEvento.partida => (CupertinoIcons.play_fill, p.azul),
      TipoEvento.chegada => (CupertinoIcons.location_fill, p.azul),
      TipoEvento.embarque => (CupertinoIcons.arrow_right, p.verde),
      TipoEvento.desembarque => (CupertinoIcons.checkmark_alt, p.verde),
      TipoEvento.falta => (CupertinoIcons.xmark, p.vermelho),
      TipoEvento.aviso => (CupertinoIcons.bell_fill, p.laranja),
      TipoEvento.emergencia => (CupertinoIcons.exclamationmark_triangle_fill, p.vermelho),
      TipoEvento.fim => (CupertinoIcons.flag_fill, p.cinza),
    };
    return Linha(
      inicio: IconeApp(icone, cor: cor, tamanho: 26),
      titulo: evento.texto,
      fim: Text(hora(evento.quando), style: TextStyle(color: p.textoSuave, fontSize: 13)),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.viagem, required this.controle});

  final Viagem viagem;
  final ScrollController controle;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    final s = viagem.situacoes.values;
    int conta(bool Function(SituacaoAluno) f) => s.where(f).length;

    return ListView(
      controller: controle,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
      children: [
        Center(child: IconeApp(CupertinoIcons.checkmark_alt, cor: p.verde, tamanho: 64)),
        const SizedBox(height: 14),
        const Text('Viagem concluída', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
        Text(viagem.trajeto.nome, textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave)),
        Secao(
          filhos: [
            Linha(inicio: IconeApp(CupertinoIcons.person_2_fill, cor: p.verde), titulo: 'Transportados',
                fim: Text('${conta((x) => x == SituacaoAluno.entregue || x == SituacaoAluno.aBordo)}', style: const TextStyle(fontWeight: FontWeight.w700))),
            Linha(inicio: IconeApp(CupertinoIcons.xmark, cor: p.vermelho), titulo: 'Não vieram',
                fim: Text('${conta((x) => x == SituacaoAluno.faltou)}', style: const TextStyle(fontWeight: FontWeight.w700))),
            Linha(inicio: IconeApp(CupertinoIcons.calendar_badge_minus, cor: p.laranja), titulo: 'Avisaram ausência',
                fim: Text('${conta((x) => x == SituacaoAluno.avisado)}', style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 22),
        Botao('Concluir', aoTocar: () {
          Navigator.pop(context);
          store.descartarViagem();
        }),
      ],
    );
  }
}
