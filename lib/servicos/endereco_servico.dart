import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado da consulta de CEP (ViaCEP).
class DadosCep {
  const DadosCep({required this.cep, required this.logradouro, required this.bairro, required this.cidade, required this.uf});

  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;
}

class ErroEndereco implements Exception {
  const ErroEndereco(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Consulta de CEP e localização no mapa.
///
/// - CEP → rua, bairro e cidade: **ViaCEP** (gratuito, sem chave).
/// - Endereço → latitude/longitude: **Nominatim / OpenStreetMap** (gratuito, sem chave,
///   limite de 1 consulta por segundo). Em produção, troque por um geocodificador
///   com contrato (Google Geocoding, Mapbox, HERE) mantendo esta mesma interface.
class EnderecoServico {
  EnderecoServico({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  static String soDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<DadosCep> buscarCep(String bruto) async {
    final cep = soDigitos(bruto);
    if (cep.length != 8) throw const ErroEndereco('O CEP precisa ter 8 números.');
    final http.Response r;
    try {
      r = await _cliente.get(Uri.parse('https://viacep.com.br/ws/$cep/json/')).timeout(const Duration(seconds: 8));
    } catch (_) {
      throw const ErroEndereco('Sem conexão para consultar o CEP. Verifique a internet.');
    }
    if (r.statusCode != 200) throw const ErroEndereco('CEP inválido.');
    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (json['erro'] == true || json['erro'] == 'true') throw const ErroEndereco('CEP não encontrado.');
    return DadosCep(
      cep: cep,
      logradouro: (json['logradouro'] ?? '') as String,
      bairro: (json['bairro'] ?? '') as String,
      cidade: (json['localidade'] ?? '') as String,
      uf: (json['uf'] ?? '') as String,
    );
  }

  /// Tenta do mais preciso (rua + número) ao mais amplo (CEP, cidade).
  /// Retorna null se nada for encontrado; o motorista ajusta o pino à mão.
  Future<(double, double)?> localizar({
    required String logradouro,
    required String numero,
    required String cidade,
    required String uf,
    required String cep,
  }) async {
    final tentativas = <Map<String, String>>[
      if (logradouro.isNotEmpty) {'street': '$numero $logradouro', 'city': cidade, 'state': uf},
      if (logradouro.isNotEmpty) {'street': logradouro, 'city': cidade, 'state': uf},
      {'postalcode': cep, 'country': 'Brasil'},
      {'city': cidade, 'state': uf},
    ];
    for (final params in tentativas) {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {...params, 'country': 'Brasil', 'format': 'json', 'limit': '1'});
      try {
        final r = await _cliente.get(uri, headers: {'User-Agent': 'VanConnect/0.1 (prototipo)'}).timeout(const Duration(seconds: 8));
        if (r.statusCode != 200) continue;
        final lista = jsonDecode(utf8.decode(r.bodyBytes)) as List<dynamic>;
        if (lista.isEmpty) continue;
        final item = lista.first as Map<String, dynamic>;
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat != null && lon != null) return (lat, lon);
      } catch (_) {
        // tenta a próxima forma de busca
      }
    }
    return null;
  }
}
