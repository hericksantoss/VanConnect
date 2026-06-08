import 'package:VanConnect/features/auth/screens/escolha_perfil_page.dart';
import 'package:VanConnect/features/auth/screens/home_responsavel_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/botao_principal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // A chave global (Key) serve para o Flutter gerenciar o estado e validar o formulário
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fazerLoginComGoogle() async {
    // 1. Mostra o indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Forçamos o Dart a tratar o plugin como dinâmico para ignorar travas de versão do linter
      final dynamic googleSignIn = GoogleSignIn(scopes: ['email']);
      final dynamic googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        Navigator.pop(context);
        return;
      }

      final dynamic googleAuth = await googleUser.authentication;

      // Extração segura dos tokens
      final String? accessToken = googleAuth.accessToken?.toString();
      final String? idToken = googleAuth.idToken?.toString();

      // Criando a credencial do Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // 5. Faz o login no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 6. BUSCA NO FIRESTORE: O usuário já existe?
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        Navigator.pop(context); // Fecha o loading

        if (userDoc.exists) {
          Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
          String perfil = dados['perfil'] ?? 'responsavel';

          if (perfil == 'motorista') {
            // Navigator.pushReplacementNamed(context, '/home_motorista');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeResponsavelScreen(),
              ),
            );
          }
        } else {
          // USUÁRIO NOVO: Salva os dados básicos e deixa o perfil nulo para ele escolher
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .set({
                'nome': user.displayName ?? '',
                'email': user.email ?? '',
                'fotoUrl': user.photoURL ?? '',
                'criadoEm': FieldValue.serverTimestamp(),
                'perfil': null,
              });

          // Navigator.pushReplacementNamed(context, '/escolher_perfil');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bem-vindo! Escolha seu tipo de conta para continuar.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Fecha o loading se der erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar com o Google: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fazerLogin() async {
    // Mostra a barra de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Tenta autenticar o utilizador no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text
                .trim(), // Ajusta se o teu controller tiver outro nome
            password: _passwordController.text
                .trim(), // Ajusta se o teu controller tiver outro nome
          );

      String uid = userCredential.user!.uid;

      // 2. Consulta o Firestore para descobrir quem é esta pessoa
      DocumentSnapshot docUtilizador = await FirebaseFirestore.instance
          .collection('utilizadores')
          .doc(uid)
          .get();

      // Fecha o loading
      Navigator.pop(context);

      if (docUtilizador.exists) {
        // 3. Extrai o perfil do documento
        String perfil = docUtilizador.get('perfil');

        // 4. Encaminha para o ecrã correto
        if (perfil == 'motorista') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bem-vindo, Motorista!'),
              backgroundColor: Colors.green,
            ),
          );
          // Futuramente: Navigator.pushReplacement para a Home do Motorista
        } else if (perfil == 'pai') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bem-vindo, Responsável!'),
              backgroundColor: Colors.green,
            ),
          );
          // Futuramente: Navigator.pushReplacement para a Home do Pai
        }
      } else {
        // Caso bizarro: tem login mas não tem documento na base de dados
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Perfil não encontrado na base de dados.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String mensagemErro = 'Erro ao iniciar sessão.';

      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensagemErro = 'E-mail ou palavra-passe incorretos.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      print(e);
    }
  }

  // // Dentro do seu Widget de Login, crie as funções vazias no topo do método build:

  // void _loginComEmail() {
  //   // Aqui entrará a lógica de validação dos campos de texto e Firebase Auth
  //   print("Tentando logar com e-mail...");
  // }

  // void _loginComGoogle() {
  //   // Aqui entrará o pacote google_sign_in
  //   print("Chamando o fluxo do Gmail...");
  // }

  // void _loginComFacebook() {
  //   // Aqui entrará o pacote flutter_facebook_auth
  //   print("Chamando o fluxo do Facebook...");
  // }

  // Função que executa a validação ao clicar no botão
  Future<void> _tentarEntrar() async {
    // 1. Primeiro, garantimos que o usuário preencheu os campos corretamente
    if (_formKey.currentState!.validate()) {
      // 2. Mostra a barra de carregamento para dar um feedback visual
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 3. Tenta autenticar o usuário no Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text
                  .trim(), // Verifique o nome do seu controlador
              password: _passwordController.text
                  .trim(), // Verifique o nome do seu controlador
            );

        String uid = userCredential.user!.uid;

        // 4. Vai no banco de dados (Firestore) buscar o documento desse usuário
        DocumentSnapshot docUsuario = await FirebaseFirestore.instance
            .collection('utilizadores')
            .doc(uid)
            .get();

        // 5. Fecha o aviso de carregamento
        Navigator.pop(context);

        if (docUsuario.exists) {
          // 6. Lê o campo perfil para saber para qual tela enviar o usuário
          String perfil = docUsuario.get('perfil');

          if (perfil == 'motorista') {
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeMotoristaScreen()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bem-vindo, Motorista!')),
            );
          } else if (perfil == 'pai') {
            // Navegação correta para a nova HomeResponsavelScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeResponsavelScreen(),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: Perfil não encontrado na base de dados.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Fecha o aviso de carregamento se der erro
        Navigator.pop(context);

        String mensagemErro = 'Erro ao iniciar sessão.';

        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          mensagemErro = 'E-mail ou senha incorretos.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
        );
      } catch (e) {
        Navigator.pop(context);
        print(e);
      }
    }
  }

  Future<void> _recuperarSenha() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, digite seu e-mail no campo acima primeiro.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostra um indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.setLanguageCode("pt-BR");
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      Navigator.pop(context); // Fecha o loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de redefinição enviado para $email. Verifique sua caixa de entrada e spam.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Fecha o loading
      String mensagem = 'Erro ao enviar e-mail de recuperação.';

      if (e.code == 'user-not-found') {
        mensagem = 'Este e-mail não está cadastrado no sistema.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'O formato do e-mail digitado é inválido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoBranco,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Form(
            key: _formKey, // Vincula a chave do fo rmulário aqui
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Imagem da Logo da Van (MAIOR, MAIS BAIXA E REDONDA)
                const SizedBox(
                  height: 40,
                ), // Empurra a logo mais para baixo, dando distância do topo da tela
                Center(
                  child: Container(
                    width:
                        160, // Aumentado de 120 para 160 para dar mais destaque
                    height: 160, // Aumentado de 120 para 160
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.azulPrincipal,
                        width:
                            3.5, // Borda levemente mais espessa para acompanhar o tamanho
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        80,
                      ), // Metade do novo width/height (160 / 2)
                      child: Padding(
                        padding: const EdgeInsets.all(
                          16.0,
                        ), // Mais espaço interno para a imagem ficar perfeita
                        child: Image.asset(
                          'lib/core/assets/images/logo2.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // // 2. Nome do App
                // const Text(
                //   'VANCONNECT',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 28,
                //     fontWeight: FontWeight.bold,
                //     letterSpacing: 2.0,
                //     color: AppColors.textoEscuro,
                //   ),
                // ),
                // const SizedBox(height: 8),
                const SizedBox(
                  height: 32,
                ), // Espaço entre a logo e o texto "FAÇA LOGIN PARA CONTINUAR"
                // 3. Subtítulo (PT-BR)
                const Text(
                  'FAÇA LOGIN PARA CONTINUAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 48),

                // 4. Campo de E-mail com Validação
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'E-mail',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  // Regra de validação do e-mail
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o seu e-mail';
                    }
                    // Expressão regular simples para checar se o texto tem formato de e-mail (ex@ex.com)
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Insira um formato de e-mail válido';
                    }
                    return null; // Retornar null significa que está tudo certo!
                  },
                ),
                const SizedBox(height: 16),

                // 5. Campo de Senha com Validação
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Senha',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  // Regra de validação da senha
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 6. Esqueceu a Senha (PT-BR)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _recuperarSenha,
                    child: const Text(
                      'Esqueceu sua senha?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 7. Botão de Entrar chamando a função de validação
                BotaoPrincipal(texto: 'ENTRAR', aoClicar: _tentarEntrar),
                const SizedBox(height: 48),

                // 8. Divisor "Ou entrar com"
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OU ENTRAR COM',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),

                // 9. Ícones de Login Social
                // Botão do Google ocupando a largura total (Clean e Minimalista)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _fazerLoginComGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                    ),
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                      height: 22,
                    ),
                    label: const Text(
                      'Continuar com o Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // 10. Link de Cadastro (PT-BR)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("NÃO TEM UMA CONTA?"),
                    TextButton(
                      onPressed: () {
                        // Colocamos o comando de navegação aqui dentro:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EscolhaPerfilPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'CADASTRE-SE',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
