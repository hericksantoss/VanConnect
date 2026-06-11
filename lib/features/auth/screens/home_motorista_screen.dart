import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import 'perfil_screen.dart'; // Reutiliza a sua tela de perfil com fade clean
import 'meus_passageiros_aba.dart';

class HomeMotoristaScreen extends StatefulWidget {
  const HomeMotoristaScreen({super.key});

  @override
  State<HomeMotoristaScreen> createState() => _HomeMotoristaScreenState();
}

class _HomeMotoristaScreenState extends State<HomeMotoristaScreen> {
  int _abaAtiva = 0;
  bool _emViagem = false;
  String _codigoVan = "CARREGANDO...";

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _buscarCodigoVan();
  }

  // Coleta o código da van ou gera um temporário para o motorista compartilhar
  Future<void> _buscarCodigoVan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
          setState(() {
            // Se ele já tiver uma van associada puxa o código, se não, exibe o UID parcial para testes
            _codigoVan = dados['codigo_van'] ?? "VAN-${user.uid.substring(0, 5).toUpperCase()}";
          });
        }
      }
    } catch (e) {
      print("Erro ao buscar código da van: $e");
    }
  }

  // Alterna o estado da viagem e dispara o tracking futuramente
  void _confirmarAlternarViagem() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _emViagem ? "Finalizar Rota?" : "Iniciar Rota?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _emViagem 
              ? "Deseja encerrar o rastreio e a transmissão de GPS agora?" 
              : "Isso iniciará o compartilhamento da sua localização em tempo real com os pais. Deseja continuar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancela
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o modal
              _executarMudancaRota();  // Executa a ação real
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _emViagem ? Colors.redAccent : AppColors.azulPrincipal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

// A lógica real de mudança de estado fica isolada aqui
void _executarMudancaRota() {
  setState(() {
    _emViagem = !_emViagem;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_emViagem ? 'Rota iniciada! Pais sendo notificados.' : 'Rota finalizada com sucesso.'),
      backgroundColor: _emViagem ? Colors.green : AppColors.azulPrincipal,
    ),
  );
}

  // Conteúdo da Aba Principal do Motorista (Mapa + Painel de Controle)
  Widget _buildAbaPainel() {
    return Stack(
      children: [
        // 1. Mapa de fundo sempre ativo
        const GoogleMap(
          initialCameraPosition: _initialPosition,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),

        // 2. Card de Informações e Ações Rápidas no topo
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "CÓDIGO DE CONVITE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textoSuave, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _codigoVan,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Compartilhar código via WhatsApp futuramente
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado para a área de transferência!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        foregroundColor: AppColors.azulPrincipal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("COPIAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Card inferior de Status da Rota
        Positioned(
          bottom: 170, // Fica perfeitamente posicionado acima da BottomAppBar
          left: 16,
          right: 16,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _emViagem ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _emViagem ? Icons.directions_bus : Icons.bus_alert,
                          color: _emViagem ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _emViagem ? "Em Viagem" : "Van Estacionada",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _emViagem ? "Transmitindo GPS em tempo real..." : "Pronto para iniciar o trajeto.",
                              style: const TextStyle(fontSize: 13, color: AppColors.textoSuave),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmarAlternarViagem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emViagem ? Colors.redAccent : AppColors.azulPrincipal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _emViagem ? "FINALIZAR ROTA" : "INICIAR ROTA",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> abas = [
      _buildAbaPainel(),      // Aba 0: Painel do Motorista + Mapa
      const MeusPassageirosAba(), // ALTERADO AQUI Aba 1: Lista Real com Gestão de Autorizações do Firestore!
      const Center(child: Text('Minhas Rotas (Futura)')), // Aba 2
      const PerfilScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fundoBranco,
      
      // Transição suave de Fade idêntica à do Responsável
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey<int>(_abaAtiva),
          child: abas[_abaAtiva],
        ),
      ),

      // Botão central flutuante estilizado (Central de Alertas ou Atalho de Emergência)
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    // Abre confirmação de emergência para evitar cliques por erro enquanto dirige
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("ALERTA DE EMERGÊNCIA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text("Deseja enviar um alerta de pânico/emergência para todos os responsáveis agora?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alerta de emergência enviado aos responsáveis!'), backgroundColor: Colors.red),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("DISPARAR ALERTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  },
  backgroundColor: Colors.redAccent,
  elevation: 4,
  shape: const CircleBorder(side: BorderSide(color: Colors.redAccent, width: 2)),
  child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Menu de Navegação Inferior Customizado
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                _abaAtiva == 0 ? Icons.dashboard : Icons.dashboard_outlined, 
                color: _abaAtiva == 0 ? AppColors.azulPrincipal : Colors.grey.shade400
              ),
              onPressed: () => setState(() => _abaAtiva = 0),
            ),
            IconButton(
              icon: Icon(
                Icons.people_outline, 
                color: _abaAtiva == 1 ? AppColors.azulPrincipal : Colors.grey.shade400
              ),
              onPressed: () => setState(() => _abaAtiva = 1),
            ),
            const SizedBox(width: 40), // Espaço do notch do botão central
            IconButton(
              icon: Icon(
                Icons.alt_route, 
                color: _abaAtiva == 2 ? AppColors.azulPrincipal : Colors.grey.shade400
              ),
              onPressed: () => setState(() => _abaAtiva = 2),
            ),
            IconButton(
              icon: Icon(
                _abaAtiva == 3 ? Icons.person : Icons.person_outline, 
                color: _abaAtiva == 3 ? AppColors.azulPrincipal : Colors.grey.shade400
              ),
              onPressed: () => setState(() => _abaAtiva = 3),
            ),
          ],
        ),
      ),
    );
  }
}