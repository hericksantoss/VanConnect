import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class MeusPassageirosAba extends StatefulWidget {
  const MeusPassageirosAba({super.key});

  @override
  State<MeusPassageirosAba> createState() => _MeusPassageirosAbaState();
}

class _MeusPassageirosAbaState extends State<MeusPassageirosAba> {
  final String _uidMotorista = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Função para atualizar o status do vínculo no Firestore (Aprovar ou Recusar)
  Future<void> _atualizarStatusVinculo(String docId, String novoStatus) async {
    try {
      await FirebaseFirestore.instance.collection('vinculos').doc(docId).update(
        {
          'status': novoStatus,
          'data_autorizacao': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoStatus == 'ativo'
                ? 'Passageiro autorizado com sucesso!'
                : 'Solicitação recusada.',
          ),
          backgroundColor: novoStatus == 'ativo'
              ? Colors.green
              : Colors.redAccent,
        ),
      );
    } catch (e) {
      print("Erro ao atualizar status: $e");
    }
  }

  // Modal de confirmação antes de aprovar ou recusar
  void _confirmarAcao(String docId, String nomeFilho, String acao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          acao == 'ativo' ? "Autorizar Passageiro?" : "Recusar Solicitação?",
        ),
        content: Text(
          acao == 'ativo'
              ? "Deseja permitir que os responsáveis de $nomeFilho vejam a sua localização em tempo real?"
              : "Tem certeza que deseja recusar a solicitação de vínculo para $nomeFilho?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _atualizarStatusVinculo(docId, acao);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: acao == 'ativo'
                  ? Colors.green
                  : Colors.redAccent,
            ),
            child: const Text(
              "CONFIRMAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uidMotorista.isEmpty) {
      return const Center(child: Text("Utilizador não autenticado."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Passageiros & Vínculos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escuta em tempo real todos os vínculos criados para este motorista específico
        stream: FirebaseFirestore.instance
            .collection('vinculos')
            .where('id_motorista', isEqualTo: _uidMotorista)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nenhum passageiro ou solicitação encontrada.",
                    style: TextStyle(color: AppColors.textoSuave, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Separa os documentos entre pendentes e ativos
          List<QueryDocumentSnapshot> pendentes = [];
          List<QueryDocumentSnapshot> ativos = [];

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
            if (dados['status'] == 'pendente') {
              pendentes.add(doc);
            } else if (dados['status'] == 'ativo') {
              ativos.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              120,
            ), // Padding inferior para o card não sumir atrás da barra
            children: [
              // =========================================================================
              // SEÇÃO: SOLICITAÇÕES PENDENTES
              // =========================================================================
              if (pendentes.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "PEDIDOS DE AUTORIZAÇÃO",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendentes.length,
                  itemBuilder: (context, index) {
                    var doc = pendentes[index];
                    Map<String, dynamic> dados =
                        doc.data() as Map<String, dynamic>;
                    String nomeFilho = dados['nome_filho'] ?? 'Criança';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade50,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                ),
                              ),
                              title: Text(
                                nomeFilho,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                "Solicitou vínculo à sua Van",
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _confirmarAcao(
                                    doc.id,
                                    nomeFilho,
                                    'recusado',
                                  ),
                                  child: const Text(
                                    "RECUSAR",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _confirmarAcao(
                                    doc.id,
                                    nomeFilho,
                                    'ativo',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "AUTORIZAR",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // =========================================================================
              // SEÇÃO: PASSAGEIROS ATIVOS
              // =========================================================================
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.azulPrincipal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "PASSAGEIROS ATIVOS (COM ACESSO AO GPS)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulPrincipal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (ativos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Nenhum passageiro ativo no momento.",
                      style: TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ativos.length,
                  itemBuilder: (context, index) {
                    var doc = ativos[index];
                    Map<String, dynamic> dados =
                        doc.data() as Map<String, dynamic>;
                    String nomeFilho = dados['nome_filho'] ?? 'Criança';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.directions_bus_filled,
                            color: AppColors.azulPrincipal,
                          ),
                        ),
                        title: Text(
                          nomeFilho,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          "Status: Monitoramento Ativo",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _confirmarAcao(
                            doc.id,
                            nomeFilho,
                            'recusado',
                          ), // Permite remover o acesso depois se precisar
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
