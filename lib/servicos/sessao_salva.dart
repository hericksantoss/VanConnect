import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/modelos.dart';
import '../estado/van_store.dart';
import 'autenticacao_servico.dart';

/// Guarda no aparelho quem está logado, para não pedir login toda vez.
/// (No protótipo os demais dados ficam em memória; com backend, viriam do servidor.)
class SessaoSalva {
  static SharedPreferences? _prefs;
  static const _chave = 'sessao.v1';

  static Future<void> iniciar() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> salvar(VanStore s) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (s.perfil == null) {
      await prefs.remove(_chave);
      return;
    }
    final v = s.veiculo;
    await prefs.setString(
      _chave,
      jsonEncode({
        'perfil': s.perfil!.name,
        'conta': s.conta?.paraJson(),
        'motorista': {
          'contaId': s.contaMotoristaId,
          'nome': s.nomeMotorista,
          'cpf': s.cpfMotorista,
          'rg': s.rgMotorista,
          'cnh': s.cnhMotorista,
          'telefone': s.telefoneMotorista,
          'van': {'apelido': v.apelido, 'modelo': v.modelo, 'placa': v.placa, 'lugares': v.capacidade},
        },
        'responsavel': {
          'contaId': s.contaResponsavelId,
          'nome': s.nomeSessao,
          'telefone': s.telefoneSessao,
          'escopo': s.escopoSessao.name,
          'filhos': s.filhosDoResponsavel,
        },
      }),
    );
  }

  /// Aplica a sessão salva (se houver) antes de abrir o app.
  static void restaurar(VanStore s) {
    final texto = _prefs?.getString(_chave);
    if (texto == null) return;
    try {
      final j = jsonDecode(texto) as Map<String, dynamic>;
      final perfil = Perfil.values.asNameMap()[j['perfil']];
      if (perfil == null) return;
      s.conta = ContaUsuario.deJson(j['conta']);

      final m = j['motorista'] as Map<String, dynamic>;
      s
        ..nomeMotorista = '${m['nome']}'
        ..cpfMotorista = '${m['cpf']}'
        ..rgMotorista = '${m['rg']}'
        ..cnhMotorista = '${m['cnh']}'
        ..telefoneMotorista = '${m['telefone']}';
      final van = m['van'] as Map<String, dynamic>;
      s.veiculo
        ..apelido = '${van['apelido']}'
        ..modelo = '${van['modelo']}'
        ..placa = '${van['placa']}'
        ..capacidade = (van['lugares'] as num).toInt()
        ..motorista = s.nomeMotorista;
      s.contaMotoristaId = m['contaId'] as String?;
      if (s.contaMotoristaId != null) s.deixarSoVanPrincipal();

      final r = j['responsavel'] as Map<String, dynamic>;
      s
        ..contaResponsavelId = '${r['contaId']}'
        ..nomeSessao = '${r['nome']}'
        ..telefoneSessao = '${r['telefone']}'
        ..escopoSessao = Escopo.values.asNameMap()[r['escopo']] ?? Escopo.completo;
      final ids = (r['filhos'] as List).map((e) => '$e').where((id) => s.alunos.any((a) => a.id == id)).toList();
      s.filhosDoResponsavel
        ..clear()
        ..addAll(ids);
      s.perfil = perfil;
    } catch (_) {
      // Sessão de uma versão antiga: ignora e mostra a tela de entrada.
    }
  }
}
