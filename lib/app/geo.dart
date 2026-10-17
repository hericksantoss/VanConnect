import 'dart:ui' show Offset;

import 'package:latlong2/latlong.dart';

/// Área de atendimento da demonstração (região central de São Paulo).
/// Os dados guardam posições normalizadas (0..1 dentro desta área); endereços
/// reais fora dela viram valores fora de 0..1 e funcionam do mesmo jeito.
const _norte = -23.548;
const _oeste = -46.672;
const _alturaGraus = 0.036;
const _larguraGraus = 0.048;

LatLng paraLatLng(Offset n) => LatLng(_norte - n.dy * _alturaGraus, _oeste + n.dx * _larguraGraus);

/// Inverso de [paraLatLng]: coordenada real → posição na área de atendimento.
Offset deLatLng(double lat, double lng) => Offset((lng - _oeste) / _larguraGraus, (_norte - lat) / _alturaGraus);

/// Centro da área de atendimento (ponto de partida quando não há endereço).
final centroArea = paraLatLng(const Offset(0.5, 0.5));
