import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart'; // Ajuste o caminho do seu tema conforme o projeto
import 'home_responsavel_screen.dart';

class CadastroPaiPage extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? nomeInicial;
  final String? fotoUrl;

  const CadastroPaiPage({
    super.key,
    this.uid,
    this.email,
    this.nomeInicial,
    this.fotoUrl,
  });

  @override
  State<CadastroPaiPage> createState() => _CadastroPaiPageState();
}

class _CadastroPaiPageState extends State<CadastroPaiPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmarEmailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaOculta = true;
  bool _confirmarSenhaOculta = true;
  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();

    // Força o Flutter a registrar o texto nos controladores antes da renderização do layout
    if (widget.nomeInicial != null && widget.nomeInicial!.isNotEmpty) {
      _nomeController.text = widget.nomeInicial!;
    }

    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
      _confirmarEmailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _confirmarEmailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarPaiNoFirebase() async {
    setState(() => _estaCarregando = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String uidFinal = widget.uid ?? '';
      String emailFinal = _emailController.text.trim();

      // Se for por E-MAIL tradicional, cria as credenciais no Auth
      if (widget.uid == null) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailFinal,
              password: _senhaController.text.trim(),
            );
        uidFinal = userCredential.user!.uid;
      }

      // Gravando o documento unificado e definitivo na coleção 'usuarios'
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uidFinal)
          .set({
            'nome': _nomeController.text.trim(),
            'telefone': _telefoneController.text.trim(),
            'email': emailFinal,
            'fotoUrl': widget.fotoUrl ?? '',
            'perfil': 'pai',
            'status_conta': 'ativo',
            'data_registo': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responsável registrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Redireciona destruindo o fluxo de login para a tela de mapas do pai
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeResponsavelScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      String mensagemErro = 'Ocorreu um erro ao registrar.';

      if (e.code == 'weak-password') {
        mensagemErro = 'A palavra-passe digitada é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está registrado.';
      } else if (e.code == 'invalid-email') {
        mensagemErro = 'E-mail inválido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print(e);
    } finally {
      setState(() => _estaCarregando = false);
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
    final bool veioDoGoogle = widget.uid != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Cadastro do Responsável",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Acompanhe seu filho",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Crie sua conta e insira o código enviado pelo motorista para vincular a van.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // Campo Nome
                      _buildTextFormField(
                        controller: _nomeController,
                        label: "Nome Completo",
                        hint: "Ex: Carlos Silva",
                        icon: Icons.person_outline,
                        validator: (valor) => valor == null || valor.isEmpty
                            ? "Digite seu nome"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Campo E-mail
                      _buildTextFormField(
                        controller: _emailController,
                        label: "E-mail",
                        hint: "pais@email.com",
                        icon: Icons.email_outlined,
                        enabled:
                            !veioDoGoogle, // Fica desativado se veio do Google
                        fillColor: veioDoGoogle
                            ? Colors.grey.shade100
                            : Colors.white, // Muda a cor de fundo se travado
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

                      // Campo Confirmação de E-mail (Ocultado se veio do Google)
                      if (!veioDoGoogle) ...[
                        _buildTextFormField(
                          controller: _confirmarEmailController,
                          label: "Confirme seu E-mail",
                          hint: "Digite o e-mail novamente",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return "A confirmação de e-mail é obrigatória";
                            }
                            if (valor.trim() != _emailController.text.trim()) {
                              return "Os e-mails não coincidem";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Campo Telefone
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

                      // Campos de Senha (SÓ SURGEM SE NÃO VEIO DO GOOGLE)
                      if (!veioDoGoogle) ...[
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
                              color: AppColors.azulPrincipal,
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
                              color: AppColors.azulPrincipal,
                            ),
                            onPressed: () => setState(
                              () => _confirmarSenhaOculta =
                                  !_confirmarSenhaOculta,
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
                      ],

                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _cadastrarPaiNoFirebase();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulPrincipal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
    bool isObscure = false,
    bool enabled = true,
    Color fillColor = Colors.white,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        prefixIcon: Icon(icon, color: AppColors.azulPrincipal),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.azulPrincipal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
