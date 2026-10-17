import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/tema.dart';
import '../../componentes/mapa.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../../servicos/endereco_servico.dart';

/// Abre a tela de endereço e devolve o endereço confirmado no mapa (ou null).
Future<Endereco?> escolherEndereco(BuildContext context, {Endereco? inicial, String titulo = 'Endereço', String? ajuda}) =>
    abrir<Endereco>(context, EnderecoTela(inicial: inicial, titulo: titulo, ajuda: ajuda));

/// Passo 1: CEP (ViaCEP) + número. Passo 2: confirmar o ponto exato no mapa.
class EnderecoTela extends StatefulWidget {
  const EnderecoTela({super.key, this.inicial, this.titulo = 'Endereço', this.ajuda});

  final Endereco? inicial;
  final String titulo;
  final String? ajuda;

  @override
  State<EnderecoTela> createState() => _EnderecoTelaState();
}

class _EnderecoTelaState extends State<EnderecoTela> {
  late final _cep = TextEditingController(text: widget.inicial?.cepFormatado ?? '');
  late final _rua = TextEditingController(text: widget.inicial?.logradouro ?? '');
  late final _numero = TextEditingController(text: widget.inicial?.numero ?? '');
  late final _complemento = TextEditingController(text: widget.inicial?.complemento ?? '');
  late final _bairro = TextEditingController(text: widget.inicial?.bairro ?? '');
  late final _cidade = TextEditingController(text: widget.inicial?.cidade ?? '');
  late final _uf = TextEditingController(text: widget.inicial?.uf ?? '');

  bool _buscando = false;
  bool _cepOk = false;
  String? _erroCep;
  bool _localizando = false;

  @override
  void initState() {
    super.initState();
    _cepOk = widget.inicial != null;
  }

  @override
  void dispose() {
    for (final c in [_cep, _rua, _numero, _complemento, _bairro, _cidade, _uf]) {
      c.dispose();
    }
    super.dispose();
  }

  EnderecoServico get _servico => VanScope.read(context).enderecos;

