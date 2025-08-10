// lib/features/auth/presentation/view/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/main.dart'; // Importa o main para ter acesso ao 'supabase'
import 'package:musilingo/shared/widgets/custom_text_field.dart';

// Convertido para StatefulWidget
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controladores para capturar o texto dos campos
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variável para controlar o estado de carregamento
  bool _isLoading = false;

  // Função para realizar o cadastro
  Future<void> _signUp() async {
    // Verifica se o widget ainda está na árvore de widgets
    if (!mounted) return;

    // Inicia o estado de carregamento
    setState(() {
      _isLoading = true;
    });

    try {
      // Chama a função de cadastro do Supabase
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // Podemos adicionar dados extras, como o nome do usuário
        data: {'full_name': _nameController.text.trim()},
      );

      // Se o cadastro for bem-sucedido, mostra uma mensagem
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sucesso! Verifique seu e-mail para confirmação.'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de login
        Navigator.of(context).pop();
      }
    } catch (error) {
      // Se ocorrer um erro, mostra a mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no cadastro: ${error.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      // Finaliza o estado de carregamento, independentemente do resultado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Limpa os controladores para liberar memória
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Icon(Icons.music_note, color: AppColors.accent, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Crie sua Conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),

                // Conectamos os controladores aos campos de texto
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accent),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(height: 32),

                // Botão de Cadastrar agora chama a função _signUp
                ElevatedButton(
                  // Desabilitamos o botão enquanto estiver carregando
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // Mostra um indicador de progresso ou o texto
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'CADASTRAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Já tem uma conta?', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Faça Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
