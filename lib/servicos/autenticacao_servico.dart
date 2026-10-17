enum ProvedorLogin {
  google('Google'),
  facebook('Facebook'),
  email('E-mail'),
  demonstracao('Demonstração');

  const ProvedorLogin(this.rotulo);
  final String rotulo;
}

class ContaUsuario {
  const ContaUsuario({required this.id, required this.nome, required this.email, required this.provedor});

  final String id;
  final String nome;
  final String email;
  final ProvedorLogin provedor;

  Map<String, Object?> paraJson() => {'id': id, 'nome': nome, 'email': email, 'provedor': provedor.name};

  static ContaUsuario? deJson(Object? j) {
    if (j is! Map) return null;
    return ContaUsuario(
      id: '${j['id']}',
      nome: '${j['nome']}',
      email: '${j['email']}',
      provedor: ProvedorLogin.values.asNameMap()['${j['provedor']}'] ?? ProvedorLogin.email,
    );
  }
}

/// Login. O protótipo usa [AutenticacaoDemonstracao]; em produção, troque por uma
/// implementação com Firebase Auth (Google: `google_sign_in`; Facebook:
/// `flutter_facebook_auth`) — veja o README.
abstract class AutenticacaoServico {
  /// true quando os botões de Google/Facebook ainda são simulados.
  bool get demonstracao;

  Future<ContaUsuario> entrar(ProvedorLogin provedor, {required String nome, required String email});
  Future<void> sair();
}

class AutenticacaoDemonstracao implements AutenticacaoServico {
  @override
  bool get demonstracao => true;

  @override
  Future<ContaUsuario> entrar(ProvedorLogin provedor, {required String nome, required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final id = '${provedor.name}-${email.trim().toLowerCase().hashCode.toUnsigned(32).toRadixString(16)}';
    return ContaUsuario(id: id, nome: nome.trim(), email: email.trim(), provedor: provedor);
  }

  @override
  Future<void> sair() async {}
}
