import 'package:VanConnect/features/auth/screens/escolha_perfil_page.dart';
import 'package:VanConnect/features/auth/screens/home_motorista_screen.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dynamic googleSignIn = GoogleSignIn(scopes: ['email']);
      final dynamic googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Garante o fechamento usando o rootNavigator se o usuário cancelar a gaveta do Google
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      final dynamic googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken?.toString();
      final String? idToken = googleAuth.idToken?.toString();

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (!mounted) return;
        
        // FECHAMENTO SEGURO: Mata o diálogo roxo antes que a árvore mude de tela
        Navigator.of(context, rootNavigator: true).pop(); 

        if (userDoc.exists) {
          Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
          String? perfil = dados['perfil'];

          if (perfil == null || perfil.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EscolhaPerfilPage(
                  uid: user.uid,
                  email: user.email ?? '',
                  nomeInicial: user.displayName ?? '',
                  fotoUrl: user.photoURL ?? '',
                ),
              ),
            );
          } else if (perfil == 'motorista') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeMotoristaScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeResponsavelScreen(),
              ),
            );
          }
        } else {
          // SE NÃO EXISTE DOCUMENTO: É Usuário Novo (Persistência Tardia)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EscolhaPerfilPage(
                uid: user.uid,
                email: user.email ?? '',
                nomeInicial: user.displayName ?? '',
                fotoUrl: user.photoURL ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Fecha o loading em caso de erro de rede
      
      String mensagemErro = 'Erro ao entrar com o Google: $e';
      if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
        mensagemErro = 'Este e-mail já está cadastrado com senha tradicional. Faça login digitando seus dados.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _tentarEntrar() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        DocumentSnapshot docUsuario = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();

        if (!mounted) return;
        
        // FECHAMENTO SEGURO: Fecha o loading tradicional do e-mail antes de mudar de rota
        Navigator.of(context, rootNavigator: true).pop(); 

        if (docUsuario.exists) {
          Map<String, dynamic> dados = docUsuario.data() as Map<String, dynamic>;
          String? perfil = dados['perfil'];

          if (perfil == null || perfil.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EscolhaPerfilPage(
                  uid: userCredential.user!.uid,
                  email: userCredential.user!.email ?? '',
                  nomeInicial: userCredential.user!.displayName ?? '',
                ),
              ),
            );
          } else if (perfil == 'motorista') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bem-vindo, Motorista!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeMotoristaScreen(),
              ),
            );
          } else if (perfil == 'pai' || perfil == 'responsavel') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeResponsavelScreen(),
              ),
            );
          }
        } else {
          // Caso de contorno se o doc sumiu do Firestore
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EscolhaPerfilPage(
                uid: userCredential.user!.uid,
                email: userCredential.user!.email ?? '',
                nomeInicial: userCredential.user!.displayName ?? '',
              ),
            ),
          );
        }
      } on FirebaseAuthException {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Fecha o loading se errar a senha

        String mensajeErro = 'E-mail ou senha incorretos.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeErro), backgroundColor: Colors.red),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.setLanguageCode("pt-BR");
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
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
      if (!mounted) return;
      Navigator.pop(context);
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
      if (!mounted) return;
      Navigator.pop(context);
      print(e);
    }
  }

  InputDecoration _buildInputStyle({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      prefixIcon: Icon(icon, color: AppColors.azulPrincipal),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.azulPrincipal,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoBranco,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.azulPrincipal,
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'lib/core/assets/images/logo2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'FAÇA LOGIN PARA CONTINUAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: _buildInputStyle(
                      hint: 'E-mail',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira o seu e-mail';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Insira um formato de e-mail válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: _buildInputStyle(
                      hint: 'Senha',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.azulPrincipal,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve tener pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _recuperarSenha,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Esqueceu sua senha?',
                        style: TextStyle(
                          color: AppColors.azulPrincipal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  BotaoPrincipal(texto: 'ENTRAR', aoClicar: _tentarEntrar),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1.2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OU ENTRAR COM',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1.2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _fazerLoginComGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                      icon: Image.network(
                        'https://developers.google.com/static/identity/images/g-logo.png',
                        height: 22,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_circle,
                            color: AppColors.azulPrincipal,
                            size: 22,
                          );
                        },
                      ),
                      label: const Text(
                        'Continuar com o Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "NÃO TEM UMA CONTA?",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // CORREÇÃO: No clique de texto limpo, os parâmetros vão como nulos automaticamente para habilitar formulário em branco
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
                            color: AppColors.azulPrincipal,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
      ),
    );
  }
}
