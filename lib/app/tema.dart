import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Paleta inspirada nas cores de sistema do iOS + identidade Van Connect
/// (marinho do "Van", azul do "Connect" e amarelo escolar).
@immutable
class Paleta extends ThemeExtension<Paleta> {
  const Paleta({
    required this.escuro,
    required this.fundo,
    required this.cartao,
    required this.elevado,
    required this.preenchimento,
    required this.separador,
    required this.texto,
    required this.textoSuave,
    required this.azul,
    required this.marinho,
    required this.amarelo,
    required this.verde,
    required this.vermelho,
    required this.laranja,
    required this.roxo,
    required this.ambar,
    required this.cinza,
    required this.heroi,
    required this.mapaFundo,
    required this.mapaQuadra,
    required this.mapaParque,
    required this.mapaAgua,
  });

  final bool escuro;
  final Color fundo;
  final Color cartao;
  final Color elevado;
  final Color preenchimento;
  final Color separador;
  final Color texto;
  final Color textoSuave;
  final Color azul;
  final Color marinho;
  final Color amarelo;
  final Color verde;
  final Color vermelho;
  final Color laranja;
  final Color roxo;

  /// Lembretes e atenção (cobranças a vencer).
  final Color ambar;
  final Color cinza;
  final List<Color> heroi;
  final Color mapaFundo;
  final Color mapaQuadra;
  final Color mapaParque;
  final Color mapaAgua;

  static const marinhoMarca = Color(0xFF10213F);
  static const azulMarca = Color(0xFF1E7FD8);
  static const amareloMarca = Color(0xFFFBC02D);

  static const claro = Paleta(
    escuro: false,
    fundo: Color(0xFFF4F6FA),
    cartao: Color(0xFFFFFFFF),
    elevado: Color(0xFFFFFFFF),
    preenchimento: Color(0xFFEBEEF3),
    separador: Color(0xFFE4E8EF),
    texto: Color(0xFF14213D),
    textoSuave: Color(0xFF6B7385),
    azul: azulMarca,
    marinho: marinhoMarca,
    amarelo: amareloMarca,
    verde: Color(0xFF22A06B),
    vermelho: Color(0xFFE5484D),
    laranja: Color(0xFF6E86A8),
    roxo: Color(0xFF4C6FFF),
    ambar: Color(0xFFF59E0B),
    cinza: Color(0xFF8A93A6),
    heroi: [Color(0xFF1E7FD8), Color(0xFF3D9BF0)],
    mapaFundo: Color(0xFFEEF1F5),
    mapaQuadra: Color(0xFFE1E5EC),
    mapaParque: Color(0xFFDCE9F7),
    mapaAgua: Color(0xFFCFE2F8),
  );

  static const noturno = Paleta(
    escuro: true,
    fundo: Color(0xFF0B0F17),
    cartao: Color(0xFF161B26),
    elevado: Color(0xFF1F2633),
    preenchimento: Color(0xFF1F2633),
    separador: Color(0xFF283041),
    texto: Color(0xFFF2F5FA),
    textoSuave: Color(0xFF8E98AB),
    azul: Color(0xFF4FA3FF),
    marinho: Color(0xFFE8EDF7),
    amarelo: Color(0xFFFFCC33),
    verde: Color(0xFF3DD68C),
    vermelho: Color(0xFFFF6369),
    laranja: Color(0xFF8FA3C2),
    roxo: Color(0xFF7B93FF),
    ambar: Color(0xFFFBBF24),
    cinza: Color(0xFF7D879A),
    heroi: [Color(0xFF1A4F8F), Color(0xFF12305A)],
    mapaFundo: Color(0xFF16181D),
    mapaQuadra: Color(0xFF22262E),
    mapaParque: Color(0xFF1C2E24),
    mapaAgua: Color(0xFF172638),
  );

  Color suave(Color c) => c.withValues(alpha: escuro ? 0.22 : 0.13);

  @override
  Paleta copyWith() => this;

