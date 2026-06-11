import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/botao_principal.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  
  User? _usuarioAtual;
  bool _estaCarregando = true;
  bool _estaSalvando = false;
  String _emailUsuario = '';
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // Coleta as informações do usuário atual (Auth + Firestore)
  Future<void> _carregarDadosUsuario() async {
    try {
      _usuarioAtual = FirebaseAuth.instance.currentUser;

      if (_usuarioAtual != null) {
        // Tenta buscar na coleção 'usuarios' ou 'utilizadores' (ajuste conforme o seu padrão do banco)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios') 
            .doc(_usuarioAtual!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
          _nomeController.text = dados['nome'] ?? '';
          _emailUsuario = dados['email'] ?? _usuarioAtual!.email ?? '';
          _fotoUrl = dados['fotoUrl'] ?? '';
        } else {
          // Fallback se o documento no Firestore ainda não existir por algum motivo
          _nomeController.text = _usuarioAtual!.displayName ?? '';
          _emailUsuario = _usuarioAtual!.email ?? '';
          _fotoUrl = _usuarioAtual!.photoURL ?? '';
        }
      }
    } catch (e) {
      print("Erro ao carregar dados do perfil: $e");
    } finally {
      setState(() {
        _estaCarregando = false;
      });
    }
  }

  // Atualiza apenas o nome do usuário no Firestore
  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaSalvando = true;
    });

    try {
      if (_usuarioAtual != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_usuarioAtual!.uid)
            .update({
          'nome': _nomeController.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar alterações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _estaSalvando = false;
      });
    }
  }

  // Fluxo completo de Log-out (Sair da conta limpando os tokens do Google)
  Future<void> _executarLogoutSeguro() async {
  // 1. Mostra o loading de fechamento de sessão
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 2. Limpa o cache do Google Sign In se ele estiver ativo
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }

    // 3. Desloga do Firebase Auth
    // O StreamBuilder na main.dart vai capturar isso e já vai mandar a raiz para a LoginScreen()
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    
    // 4. Fecha o showDialog de loading com segurança antes de resetar a pilha
    Navigator.of(context, rootNavigator: true).pop();

    // 5. Destrói toda a árvore de telas antigas da Home e garante o Login limpo
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Fecha o loading em caso de falha
    print("Erro ao deslogar: $e");
  }
}

  // Reutiliza o estilo de input que padronizamos na tela de login
  InputDecoration _buildInputStyle({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      prefixIcon: Icon(icon, color: AppColors.azulPrincipal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.azulPrincipal, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCarregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.fundoBranco,
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: AppColors.fundoBranco,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Avatar do usuário (Foto do Google ou ícone padrão)
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.azulPrincipal, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: _fotoUrl.isNotEmpty ? NetworkImage(_fotoUrl) : null,
                            child: _fotoUrl.isEmpty
                                ? const Icon(Icons.person, size: 60, color: AppColors.azulPrincipal)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Campo de Nome (Editável)
                  const Text(
                    'NOME COMPLETO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textoSuave, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nomeController,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: _buildInputStyle(hint: 'Seu nome', icon: Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome não pode ficar vazio';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Campo de E-mail (Apenas leitura/Read-only por segurança)
                  const Text(
                    'E-MAIL DE CADASTRO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textoSuave, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _emailUsuario,
                    enabled: false, // Desabilita a edição do e-mail
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    decoration: _buildInputStyle(hint: 'E-mail', icon: Icons.mail_outline).copyWith(
                      fillColor: Colors.grey.shade50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Botão de Salvar Alterações (Reutiliza o seu widget padrão)
                  _estaSalvando
                      ? const Center(child: CircularProgressIndicator())
                      : BotaoPrincipal(
                          texto: 'SALVAR ALTERAÇÕES',
                          aoClicar: _salvarAlteracoes,
                        ),
                  
                  const SizedBox(height: 20),

                  // Botão de Log-out (Sair da Conta)
                  OutlinedButton.icon(
                    onPressed: _executarLogoutSeguro,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    label: const Text(
                      'SAIR DA CONTA',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}