import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import '../../servicos/localizacao_servico.dart';

/// Garante GPS ligado e com permissão antes de iniciar a viagem.
/// Retorna true só quando a localização está pronta; enquanto não estiver,
/// a viagem fica indisponível.
Future<bool> garantirLocalizacao(BuildContext context) async {
  final servico = VanScope.read(context).localizacao;
  final agora = await servico.verificar(pedirPermissao: true);
  if (agora == SituacaoGps.pronto) return true;
  if (!context.mounted) return false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _FolhaLocalizacao(servico: servico, inicial: agora),
  );
  return ok ?? false;
}

class _FolhaLocalizacao extends StatefulWidget {
  const _FolhaLocalizacao({required this.servico, required this.inicial});

  final LocalizacaoServico servico;
  final SituacaoGps inicial;

  @override
  State<_FolhaLocalizacao> createState() => _FolhaLocalizacaoState();
}

class _FolhaLocalizacaoState extends State<_FolhaLocalizacao> with WidgetsBindingObserver {
  late SituacaoGps _situacao = widget.inicial;
  Timer? _conferir;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Confere sozinho a cada 2 s: quando o motorista ligar, a folha fecha e a viagem segue.
    _conferir = Timer.periodic(const Duration(seconds: 2), (_) => _verificar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conferir?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verificar();
  }

  Future<void> _verificar({bool pedir = false}) async {
    final s = await widget.servico.verificar(pedirPermissao: pedir);
    if (!mounted) return;
    if (s == SituacaoGps.pronto) {
      _conferir?.cancel();
      Navigator.pop(context, true);
      return;
    }
    setState(() => _situacao = s);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final (titulo, texto, botao) = switch (_situacao) {
      SituacaoGps.desligado => (
        'Ligue a localização',
        'As famílias acompanham a van em tempo real pela sua localização. Com o GPS desligado, a viagem não pode começar.',
        'Ligar localização',
      ),
      SituacaoGps.semPermissao => (
        'Permita a localização',
        'O Van Connect precisa da sua localização durante a viagem para mostrar a van no mapa das famílias.',
        'Permitir',
      ),
      _ => (
        'Localização bloqueada',
        'A permissão de localização foi negada. Abra os ajustes do app e permita a localização para iniciar viagens.',
        'Abrir ajustes do app',
      ),
    };

    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: p.suave(p.vermelho), shape: BoxShape.circle),
                child: Icon(Icons.location_off_rounded, color: p.vermelho, size: 38),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.texto),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textoSuave, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Conferindo automaticamente…', style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: 20),
            Botao(
              botao,
              icone: Icons.my_location_rounded,
              aoTocar: () async {
                switch (_situacao) {
                  case SituacaoGps.desligado:
                    await widget.servico.abrirAjustesLocalizacao();
                  case SituacaoGps.semPermissao:
                    await _verificar(pedir: true);
                  case _:
                    await widget.servico.abrirAjustesDoApp();
                }
              },
            ),
            const SizedBox(height: 10),
            Botao('Agora não', estilo: EstiloBotao.secundario, aoTocar: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}
