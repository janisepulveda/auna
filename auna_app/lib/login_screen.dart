// login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_scaffold.dart';
import 'user_provider.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginView = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // === FONDO LOGIN ===
          Image.asset(
            'assets/imagenes/login.JPG',   // <<<<<<<<<<<<<<<<<<<<<< AQUÍ TU FONDO
            fit: BoxFit.cover,
          ),

          // === CAPA DE CONTENIDO ===
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // logo
                    Image.asset(
                      'assets/imagenes/auna05.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'AUNA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 34),

                    // ===== GLASS FORM CONTAINER =====
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20), // más transparente
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.40),
                              width: 1.2,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isLoginView
                                ? _buildLoginForm()
                                : _buildSignUpForm(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildDivider(),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton('assets/imagenes/google_logo.png'),
                        const SizedBox(width: 22),
                        _buildSocialButton('assets/imagenes/apple_logo.png'),
                      ],
                    ),

                    const SizedBox(height: 25),
                    _buildBottomText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.20),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.25),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Bienvenida a Auna', 'Tu espacio personal de registro.'),
        const SizedBox(height: 20),

        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Correo'),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Contraseña'),
          obscureText: true,
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Olvidé mi contraseña'),
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            final email = _emailController.text;
            const name = 'Ana Pérez';
            Provider.of<UserProvider>(context, listen: false).login(name, email);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
          },
          style: _buildButtonStyle(),
          child: const Text('Iniciar sesión'),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Crea tu cuenta', 'Regístrate para empezar.'),
        const SizedBox(height: 20),

        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Nombre'),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Correo'),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Contraseña'),
          obscureText: true,
        ),
        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: () {
            final name = _nameController.text;
            final email = _emailController.text;
            Provider.of<UserProvider>(context, listen: false).login(name, email);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
          },
          style: _buildButtonStyle(),
          child: const Text('Registrarse'),
        ),
      ],
    );
  }

  Widget _buildFormTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white70)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('O ingresa con', style: TextStyle(color: Colors.white70)),
        ),
        Expanded(child: Divider(color: Colors.white70)),
      ],
    );
  }

  Widget _buildSocialButton(String imagePath) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Image.asset(imagePath, height: 30, width: 30),
      ),
    );
  }

  Widget _buildBottomText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginView ? '¿No tienes una cuenta?' : '¿Ya tienes una cuenta?',
          style: const TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginView = !_isLoginView),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(_isLoginView ? 'Regístrate' : 'Inicia sesión'),
        )
      ],
    );
  }
}
