import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../app/validacoes.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import '../../servicos/autenticacao_servico.dart';
import 'cadastro_motorista.dart';
import 'codigo_van.dart';

/// Criar conta / entrar: Google, Facebook ou e-mail.
/// Motorista segue para o cadastro (dados + van); responsável, para o código da van.
class EntrarContaTela extends StatefulWidget {
  const EntrarContaTela({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<EntrarContaTela> createState() => _EntrarContaTelaState();
}

class _EntrarContaTelaState extends State<EntrarContaTela> {
  ProvedorLogin? _carregando;

  bool get _motorista => widget.perfil == Perfil.motorista;

  Future<void> _entrar(ProvedorLogin provedor) async {
    final store = VanScope.read(context);
    final dados = await abrirFolha<(String, String)>(context, _FolhaConta(provedor: provedor, demonstracao: store.auth.demonstracao));
    if (dados == null || !mounted) return;

    setState(() => _carregando = provedor);
    final conta = await store.auth.entrar(provedor, nome: dados.$1, email: dados.$2);
    if (!mounted) return;
    setState(() => _carregando = null);

    final nav = Navigator.of(context);
    if (_motorista) {
      if (store.motoristaCadastrado(conta)) {
        nav.popUntil((r) => r.isFirst);
        store.entrarMotorista(conta);
      } else {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => CadastroMotoristaTela(conta: conta)));
      }
      return;
    }
    store.comecarSessaoResponsavel(conta);
    if (store.filhosDoResponsavel.isNotEmpty || store.solicitacoesDoResponsavel.isNotEmpty) {
      // Conta que já tem filho liberado (ou pedido em andamento) entra direto.
      nav.popUntil((r) => r.isFirst);
      store.escolherPerfil(Perfil.responsavel);
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const CodigoVanTela()));
    }
  }

  void _demonstracao() {
    final store = VanScope.read(context);
    Navigator.of(context).popUntil((r) => r.isFirst);
    _motorista ? store.entrarDemonstracaoMotorista() : store.entrarDemonstracaoResponsavel();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;

    return PaginaIOS(
      titulo: _motorista ? 'Conta de motorista' : 'Conta da família',
      voltar: true,
      filhos: [
        Text(
          _motorista ? 'Entre para cadastrar seus dados e a sua van.' : 'Entre e depois digite o código da van que o motorista enviou.',
          style: TextStyle(fontSize: 16, color: p.textoSuave, height: 1.35),
        ),
        const SizedBox(height: 22),
        _PassoAPasso(
          passos: _motorista
              ? const ['Criar a conta', 'Seus dados (CPF, RG, CNH)', 'Dados da van (placa e lugares)']
              : const ['Criar a conta', 'Código da van', 'Acompanhar o seu filho'],
        ),
        const SizedBox(height: 24),
        _BotaoProvedor(
          provedor: ProvedorLogin.google,
          carregando: _carregando == ProvedorLogin.google,
          aoTocar: _carregando == null ? () => _entrar(ProvedorLogin.google) : null,
        ),
        const SizedBox(height: 10),
        _BotaoProvedor(
          provedor: ProvedorLogin.facebook,
          carregando: _carregando == ProvedorLogin.facebook,
          aoTocar: _carregando == null ? () => _entrar(ProvedorLogin.facebook) : null,
        ),
        const SizedBox(height: 10),
        _BotaoProvedor(
          provedor: ProvedorLogin.email,
          carregando: _carregando == ProvedorLogin.email,
          aoTocar: _carregando == null ? () => _entrar(ProvedorLogin.email) : null,
        ),
        const SizedBox(height: 16),
        Text(
          'Ao continuar, você concorda com os Termos de Uso e a Política de Privacidade.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textoSuave, fontSize: 12.5),
        ),
        if (store.auth.demonstracao) ...[
          const SizedBox(height: 22),
          Cartao(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.info_circle_fill, color: p.azul, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Protótipo: o Google e o Facebook ainda são simulados (você digita nome e e-mail). '
                    'Para ligar o login de verdade, configure o Firebase — o passo a passo está no README.',
                    style: TextStyle(color: p.textoSuave, fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: _carregando == null ? _demonstracao : null,
            child: Text(_motorista ? 'Só quero ver a demonstração do motorista' : 'Só quero ver a demonstração da família'),
          ),
        ),
      ],
    );
  }
}

class _PassoAPasso extends StatelessWidget {
  const _PassoAPasso({required this.passos});

