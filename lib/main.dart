import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa a base do Firebase
import 'firebase_options.dart'; // O arquivo gerado pelo FlutterFire


// IMPORTAÇÃO CORRIGIDA: Aponta exatamente para a sua estrutura de pastas
import 'features/auth/screens/login_screen.dart'; 

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Aponta para a classe da sua tela de login (provavelmente LoginScreen)
      home: const LoginScreen(), 
    );
  }
}