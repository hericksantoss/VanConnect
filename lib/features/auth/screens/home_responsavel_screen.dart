import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeResponsavelScreen extends StatefulWidget {
  const HomeResponsavelScreen({super.key});

  @override
  State<HomeResponsavelScreen> createState() => _HomeResponsavelScreenState();
}

class _HomeResponsavelScreenState extends State<HomeResponsavelScreen> {
  final TextEditingController _codigoController = TextEditingController();
  bool _isMapaDesbloqueado = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  void _validarCodigo() {
    if (_codigoController.text.isNotEmpty) {
      setState(() {
        _isMapaDesbloqueado = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tudo pronto! Você já pode acompanhar a van.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. FUNDO: Mapa com Filtro Monocromático
          AbsorbPointer(
            absorbing: !_isMapaDesbloqueado,
            child: ColorFiltered(
              colorFilter: _isMapaDesbloqueado
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: GoogleMap(
                initialCameraPosition: _initialPosition,
                zoomControlsEnabled: _isMapaDesbloqueado,
                myLocationButtonEnabled: false,
              ),
            ),
          ),

          // 2. CAMADA INTERMEDIÁRIA: Escurecimento Suave (Apenas se bloqueado)
          if (!_isMapaDesbloqueado)
            Container(color: Colors.black.withValues(alpha: 0.15)),

          // 3. CENTRO DA TELA: Card de Entrada + Indicação Visual de Bloqueio
          if (!_isMapaDesbloqueado)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Card centralizado com Glassmorphic sutil
                    Card(
                      elevation: 12,
                      color: Colors.white.withValues(alpha: 0.96),
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Acompanhar Van',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Insira o código enviado pelo motorista para liberar o mapa em tempo real.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _codigoController,
                              style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.0),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Ex: VAN-1234',
                                hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                                prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.blueAccent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _validarCodigo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'CONECTAR AGORA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Texto de rodapé amigável substituindo a tarja preta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 8),
                        Text(
                          'Acesso seguro e restrito a responsáveis.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            shadows: const [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 1))],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // 4. BOTÃO CENTRAL DE RASTREIO (Estilo Premium)
      floatingActionButton: FloatingActionButton(
        onPressed: _isMapaDesbloqueado ? () {} : null,
        backgroundColor: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade200,
        elevation: _isMapaDesbloqueado ? 4 : 0,
        shape: CircleBorder(
          side: BorderSide(
            color: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.gps_fixed,
          color: _isMapaDesbloqueado ? Colors.white : Colors.grey.shade400,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 5. BOTTOM NAVBAR (Bordas dos Ícones Condicionais)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_outlined, color: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () {} : null,
            ),
            IconButton(
              icon: Icon(Icons.search, color: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () {} : null,
            ),
            const SizedBox(width: 40), // Espaço livre do botão central
            IconButton(
              icon: Icon(Icons.history, color: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () {} : null,
            ),
            IconButton(
              icon: Icon(Icons.person_outline, color: _isMapaDesbloqueado ? Colors.blueAccent : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () {} : null,
            ),
          ],
        ),
      ),
    );
  }
}