  final List<String> passos;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Row(
      children: [
        for (var i = 0; i < passos.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(color: i == 0 ? p.azul : p.preenchimento, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${i + 1}',
                  style: TextStyle(color: i == 0 ? p.azul : p.textoSuave, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(passos[i], style: TextStyle(color: p.textoSuave, fontSize: 12.5, height: 1.25)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BotaoProvedor extends StatelessWidget {
  const _BotaoProvedor({required this.provedor, required this.carregando, this.aoTocar});

  final ProvedorLogin provedor;
  final bool carregando;
  final VoidCallback? aoTocar;

  static const _azulFacebook = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final (fundo, texto, borda) = switch (provedor) {
      ProvedorLogin.google => (p.escuro ? p.cartao : Colors.white, p.texto, p.separador),
      ProvedorLogin.facebook => (_azulFacebook, Colors.white, _azulFacebook),
      _ => (p.preenchimento, p.texto, p.preenchimento),
    };
    final marca = switch (provedor) {
      ProvedorLogin.google => const _LetraGoogle(),
      ProvedorLogin.facebook => const Text(
        'f',
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1),
      ),
      _ => Icon(CupertinoIcons.mail_solid, color: p.azul, size: 22),
    };

    return Tocavel(
      aoTocar: aoTocar,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: aoTocar == null && !carregando ? 0.5 : 1,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borda),
          ),
          child: Row(
            children: [
              SizedBox(width: 26, child: Center(child: marca)),
              Expanded(
                child: Text(
                  'Continuar com ${provedor.rotulo}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: texto, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              SizedBox(
                width: 26,
                child: carregando ? CircularProgressIndicator.adaptive(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(texto)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "G" com as quatro cores, sem depender de imagem.
class _LetraGoogle extends StatelessWidget {
  const _LetraGoogle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const SweepGradient(
        colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)],
        stops: [0.0, 0.3, 0.55, 0.8, 1.0],
        startAngle: 3.6,
        endAngle: 10.0,
        tileMode: TileMode.repeated,
      ).createShader(r),
      child: const Text(
        'G',
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1),
      ),
    );
  }
}

/// No protótipo, a "janela do Google/Facebook" é esta folha: nome e e-mail.
class _FolhaConta extends StatefulWidget {
  const _FolhaConta({required this.provedor, required this.demonstracao});

  final ProvedorLogin provedor;
  final bool demonstracao;

  @override
  State<_FolhaConta> createState() => _FolhaContaState();
}

class _FolhaContaState extends State<_FolhaConta> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _tentou = false;

  bool get _porEmail => widget.provedor == ProvedorLogin.email;

  String? get _erroNome => _nome.text.trim().split(RegExp(r'\s+')).length < 2 ? 'Escreva nome e sobrenome' : null;
  String? get _erroEmail => emailValido(_email.text) ? null : 'E-mail inválido';
  String? get _erroSenha => !_porEmail || _senha.text.length >= 6 ? null : 'Use pelo menos 6 caracteres';

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _continuar() {
    setState(() => _tentou = true);
    if (_erroNome != null || _erroEmail != null || _erroSenha != null) return;
    Navigator.pop(context, (_nome.text.trim(), _email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Formulario(
      titulo: _porEmail ? 'Entrar com e-mail' : 'Entrar com ${widget.provedor.rotulo}',
      rotuloSalvar: 'Continuar',
      aoSalvar: _continuar,
      campos: [
        if (widget.demonstracao && !_porEmail)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No app publicado, aqui abre a janela do ${widget.provedor.rotulo}. No protótipo, informe nome e e-mail.',
              style: TextStyle(color: p.textoSuave, height: 1.35),
            ),
          ),
        CampoTexto(
          controle: _nome,
          rotulo: 'Nome completo',
          icone: CupertinoIcons.person_fill,
          nomes: true,
          erro: _tentou ? _erroNome : null,
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _email,
          rotulo: 'E-mail',
          icone: CupertinoIcons.mail_solid,
          teclado: TextInputType.emailAddress,
          erro: _tentou ? _erroEmail : null,
          aoMudar: () => setState(() {}),
        ),
        if (_porEmail)
          CampoTexto(
            controle: _senha,
            rotulo: 'Senha',
            icone: CupertinoIcons.lock_fill,
            oculto: true,
            erro: _tentou ? _erroSenha : null,
            aoMudar: () => setState(() {}),
          ),
      ],
    );
  }
}
