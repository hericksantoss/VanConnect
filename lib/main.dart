import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/tema.dart';
import 'estado/van_store.dart';
import 'servicos/sessao_salva.dart';
import 'telas/entrada/boas_vindas.dart';
import 'telas/motorista/shell_motorista.dart';
import 'telas/responsavel/shell_responsavel.dart';
import 'tutoriais/tutoriais.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Tutoriais.iniciar();
  await SessaoSalva.iniciar();
  final store = VanStore();
  // Quem já entrou continua logado ao reabrir o app.
  SessaoSalva.restaurar(store);
  store.aoMudarSessao = () => SessaoSalva.salvar(store);
  runApp(VanConnectApp(store: store));
}

class VanConnectApp extends StatelessWidget {
  const VanConnectApp({super.key, required this.store});

  final VanStore store;

  @override
  Widget build(BuildContext context) {
    return VanScope(
      store: store,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: store.tema,
        builder: (context, modo, _) => MaterialApp(
          title: 'Van Connect',
          debugShowCheckedModeBanner: false,
          theme: criarTema(Brightness.light),
          darkTheme: criarTema(Brightness.dark),
          themeMode: modo,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeOutCubic,
          scrollBehavior: const RolagemIOS(),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final escuro = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (escuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
              child: child!,
            );
          },
          home: const _Raiz(),
        ),
      ),
    );
  }
}

class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final perfil = VanScope.of(context).perfil;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(anim), child: child),
      ),
      child: switch (perfil) {
        null => const BoasVindas(key: ValueKey('entrada')),
        Perfil.motorista => const ShellMotorista(key: ValueKey('motorista')),
        Perfil.responsavel => const ShellResponsavel(key: ValueKey('responsavel')),
      },
    );
  }
}
