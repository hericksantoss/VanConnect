import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

/// Conexão em 3 passos: código → "esta é a sua van?" → dados do filho.
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

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    _endereco.dispose();
    super.dispose();
  }

  void _validarCodigo() {
    final store = VanScope.read(context);
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
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _passo ? p.azul : p.preenchimento,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
            const Text('Conectar à van', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            const SizedBox(height: 6),
            Text('Digite o código que o motorista enviou.', textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave)),
            const SizedBox(height: 22),
            TextField(
              controller: _codigo,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 3),
              onSubmitted: (_) => _validarCodigo(),
              decoration: InputDecoration(hintText: 'VAN-0000', errorText: _erro),
            ),
            const SizedBox(height: 8),
            Text('Na demonstração, use ${store.codigoVan}.', textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
            const SizedBox(height: 20),
            Botao('Continuar', aoTocar: _validarCodigo),
          ],
        );
      case 1:
        final v = store.veiculo;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Esta é a sua van?', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            const SizedBox(height: 20),
            Cartao(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
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
              ]),
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
                    e.key: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(e.value, overflow: TextOverflow.ellipsis)),
                },
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Quem vai na van?', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            const SizedBox(height: 6),
            Text('Isso ajuda o motorista a montar a rota.', textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave)),
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
                      avisar(context, 'Pedido enviado! Aguarde a aprovação do motorista.', icone: CupertinoIcons.paperplane_fill, cor: p.azul);
                    }
                  : null,
            ),
          ],
        );
    }
  }
}
