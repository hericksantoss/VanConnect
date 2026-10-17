import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum SituacaoGps {
  /// Localização ligada e com permissão: pode transmitir.
  pronto,

  /// O GPS do celular está desligado.
  desligado,

  /// O app ainda não tem permissão (pode pedir).
  semPermissao,

  /// Permissão negada de vez: só pelos ajustes do sistema.
  bloqueado,
}

/// Acesso à localização do celular. Interface para trocar nos testes.
abstract class LocalizacaoServico {
  Future<SituacaoGps> verificar({bool pedirPermissao = false});
  Future<void> abrirAjustesLocalizacao();
  Future<void> abrirAjustesDoApp();

  /// true quando o GPS está ligado. Pode não emitir em plataformas sem suporte.
  Stream<bool> get gpsLigado;
}

class LocalizacaoGeolocator implements LocalizacaoServico {
  @override
  Future<SituacaoGps> verificar({bool pedirPermissao = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return SituacaoGps.desligado;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied && pedirPermissao) {
        permissao = await Geolocator.requestPermission();
      }
      return switch (permissao) {
        LocationPermission.always || LocationPermission.whileInUse => SituacaoGps.pronto,
        LocationPermission.deniedForever => SituacaoGps.bloqueado,
        _ => SituacaoGps.semPermissao,
      };
    } catch (_) {
      return SituacaoGps.desligado;
    }
  }

  @override
  Future<void> abrirAjustesLocalizacao() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }

  @override
  Future<void> abrirAjustesDoApp() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  @override
  Stream<bool> get gpsLigado {
    try {
      return Geolocator.getServiceStatusStream().map((s) => s == ServiceStatus.enabled);
    } catch (_) {
      return const Stream.empty(); // ex.: navegador
    }
  }
}

/// Para testes e demonstração: situação controlada à mão.
class LocalizacaoFalsa implements LocalizacaoServico {
  LocalizacaoFalsa([this.situacao = SituacaoGps.pronto]);

  SituacaoGps situacao;
  final _gps = StreamController<bool>.broadcast();

  void mudar(SituacaoGps nova) {
    situacao = nova;
    _gps.add(nova != SituacaoGps.desligado);
  }

  @override
  Future<SituacaoGps> verificar({bool pedirPermissao = false}) async {
    if (situacao == SituacaoGps.semPermissao && pedirPermissao) situacao = SituacaoGps.pronto;
    return situacao;
  }

  @override
  Future<void> abrirAjustesLocalizacao() async {}

  @override
  Future<void> abrirAjustesDoApp() async {}

  @override
  Stream<bool> get gpsLigado => _gps.stream;
}