  /// Interpola todas as cores: a troca claro ↔ escuro fica suave.
  @override
  Paleta lerp(Paleta? o, double t) {
    if (o == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Paleta(
      escuro: t < 0.5 ? escuro : o.escuro,
      fundo: c(fundo, o.fundo),
      cartao: c(cartao, o.cartao),
      elevado: c(elevado, o.elevado),
      preenchimento: c(preenchimento, o.preenchimento),
      separador: c(separador, o.separador),
      texto: c(texto, o.texto),
      textoSuave: c(textoSuave, o.textoSuave),
      azul: c(azul, o.azul),
      marinho: c(marinho, o.marinho),
      amarelo: c(amarelo, o.amarelo),
      verde: c(verde, o.verde),
      vermelho: c(vermelho, o.vermelho),
      laranja: c(laranja, o.laranja),
      roxo: c(roxo, o.roxo),
      ambar: c(ambar, o.ambar),
      cinza: c(cinza, o.cinza),
      heroi: [c(heroi[0], o.heroi[0]), c(heroi[1], o.heroi[1])],
      mapaFundo: c(mapaFundo, o.mapaFundo),
      mapaQuadra: c(mapaQuadra, o.mapaQuadra),
      mapaParque: c(mapaParque, o.mapaParque),
      mapaAgua: c(mapaAgua, o.mapaAgua),
    );
  }
}

extension PaletaContexto on BuildContext {
  Paleta get cores => Theme.of(this).extension<Paleta>()!;
}

/// Cor estável por nome (avatares).
Color corDoNome(String nome, Paleta p) {
  final opcoes = [p.azul, p.roxo, p.laranja, p.verde, const Color(0xFFFF2D55), const Color(0xFF5AC8FA), const Color(0xFF5856D6)];
  return opcoes[nome.codeUnits.fold<int>(0, (a, b) => a + b) % opcoes.length];
}

ThemeData criarTema(Brightness brilho) {
  final p = brilho == Brightness.dark ? Paleta.noturno : Paleta.claro;
  final esquema = ColorScheme.fromSeed(
    seedColor: Paleta.azulMarca,
    brightness: brilho,
    primary: p.azul,
    secondary: p.amarelo,
    surface: p.cartao,
    error: p.vermelho,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: esquema,
    scaffoldBackgroundColor: p.fundo,
    extensions: [p],
    // Sem ripple do Material: a resposta ao toque vem do componente Tocavel (escala).
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    // Cada sistema com a sua transição natural (Android: fade; iPhone: lateral com gesto de voltar).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brilho,
      primaryColor: p.azul,
      barBackgroundColor: p.fundo.withValues(alpha: 0.82),
      scaffoldBackgroundColor: p.fundo,
      textTheme: CupertinoTextThemeData(
        primaryColor: p.azul,
        textStyle: TextStyle(color: p.texto, fontSize: 17, letterSpacing: -0.4),
        navLargeTitleTextStyle: TextStyle(color: p.texto, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.9),
        navTitleTextStyle: TextStyle(color: p.texto, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
      ),
    ),
    textTheme: Typography.material2021(platform: TargetPlatform.iOS).black
        .apply(bodyColor: p.texto, displayColor: p.texto)
        .copyWith(
          // Título grande das páginas (SliverAppBar.large) e o título encolhido.
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: p.texto),
          titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: p.texto),
        ),
    iconTheme: IconThemeData(color: p.texto),
    dividerTheme: DividerThemeData(color: p.separador, space: 0.5, thickness: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.preenchimento,
      hintStyle: TextStyle(color: p.textoSuave),
      labelStyle: TextStyle(color: p.textoSuave),
      prefixIconColor: p.textoSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.azul, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.escuro ? p.elevado : const Color(0xFF1C1C1E),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.fundo,
      showDragHandle: true,
      dragHandleColor: p.cinza.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.azul),
  );
}

/// Rolagem com "elástico" do iOS em todas as plataformas.
class RolagemIOS extends MaterialScrollBehavior {
  const RolagemIOS();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
