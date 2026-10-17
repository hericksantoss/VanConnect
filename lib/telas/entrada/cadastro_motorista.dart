import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../app/validacoes.dart';
import '../../componentes/mascaras.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import '../../servicos/autenticacao_servico.dart';

/// Cadastro do motorista em dois passos: dados pessoais e a van.
/// Sem [conta], abre só os dados pessoais para edição ("Meus dados").
class CadastroMotoristaTela extends StatefulWidget {
  const CadastroMotoristaTela({super.key, this.conta});

  final ContaUsuario? conta;

  @override
  State<CadastroMotoristaTela> createState() => _CadastroMotoristaTelaState();
}

class _CadastroMotoristaTelaState extends State<CadastroMotoristaTela> {
  int _passo = 0;
  bool _tentou = false;

  late final VanStore _store = VanScope.read(context);
  bool get _edicao => widget.conta == null;

  late final _nome = TextEditingController(text: _edicao ? _store.nomeMotorista : widget.conta!.nome);
  late final _cpf = TextEditingController(text: _edicao ? formatarCpf(_store.cpfMotorista) : '');
  late final _rg = TextEditingController(text: _edicao ? _store.rgMotorista : '');
  late final _cnh = TextEditingController(text: _edicao ? _store.cnhMotorista : '');
  late final _telefone = TextEditingController(text: _edicao ? _store.telefoneMotorista : '');