  Future<void> _buscarCep() async {
    final digitos = EnderecoServico.soDigitos(_cep.text);
    if (digitos.length != 8) return;
    setState(() {
      _buscando = true;
      _erroCep = null;
    });
    try {
      final d = await _servico.buscarCep(digitos);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _rua.text = d.logradouro;
        _bairro.text = d.bairro;
        _cidade.text = d.cidade;
        _uf.text = d.uf;
        _cepOk = true;
      });
    } on ErroEndereco catch (e) {
      if (mounted) setState(() => _erroCep = e.mensagem);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  bool get _formularioValido =>
      _cepOk &&
      _rua.text.trim().isNotEmpty &&
      _numero.text.trim().isNotEmpty &&
      _cidade.text.trim().isNotEmpty &&
      _uf.text.trim().length == 2;

  Endereco _montar() => Endereco(
    cep: EnderecoServico.soDigitos(_cep.text),
    logradouro: _rua.text.trim(),
    numero: _numero.text.trim(),
    complemento: _complemento.text.trim(),
    bairro: _bairro.text.trim(),
    cidade: _cidade.text.trim(),
    uf: _uf.text.trim().toUpperCase(),
  );

  Future<void> _irParaMapa() async {
    final e = _montar();
    setState(() => _localizando = true);
    (double, double)? ponto;
    var aproximado = false;
    if (widget.inicial != null && widget.inicial!.temLocal && widget.inicial!.cep == e.cep && widget.inicial!.numero == e.numero) {
      ponto = (widget.inicial!.latitude!, widget.inicial!.longitude!);
    } else {
      ponto = await _servico.localizar(logradouro: e.logradouro, numero: e.numero, cidade: e.cidade, uf: e.uf, cep: e.cep);
      aproximado = ponto == null;
    }
    if (!mounted) return;
    setState(() => _localizando = false);
    final confirmado = await Navigator.of(context).push<Endereco>(
      MaterialPageRoute(
        builder: (_) => _ConfirmarNoMapa(endereco: e, ponto: ponto, aproximado: aproximado),
      ),
    );
    if (confirmado != null && mounted) Navigator.of(context).pop(confirmado);
  }

  Widget _campo(TextEditingController c, String rotulo, {TextInputType? teclado, int flex = 1, bool maiusculas = false}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: teclado,
        textCapitalization: maiusculas ? TextCapitalization.characters : TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: rotulo),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return PaginaIOS(
      titulo: widget.titulo,
      voltar: true,
      rodape: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _localizando
            ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()))
            : Botao('Localizar no mapa', icone: Icons.place_rounded, aoTocar: _formularioValido ? _irParaMapa : null),
      ),
      filhos: [
        if (widget.ajuda != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(widget.ajuda!, style: TextStyle(color: p.textoSuave, height: 1.35)),
          ),
        TextField(
          controller: _cep,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8), _MascaraCep()],
          onChanged: (v) {
            setState(() => _cepOk = false);
            if (EnderecoServico.soDigitos(v).length == 8) _buscarCep();
          },
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          decoration: InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
            errorText: _erroCep,
            prefixIcon: const Icon(Icons.local_post_office_rounded),
            suffixIcon: _buscando
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_cepOk ? Icon(Icons.check_circle_rounded, color: p.verde) : null),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
          child: Text('Digite o CEP e o resto aparece sozinho (ViaCEP).', style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _cepOk ? 1 : 0.45,
          child: IgnorePointer(
            ignoring: !_cepOk,
            child: Column(
              children: [
                Row(children: [_campo(_rua, 'Rua / Avenida', flex: 3)]),
                Row(
                  children: [
                    _campo(_numero, 'Número', teclado: TextInputType.text),
                    const SizedBox(width: 10),
                    _campo(_complemento, 'Complemento', flex: 2),
                  ],
                ),
                Row(children: [_campo(_bairro, 'Bairro')]),
                Row(children: [_campo(_cidade, 'Cidade', flex: 3), const SizedBox(width: 10), _campo(_uf, 'UF', maiusculas: true)]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

/// 00000000 → 00000-000 enquanto digita.
class _MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final d = novo.text.replaceAll(RegExp(r'\D'), '');
    final t = d.length > 5 ? '${d.substring(0, 5)}-${d.substring(5)}' : d;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Mapa com um pino fixo no centro: o motorista arrasta o mapa até a porta da casa.
class _ConfirmarNoMapa extends StatefulWidget {
  const _ConfirmarNoMapa({required this.endereco, required this.ponto, required this.aproximado});

  final Endereco endereco;
  final (double, double)? ponto;
  final bool aproximado;

  @override
  State<_ConfirmarNoMapa> createState() => _ConfirmarNoMapaState();
}

class _ConfirmarNoMapaState extends State<_ConfirmarNoMapa> {
  late LatLng _centro = widget.ponto == null ? centroArea : LatLng(widget.ponto!.$1, widget.ponto!.$2);
  bool _arrastando = false;
  TileLayer? _imagens;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    _imagens ??= criarCamadaImagens(context, p.escuro);
    final rodape = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: p.fundo,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _centro,
              initialZoom: widget.ponto == null ? 14 : 17.5,
              backgroundColor: p.mapaFundo,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onPositionChanged: (camera, gesto) {
                _centro = camera.center;
                if (gesto && !_arrastando) setState(() => _arrastando = true);
              },
              onMapEvent: (e) {
                if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd) setState(() => _arrastando = false);
              },
            ),
            children: [_imagens!],
          ),
          // Pino fixo no centro: "levanta" enquanto o mapa é arrastado.
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset: Offset(0, _arrastando ? -0.62 : -0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.azul,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                    ),
                    Container(width: 3, height: 14, color: p.azul),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: const Padding(padding: EdgeInsets.all(12), child: BotaoVoltar()),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: rodape + 12,
            child: Material(
              color: p.cartao,
              borderRadius: BorderRadius.circular(22),
              elevation: 6,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.endereco.resumo,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.texto),
                    ),
                    Text(widget.endereco.regiao, style: TextStyle(color: p.textoSuave)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          widget.aproximado ? Icons.info_outline_rounded : Icons.touch_app_rounded,
                          size: 18,
                          color: widget.aproximado ? p.laranja : p.azul,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.aproximado
                                ? 'Não achamos o número exato. Arraste o mapa até o pino ficar na porta da casa.'
                                : 'Confira: arraste o mapa se o pino não estiver na porta da casa.',
                            style: TextStyle(color: p.textoSuave, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Botao(
                      'Confirmar local',
                      icone: Icons.check_rounded,
                      aoTocar: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(widget.endereco.comLocal(_centro.latitude, _centro.longitude));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumo de um endereço já confirmado, com mapinha. Toque para alterar.
class CartaoEndereco extends StatelessWidget {
  const CartaoEndereco({super.key, required this.endereco, required this.rotulo, required this.aoTocar, this.icone = Icons.home_rounded});

  final Endereco? endereco;
  final String rotulo;
  final VoidCallback aoTocar;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final e = endereco;
    return Cartao(
      aoTocar: aoTocar,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e != null && e.temLocal)
            IgnorePointer(
              child: MapaTrajeto(
                key: ValueKey('${e.latitude},${e.longitude}'),
                pontos: const [],
                marcadores: [MarcadorMapa(deLatLng(e.latitude!, e.longitude!), TipoMarcador.destaque)],
                altura: 110,
                raio: 18,
                margem: const EdgeInsets.all(60),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconeApp(e == null ? Icons.add_location_alt_rounded : icone, cor: p.azul),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rotulo, style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
                      Text(
                        e == null ? 'Informar pelo CEP' : e.resumo,
                        style: TextStyle(fontWeight: FontWeight.w600, color: e == null ? p.azul : p.texto),
                      ),
                      if (e != null) Text(e.regiao, style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.cinza),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
