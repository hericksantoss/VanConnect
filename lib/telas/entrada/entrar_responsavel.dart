import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

/// Entrada do responsável: o código do convite é o próprio login (sem senha).
class EntrarResponsavelTela extends StatefulWidget {
  const EntrarResponsavelTela({super.key});

  @override
  State<EntrarResponsavelTela> createState() => _EntrarResponsavelTelaState();
}

class _EntrarResponsavelTelaState extends State<EntrarResponsavelTela> {
  final _codigo = TextEditingController();
  String? _erro;
  Convite? _convite;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _validar() {
    final store = VanScope.read(context);
    if (VanStore.pareceCodigoGeral(_codigo.text)) {
      HapticFeedback.heavyImpact();
      setState(() => _erro = 'Esse é o código geral da van. Para entrar, peça ao motorista o convite da sua família.');
      return;
    }
    final c = store.buscarConvite(_codigo.text);
    HapticFeedback.mediumImpact();
    setState(() {
      _convite = c;
      _erro = c == null ? 'Convite não encontrado, já usado ou vencido. Peça um novo ao motorista.' : null;
    });
  }

  void _entrar() {
    final store = VanScope.read(context);
    final c = _convite!;
    // Volta para a raiz antes: a troca de perfil desenha a tela do responsável lá.
    Navigator.of(context).popUntil((r) => r.isFirst);
    store.entrarComConvite(c);
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final c = _convite;

    return PaginaIOS(
      titulo: 'Entrar',
      voltar: true,
      filhos: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 320), child: c == null ? _formulario(store, p) : _confirmacao(store, p, c)),
      ],
    );
  }

  Widget _formulario(VanStore store, Paleta p) {
    final demo = store.convites.where((x) => x.valido(DateTime.now())).lastOrNull;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(child: IconeApp(CupertinoIcons.paperplane_fill, cor: p.azul, tamanho: 64)),
        const SizedBox(height: 16),
        const Text(
          'Use o convite do motorista',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
        const SizedBox(height: 6),
        Text(
          'Toque no link que chegou pelo WhatsApp ou digite o código. Não precisa criar senha.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textoSuave, height: 1.35),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _codigo,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 3),
          onSubmitted: (_) => _validar(),
          onChanged: (_) {
            if (_erro != null) setState(() => _erro = null);
          },
          decoration: InputDecoration(hintText: 'K7P-2QX', errorText: _erro, errorMaxLines: 3),
        ),
        const SizedBox(height: 16),
        Botao('Continuar', aoTocar: _validar),
        const SizedBox(height: 28),
        Secao(
          titulo: 'Demonstração',
          rodape: demo == null
              ? 'Para testar o convite: entre como motorista, abra um aluno e toque em Convidar.'
              : 'Convite gerado nesta sessão: ${demo.codigoFormatado}.',
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.person_2_fill, cor: p.azul),
              titulo: 'Ver demonstração',
              subtitulo: 'Entrar como Mariana, mãe do Lucas e da Helena',
              aoTocar: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                store.entrarDemonstracaoResponsavel();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _confirmacao(VanStore store, Paleta p, Convite c) {
    final alunos = c.alunoIds.map(store.aluno).toList();
    return Column(
      key: ValueKey(c.codigo),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(child: Avatar(store.nomeMotorista, tamanho: 72)),
        const SizedBox(height: 12),
        Text(
          '${primeiroNome(store.nomeMotorista)} convidou ${primeiroNome(c.nomeConvidado ?? c.responsavel.nome)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
        Text(
          '${store.veiculo.modelo} · placa ${store.veiculo.placa}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textoSuave),
        ),
        const SizedBox(height: 10),
        Center(
          child: Selo(
            c.escopo.rotulo,
            cor: c.escopo == Escopo.completo ? p.azul : p.cinza,
            icone: c.escopo == Escopo.completo ? CupertinoIcons.hand_raised_fill : CupertinoIcons.eye_fill,
          ),
        ),
        Secao(
          titulo: 'Para acompanhar',
          rodape: c.escopo.descricao,
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
        Botao('Entrar', icone: CupertinoIcons.checkmark_alt, aoTocar: _entrar),
        CupertinoButton(onPressed: () => setState(() => _convite = null), child: const Text('Não reconheço este convite')),
      ],
    );
  }
}