  final _apelido = TextEditingController(text: 'Van principal');
  final _modelo = TextEditingController();
  final _placa = TextEditingController();
  int _lugares = 15;

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _rg, _cnh, _telefone, _apelido, _modelo, _placa]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _erroNome => _nome.text.trim().split(RegExp(r'\s+')).length < 2 ? 'Escreva nome e sobrenome' : null;
  String? get _erroCpf => cpfValido(_cpf.text) ? null : 'CPF inválido — confira os números';
  String? get _erroRg => soNumeros(_rg.text).length < 5 ? 'Informe o RG' : null;
  String? get _erroCnh => _cnh.text.trim().isEmpty || soNumeros(_cnh.text).length == 11 ? null : 'A CNH tem 11 números';
  String? get _erroTelefone => telefoneValido(_telefone.text) ? null : 'Informe o WhatsApp com DDD';
  String? get _erroModelo => _modelo.text.trim().length < 3 ? 'Informe o modelo (ex.: Sprinter 2020)' : null;
  String? get _erroPlaca => placaValida(_placa.text) ? null : 'Placa inválida (ABC-1234 ou ABC1D23)';

  bool get _dadosOk => [_erroNome, _erroCpf, _erroRg, _erroCnh, _erroTelefone].every((e) => e == null);
  bool get _vanOk => _erroModelo == null && _erroPlaca == null && _apelido.text.trim().isNotEmpty;

  void _avancar() {
    setState(() => _tentou = true);
    if (!_dadosOk) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_edicao) {
      _store.atualizarDadosMotorista(
        nome: _nome.text.trim(),
        cpf: soNumeros(_cpf.text),
        rg: _rg.text.trim(),
        cnh: soNumeros(_cnh.text),
        telefone: _telefone.text.trim(),
      );
      Navigator.pop(context);
      avisar(context, 'Dados atualizados');
      return;
    }
    setState(() {
      _passo = 1;
      _tentou = false;
    });
  }

  void _concluir() {
    setState(() => _tentou = true);
    if (!_vanOk) {
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    _store.concluirCadastroMotorista(
      conta: widget.conta!,
      nome: _nome.text.trim(),
      cpf: soNumeros(_cpf.text),
      rg: _rg.text.trim(),
      cnh: soNumeros(_cnh.text),
      telefone: _telefone.text.trim(),
      apelidoVan: _apelido.text.trim(),
      modeloVan: _modelo.text.trim(),
      placa: formatarPlaca(_placa.text),
      lugares: _lugares,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return PopScope(
      // No passo da van, "voltar" volta para os dados pessoais.
      canPop: _passo == 0,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) setState(() => _passo = 0);
      },
      child: PaginaIOS(
        titulo: _edicao ? 'Meus dados' : (_passo == 0 ? 'Seus dados' : 'Sua van'),
        voltar: true,
        filhos: [
          if (!_edicao) ...[
            Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: i <= _passo ? p.azul : p.preenchimento, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _passo == 0
                  ? 'Olá, ${primeiroNome(widget.conta!.nome)}! Conta ${widget.conta!.provedor.rotulo} criada (${widget.conta!.email}). Agora seus dados de motorista.'
                  : 'Por último, a van que você usa. Depois dá para cadastrar uma reserva em Gestão › Vans.',
              style: TextStyle(color: p.textoSuave, height: 1.35),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_passo), child: _passo == 0 ? _dados(p) : _van(p)),
          ),
        ],
      ),
    );
  }

  Widget _dados(Paleta p) {
    String? erro(String? e) => _tentou ? e : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(
          controle: _nome,
          rotulo: 'Nome completo',
          icone: CupertinoIcons.person_fill,
          nomes: true,
          erro: erro(_erroNome),
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _cpf,
          rotulo: 'CPF',
          icone: CupertinoIcons.doc_text_fill,
          teclado: TextInputType.number,
          formatadores: [Mascara.cpf],
          erro: erro(_erroCpf),
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _rg,
          rotulo: 'RG',
          icone: CupertinoIcons.creditcard_fill,
          maiusculas: true,
          erro: erro(_erroRg),
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _cnh,
          rotulo: 'CNH (opcional)',
          icone: CupertinoIcons.car_detailed,
          teclado: TextInputType.number,
          formatadores: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          erro: erro(_erroCnh),
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _telefone,
          rotulo: 'WhatsApp',
          icone: CupertinoIcons.phone_fill,
          teclado: TextInputType.phone,
          formatadores: [Mascara.telefone],
          erro: erro(_erroTelefone),
          aoMudar: () => setState(() {}),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.lock_fill, size: 15, color: p.textoSuave),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'CPF, RG e CNH ficam só no seu cadastro. As famílias veem apenas seu nome, a van e a placa.',
                style: TextStyle(color: p.textoSuave, fontSize: 12.5, height: 1.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Botao(_edicao ? 'Salvar' : 'Continuar', icone: _edicao ? Icons.check_rounded : CupertinoIcons.arrow_right, aoTocar: _avancar),
      ],
    );
  }

  Widget _van(Paleta p) {
    String? erro(String? e) => _tentou ? e : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(controle: _apelido, rotulo: 'Apelido (ex.: Van azul)', icone: CupertinoIcons.tag_fill, aoMudar: () => setState(() {})),
        CampoTexto(
          controle: _modelo,
          rotulo: 'Modelo e ano (ex.: Sprinter 2020)',
          icone: CupertinoIcons.car_fill,
          erro: erro(_erroModelo),
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _placa,
          rotulo: 'Placa',
          icone: CupertinoIcons.textformat_abc,
          maiusculas: true,
          formatadores: [MascaraPlaca()],
          erro: erro(_erroPlaca),
          aoMudar: () => setState(() {}),
        ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.person_3_fill, cor: p.azul),
              titulo: 'Lugares',
              subtitulo: 'Sem contar o motorista',
              fim: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _lugares > 4 ? () => setState(() => _lugares--) : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: p.azul,
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$_lugares',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: _lugares < 30 ? () => setState(() => _lugares++) : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: p.azul,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'A van fica ligada só à sua conta: nenhum outro motorista consegue usá-la.',
          style: TextStyle(color: p.textoSuave, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 20),
        Botao('Concluir cadastro', icone: Icons.check_rounded, aoTocar: _concluir),
      ],
    );
  }
}
