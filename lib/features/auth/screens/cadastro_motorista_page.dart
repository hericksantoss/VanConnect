import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CadastroMotoristaPage extends StatefulWidget {
  const CadastroMotoristaPage({super.key});

  @override
  State<CadastroMotoristaPage> createState() => _CadastroMotoristaPageState();
}

class _CadastroMotoristaPageState extends State<CadastroMotoristaPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmarEmailController = TextEditingController();
  final _telefoneController = TextEditingController();
  // final _placaController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaOculta = true;
  bool _confirmarSenhaOculta = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _confirmarEmailController.dispose();
    _telefoneController.dispose();
    // _placaController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarMotoristaNoFirebase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Cria a conta no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      // 2. Pega o ID único gerado pelo Google
      String uid = userCredential.user!.uid;

      // 3. Salva os dados do motorista no Firestore
      await FirebaseFirestore.instance.collection('utilizadores').doc(uid).set({
        'nome': _nomeController.text
            .trim(), // Verifique se o seu controller chama assim
        'telefone': _telefoneController.text
            .trim(), // Verifique se o seu controller chama assim
        'email': _emailController.text.trim(),
        'perfil': 'motorista',
        'status_conta':
            'pendente_configuracao', // O status que vai exigir a van depois
        'data_registo': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motorista cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Futuramente: Navigator.pushReplacement(...) para a Home
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String mensagemErro = 'Ocorreu um erro ao cadastrar.';

      if (e.code == 'weak-password') {
        mensagemErro = 'A senha digitada é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'invalid-email') {
        mensagemErro = 'E-mail inválido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.pop(context);
      print(e);
    }
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) return "A senha é obrigatória";
    if (valor.length < 8) return "A senha deve ter no mínimo 8 caracteres";
    if (!valor.contains(RegExp(r'[0-9]'))) {
      return "A senha deve conter pelo menos 1 número";
    }
    return null;
  }

  String _formatarTelefone(String valor) {
    valor = valor.replaceAll(RegExp(r'\D'), '');
    if (valor.length > 11) valor = valor.substring(0, 11);

    if (valor.length > 6) {
      return '(${valor.substring(0, 2)}) ${valor.substring(2, 7)}-${valor.substring(7)}';
    } else if (valor.length > 2) {
      return '(${valor.substring(0, 2)}) ${valor.substring(2)}';
    } else if (valor.isNotEmpty) {
      return '(${valor.substring(0)}';
    }
    return valor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Cadastro de Motorista",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        // Protege contra o notch e cantos do dispositivo
        child: LayoutBuilder(
          // Ajuda a calcular o espaço disponível de forma inteligente
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Garante altura mínima
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Crie seu perfil profissional",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Insira seus dados para começar a gerenciar suas rotas e passageiros.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // Nome
                      _buildTextFormField(
                        controller: _nomeController,
                        label: "Nome Completo",
                        hint: "Ex: Herick Silva",
                        icon: Icons.person_outlined,
                        validator: (valor) => valor == null || valor.isEmpty
                            ? "Digite seu nome"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // E-mail
                      _buildTextFormField(
                        controller: _emailController,
                        label: "E-mail",
                        hint: "motorista@email.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return "Digite seu e-mail";
                          }
                          if (!valor.contains("@")) {
                            return "Digite um e-mail válido";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirmação de E-mail
                      _buildTextFormField(
                        controller: _confirmarEmailController,
                        label: "Confirme seu E-mail",
                        hint: "Digite o e-mail novamente",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return "A confirmation de e-mail é obrigatória";
                          }
                          if (valor.trim() != _emailController.text.trim()) {
                            return "Os e-mails não coincidem";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telefone com Máscara
                      _buildTextFormField(
                        controller: _telefoneController,
                        label: "Telefone / WhatsApp",
                        hint: "(11) 99999-9999",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        onChanged: (valor) {
                          final textoFormatado = _formatarTelefone(valor);
                          _telefoneController.value = TextEditingValue(
                            text: textoFormatado,
                            selection: TextSelection.collapsed(
                              offset: textoFormatado.length,
                            ),
                          );
                        },
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return "Digite seu telefone";
                          }
                          final regexTelefone = RegExp(
                            r'^\(\d{2}\) \d{5}-\d{4}$',
                          );
                          if (!regexTelefone.hasMatch(valor)) {
                            return "Digite um telefone válido com DDD";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Placa da Van
                      // _buildTextFormField(
                      //   controller: _placaController,
                      //   label: "Placa da Van",
                      //   hint: "ABC1D23",
                      //   icon: Icons.directions_bus_outlined,
                      //   textCapitalization: TextCapitalization.characters,
                      //   validator: (valor) => valor == null || valor.isEmpty
                      //       ? "Digite a placa da van"
                      //       : null,
                      // ),
                      // const SizedBox(height: 16),

                      // Senha com Olhinho
                      _buildTextFormField(
                        controller: _senhaController,
                        label: "Senha",
                        hint: "Crie uma senha forte",
                        icon: Icons.lock_outlined,
                        isObscure: _senhaOculta,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _senhaOculta
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () =>
                              setState(() => _senhaOculta = !_senhaOculta),
                        ),
                        validator: _validarSenha,
                      ),

                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4, bottom: 16),
                        child: Text(
                          "Mínimo de 8 caracteres, contendo pelo menos 1 número.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                            height: 1.2,
                          ),
                        ),
                      ),

                      // Confirmação de Senha com Olhinho
                      _buildTextFormField(
                        controller: _confirmarSenhaController,
                        label: "Confirme sua Senha",
                        hint: "Digite a senha novamente",
                        icon: Icons.lock_outlined,
                        isObscure: _confirmarSenhaOculta,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmarSenhaOculta
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => setState(
                            () =>
                                _confirmarSenhaOculta = !_confirmarSenhaOculta,
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return "A confirmação de senha é obrigatória";
                          }
                          if (valor != _senhaController.text) {
                            return "As senhas não coincidem";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: () {
                          // 1. Primeiro valida se todos os campos do formulário estão corretos
                          if (_formKey.currentState!.validate()) {
                            // 2. Se os campos forem válidos, dispara a criação de conta no Firebase
                            _cadastrarMotoristaNoFirebase();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "CONCLUIR CADASTRO",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    Color accentColor = Colors.blueAccent,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: accentColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
