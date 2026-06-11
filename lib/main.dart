import 'package:VanConnect/features/auth/screens/home_motorista_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa a base do Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // O arquivo gerado pelo FlutterFire

// IMPORTAÇÕES DO SEU ECOSSISTEMA DE TELAS
import 'features/auth/screens/login_screen.dart'; 
import 'features/auth/screens/home_responsavel_screen.dart';
import 'features/auth/screens/escolha_perfil_page.dart';

void main() async {
  // Garante que todas as comunicações nativas do Flutter estejam prontas antes de iniciar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase usando as configurações automáticas do seu projeto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanConnect',
      debugShowCheckedModeBanner: false,
      // Mantém exatamente a identidade visual que você definiu
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      
      // A MÁGICA DE SESSÃO PERSISTENTE COMEÇA AQUI:
      // O StreamBuilder escuta em background se o chip do celular guardou o token de login
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Enquanto o Firebase lê a memória do Moto G100, mostra um loading limpo na tela branca
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // POSSIBILIDADE 2: O usuário já está logado no aparelho!
          if (snapshot.hasData && snapshot.data != null) {
            return const RoteadorDeSessaoHome(); // Passa o controle para decidir a Home certa pelo Firestore
          }

          // POSSIBILIDADE 1: Não há sessão ativa na memória, joga para a tela de login tradicional
          return const LoginScreen();
        },
      ), 
    );
  }
}

// Widget inteligente que faz a leitura da chave primária (UID) no banco de dados 
// para saber se redireciona o usuário para o fluxo de Motorista ou de Pai/Responsável
class RoteadorDeSessaoHome extends StatelessWidget {
  const RoteadorDeSessaoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).get(),
      builder: (context, snapshot) {
        // Aguarda a consulta ao Firestore terminar
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o documento existe, lê o campo 'perfil' salvo na persistência tardia
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> dados = snapshot.data!.data() as Map<String, dynamic>;
          String? perfil = dados['perfil'];

          if (perfil == 'motorista') {
  return const HomeMotoristaScreen(); 

          } else if (perfil == 'pai' || perfil == 'responsavel') {
            return const HomeResponsavelScreen(); // Abre direto na tela com o seu mapa e a barra inferior!
          }
        }

        // Caso de contorno de segurança: se o usuário está autenticado no Auth mas por algum motivo
        // fechou o app na tela de Escolha de Perfil sem concluir o cadastro, o app manda ele de volta 
        // para a Escolha de Perfil passando os dados salvos para não gerar dados órfãos.
        return EscolhaPerfilPage(
          uid: user?.uid, 
          email: user?.email ?? '',
          nomeInicial: user?.displayName ?? '',
          fotoUrl: user?.photoURL ?? '',
        );
      },
    );
  }
}