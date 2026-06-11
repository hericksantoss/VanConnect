import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import 'perfil_screen.dart'; 

class HomeResponsavelScreen extends StatefulWidget {
  const HomeResponsavelScreen({super.key});

  @override
  State<HomeResponsavelScreen> createState() => _HomeResponsavelScreenState();
}

class _HomeResponsavelScreenState extends State<HomeResponsavelScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final bool _isMapaDesbloqueado = false;
  int _abaAtiva = 0;

  // Controladores do Formulário do Filho
  final _formFilhoKey = GlobalKey<FormState>();
  final TextEditingController _nomeFilhoController = TextEditingController();
  final TextEditingController _escolaController = TextEditingController();
  String _periodoSelecionado = 'Manhã';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeFilhoController.dispose();
    _escolaController.dispose();
    super.dispose();
  }

  // ETAPA 1: Busca o motorista associado ao código digitado
  Future<void> _processarCodigoVan() async {
    final String codigoDigito = _codigoController.text.trim().toUpperCase();
    if (codigoDigito.isEmpty) return;

    // Loading de busca
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('perfil', isEqualTo: 'motorista')
          .where('codigo_van', isEqualTo: codigoDigito)
          .limit(1)
          .get();

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading

      if (query.docs.isEmpty) {
        _exibirAviso('Nenhuma van encontrada com esse código. Verifique e tente novamente.');
        return;
      }

      // Documento do motorista encontrado
      var motoristaDoc = query.docs.first;
      Map<String, dynamic> dadosMotorista = motoristaDoc.data() as Map<String, dynamic>;

      // Avança para a ETAPA 2: Exibir confirmação
      _exibirPopUpConfirmacaoMotorista(motoristaDoc.id, dadosMotorista);

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _exibirAviso('Erro ao buscar dados: $e');
    }
  }

  // ETAPA 2: Pop-up de segurança para o pai não vincular a van errada
  void _exibirPopUpConfirmacaoMotorista(String motoristaUid, Map<String, dynamic> dados) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Esta é a sua Van?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: dados['fotoUrl'] != null && dados['fotoUrl'].toString().isNotEmpty
                  ? NetworkImage(dados['fotoUrl'])
                  : null,
              child: dados['fotoUrl'] == null || dados['fotoUrl'].toString().isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(dados['nome'] ?? 'Motorista não identificado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(dados['veiculo_modelo'] ?? 'Van Escolar', style: const TextStyle(color: AppColors.textoSuave, fontSize: 14)),
            if (dados['veiculo_placa'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(dados['veiculo_placa'], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NÃO É ESTA", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o Pop-up
              _exibirFormularioFilho(motoristaUid); // Abre o formulário da criança
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.azulPrincipal),
            child: const Text("SIM, CONFIRMAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ETAPA 3: Formulário para capturar os dados da criança e criar as chaves de rota
  void _exibirFormularioFilho(String motoristaUid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Evita o teclado cobrir o botão
          ),
          child: Form(
            key: _formFilhoKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Identificação do Passageiro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Estes dados ajudam o motorista a organizar as rotas e turnos.", style: TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                const SizedBox(height: 20),

                // Campo Nome do Filho
                TextFormField(
                  controller: _nomeFilhoController,
                  decoration: InputDecoration(
                    labelText: "Nome do Filho(a)",
                    prefixIcon: const Icon(Icons.child_care, color: AppColors.azulPrincipal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Insira o nome da criança' : null,
                ),
                const SizedBox(height: 16),

                // Campo Escola
                TextFormField(
                  controller: _escolaController,
                  decoration: InputDecoration(
                    labelText: "Nome da Escola",
                    prefixIcon: const Icon(Icons.school_outlined, color: AppColors.azulPrincipal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Insira o nome da escola' : null,
                ),
                const SizedBox(height: 16),

                // Seletor de Período (Turno)
                const Text("Período Escolar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Manhã")),
                        selected: _periodoSelecionado == 'Manhã',
                        onSelected: (selected) {
                          if (selected) setModalState(() => _periodoSelecionado = 'Manhã');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Tarde")),
                        selected: _periodoSelecionado == 'Tarde',
                        onSelected: (selected) {
                          if (selected) setModalState(() => _periodoSelecionado = 'Tarde');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão de Envio de Vínculo Tardio
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _salvarVinculoNoFirestore(motoristaUid),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.azulPrincipal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("SOLICITAR VÍNCULO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // GRAVAÇÃO ATÔMICA DA SOLICITAÇÃO NO BANCO DE DADOS
  Future<void> _salvarVinculoNoFirestore(String motoristaUid) async {
    if (!_formFilhoKey.currentState!.validate()) return;

    final paiUid = FirebaseAuth.instance.currentUser?.uid;
    if (paiUid == null) return;

    Navigator.pop(context); // Fecha o BottomSheet do formulário

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('vinculos').add({
        'id_motorista': motoristaUid,
        'id_responsavel': paiUid,
        'nome_filho': _nomeFilhoController.text.trim(),
        'escola': _escolaController.text.trim(),
        'periodo': _periodoSelecionado,
        'status': 'pendente', // Motorista precisará aceitar na aba dele!
        'status_presenca': 'aguardando',
        'data_solicitacao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading de salvamento

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada! Aguardando autorização do motorista.'),
          backgroundColor: Colors.orange,
        ),
      );

      // Limpa os campos para o estado padrão
      _codigoController.clear();
      _nomeFilhoController.clear();
      _escolaController.clear();

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _exibirAviso('Falha ao registrar solicitação: $e');
    }
  }

  void _exibirAviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _buildAbaMapa() {
    return Stack(
      children: [
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
            child: const GoogleMap(
              initialCameraPosition: _initialPosition,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
        if (!_isMapaDesbloqueado)
          Container(color: Colors.black.withValues(alpha: 0.15)),

        if (!_isMapaDesbloqueado)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 12,
                    color: Colors.white.withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Acompanhar Van',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulPrincipal, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Insira o código enviado pelo motorista para liberar o mapa em tempo real.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _codigoController,
                            style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.0),
                            textCapitalization: TextCapitalization.characters, // Força caixa alta no teclado
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Ex: VAN-1234',
                              hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                              prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.azulPrincipal),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.azulPrincipal, width: 2.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _processarCodigoVan, // Alterado para disparar a busca real
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text(
                                'CONECTAR AGORA',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> abas = [
      _buildAbaMapa(), 
      const Center(child: Text('Tela de Busca (Futura)')), 
      const Center(child: Text('Tela de Histórico (Futura)')), 
      const PerfilScreen(), 
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.fundoBranco,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey<int>(_abaAtiva),
          child: abas[_abaAtiva],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isMapaDesbloqueado ? () => setState(() => _abaAtiva = 0) : null,
        backgroundColor: _isMapaDesbloqueado 
            ? (_abaAtiva == 0 ? AppColors.azulPrincipal : Colors.blue.shade200) 
            : Colors.grey.shade200,
        elevation: _isMapaDesbloqueado ? 4 : 0,
        shape: CircleBorder(
          side: BorderSide(
            color: _isMapaDesbloqueado ? AppColors.azulPrincipal : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.gps_fixed,
          color: _isMapaDesbloqueado ? Colors.white : Colors.grey.shade400,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                _abaAtiva == 0 ? Icons.home : Icons.home_outlined, 
                color: _abaAtiva == 0 ? AppColors.azulPrincipal : Colors.grey.shade400
              ),
              onPressed: () => setState(() => _abaAtiva = 0),
            ),
            IconButton(
              icon: Icon(Icons.search, color: _abaAtiva == 1 ? AppColors.azulPrincipal : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () => setState(() => _abaAtiva = 1) : null,
            ),
            const SizedBox(width: 40), 
            IconButton(
              icon: Icon(Icons.history, color: _abaAtiva == 2 ? AppColors.azulPrincipal : Colors.grey.shade400),
              onPressed: _isMapaDesbloqueado ? () => setState(() => _abaAtiva = 2) : null,
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