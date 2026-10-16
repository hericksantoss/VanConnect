import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

/// Conexão com a van. O mesmo campo aceita dois tipos de código:
/// - Convite da família (ex.: K7P-2QX): já traz filho e rota → só aceitar.
/// - Código geral do motorista (VAN-…): código → "esta é a sua van?" → dados do filho → aprovação.
class ConectarVan extends StatefulWidget {
  const ConectarVan({super.key});

  @override
  State<ConectarVan> createState() => _ConectarVanState();
}

class _ConectarVanState extends State<ConectarVan> {
  int _passo = 0;
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _endereco = TextEditingController(text: 'Rua Aurora, 45');
  String _escolaId = 'e1';
  Turno _turno = Turno.manha;
  String? _erro;
  Convite? _convite;

  /// Passo 3 = tela do convite.
  static const _passoConvite = 3;

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    _endereco.dispose();
    super.dispose();
  }

  void _validarCodigo() {
    final store = VanScope.read(context);
    if (!VanStore.pareceCodigoGeral(_codigo.text)) {
      final convite = store.buscarConvite(_codigo.text);
      if (convite != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _erro = null;
          _convite = convite;
          _passo = _passoConvite;
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _erro = 'Convite não encontrado, já usado ou vencido. Peça um novo ao motorista.');
      }
      return;
    }
    if (store.codigoValido(_codigo.text)) {
      HapticFeedback.mediumImpact();
      setState(() {
        _erro = null;
        _passo = 1;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _erro = 'Código não encontrado. Confira com o motorista.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_passo != _passoConvite)
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
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
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_passo), child: _conteudo(context, p)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context, Paleta p) {
    final store = VanScope.of(context);
    switch (_passo) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: IconeApp(CupertinoIcons.qrcode, cor: p.azul, tamanho: 64)),
            const SizedBox(height: 16),
            const Text(
              'Conectar à van',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'Digite o código do convite que o motorista enviou pelo WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textoSuave),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _codigo,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 3),
              onSubmitted: (_) => _validarCodigo(),
              onChanged: (_) {
                if (_erro != null) setState(() => _erro = null);
              },
              decoration: InputDecoration(hintText: 'K7P-2QX', errorText: _erro, errorMaxLines: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Recebeu só o código geral da van (VAN-…)? Ele também funciona, mas o motorista precisa aprovar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textoSuave, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Text(
              store.convites.any((c) => c.valido(DateTime.now()))
                  ? 'Demonstração: convite ${store.convites.lastWhere((c) => c.valido(DateTime.now())).codigoFormatado} ou ${store.codigoVan}.'
                  : 'Demonstração: gere um convite em Motorista › Gestão › Alunos › Convidar, ou use ${store.codigoVan}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.azul, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            Botao('Continuar', aoTocar: _validarCodigo),
          ],
        );
      case _passoConvite:
        return _TelaConvite(convite: _convite!, aoVoltar: () => setState(() => _passo = 0));
      case 1:
        final v = store.veiculo;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta é a sua van?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
            ),
            const SizedBox(height: 20),
            Cartao(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Avatar(store.nomeMotorista, tamanho: 72),
                  const SizedBox(height: 10),
                  Text(store.nomeMotorista, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(v.modelo, style: TextStyle(color: p.textoSuave)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.texto, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(v.placa, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Botao('Sim, é esta', aoTocar: () => setState(() => _passo = 2)),
            const SizedBox(height: 8),
            CupertinoButton(onPressed: () => setState(() => _passo = 0), child: const Text('Não é esta')),
          ],
        );
      default:
        final valido = _nome.text.trim().isNotEmpty && _endereco.text.trim().isNotEmpty;
        Widget segmento<T extends Object>(T valor, Map<T, String> opcoes, ValueChanged<T> aoMudar) => SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<T>(
            groupValue: valor,
            backgroundColor: p.preenchimento,
            thumbColor: p.escuro ? p.elevado : Colors.white,
            onValueChanged: (x) => setState(() => aoMudar(x ?? valor)),
            children: {
              for (final e in opcoes.entries)
                e.key: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
            },
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quem vai na van?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'Isso ajuda o motorista a montar a rota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textoSuave),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Nome da criança', prefixIcon: Icon(CupertinoIcons.person_fill, size: 20)),
            ),
            const SizedBox(height: 10),
            segmento<String>(_escolaId, {for (final e in store.escolas) e.id: e.nome}, (x) => _escolaId = x),
            const SizedBox(height: 10),
            segmento<Turno>(_turno, const {Turno.manha: 'Manhã', Turno.tarde: 'Tarde'}, (x) => _turno = x),
            const SizedBox(height: 10),
            TextField(
              controller: _endereco,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Endereço de embarque', prefixIcon: Icon(CupertinoIcons.house_fill, size: 20)),
            ),
            const SizedBox(height: 20),
            Botao(
              'Enviar pedido',
              icone: CupertinoIcons.paperplane_fill,
              aoTocar: valido
                  ? () {
                      store.solicitarVinculo(
                        nomeAluno: _nome.text.trim(),
                        escolaId: _escolaId,
                        turno: _turno,
                        endereco: _endereco.text.trim(),
                      );
                      Navigator.pop(context);
                      avisar(
                        context,
                        'Pedido enviado! Aguarde a aprovação do motorista.',
                        icone: CupertinoIcons.paperplane_fill,
                        cor: p.azul,
                      );
                    }
                  : null,
            ),
          ],
        );
    }
  }
}

/// O que a família vê ao abrir o convite: tudo pronto, só aceitar.
class _TelaConvite extends StatelessWidget {
  const _TelaConvite({required this.convite, required this.aoVoltar});

  final Convite convite;
  final VoidCallback aoVoltar;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final alunos = convite.alunoIds.map(store.aluno).toList();
    final v = store.veiculo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Avatar(store.nomeMotorista, tamanho: 72)),
        const SizedBox(height: 12),
        Text(
          '${primeiroNome(store.nomeMotorista)} convidou você',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
        Text(
          '${v.modelo} · placa ${v.placa}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textoSuave),
        ),
        Secao(
          titulo: alunos.length == 1 ? 'Para acompanhar' : 'Para acompanhar (${alunos.length})',
          filhos: [
            for (final a in alunos)
              Linha(
                inicio: Avatar(a.nome, tamanho: 38),
                titulo: a.nome,
                subtitulo:
                    '${store.escola(a.escolaId).nome}\n'
                    '${store.trajetosOrdenados.where((t) => t.alunoIds.contains(a.id)).map((t) => '${t.sentido.rotulo} ${horario(t.saida)}').join(' · ')}',
              ),
          ],
        ),
        const SizedBox(height: 20),
        Botao(
          'Aceitar convite',
          icone: CupertinoIcons.checkmark_alt,
          aoTocar: () {
            HapticFeedback.mediumImpact();
            final filhos = store.aceitarConvite(convite);
            Navigator.pop(context);
            avisar(
              context,
              'Pronto! ${filhos.map((a) => a.primeiro).join(' e ')} já aparece${filhos.length > 1 ? 'm' : ''} no seu mapa.',
              icone: CupertinoIcons.checkmark_seal_fill,
            );
          },
        ),
        const SizedBox(height: 4),
        CupertinoButton(onPressed: aoVoltar, child: const Text('Não reconheço este convite')),
      ],
    );
  }
}
