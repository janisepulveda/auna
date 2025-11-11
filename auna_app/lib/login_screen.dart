// login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'main_scaffold.dart';
import 'user_provider.dart'; 
import 'dart:ui'; // <-- ¡AQUÍ ESTÁ LA LÍNEA CLAVE!

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
      body: Stack(
        children: [
          // 1. EL FONDO DE IMAGEN
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Ya estoy usando tu imagen 'dia.png'
                image: AssetImage('assets/imagenes/florero_0_abiertas.png'), 
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. EL CONTENIDO (tu formulario)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const SizedBox(height: 30),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            // <-- CAMBIO: 0.2 * 255 = 51
                            color: Colors.white.withAlpha(51), 
                            borderRadius: BorderRadius.circular(20),
                            // <-- CAMBIO: 0.3 * 255 = 77
                            border: Border.all(color: Colors.white.withAlpha(77)),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _isLoginView
                                ? _buildLoginForm()
                                : _buildSignUpForm(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton('assets/imagenes/google_logo.png'),
                        const SizedBox(width: 20),
                        _buildSocialButton('assets/imagenes/apple_logo.png'),
                      ],
                    ),
                    const SizedBox(height: 30),
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

  // <-- CAMBIO COMPLETO: Esta es la función que ARREGLA tus campos de texto
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      
      // Relleno traslúcido para el campo de texto
      filled: true,
      // <-- CAMBIO: 0.1 * 255 = 26
      fillColor: Colors.white.withAlpha(26), 

      // Borde sutil cuando no está enfocado
      enabledBorder: OutlineInputBorder(
        // <-- CAMBIO: 0.4 * 255 = 102
        borderSide: BorderSide(color: Colors.white.withAlpha(102)),
        borderRadius: BorderRadius.circular(12),
      ),
      // Borde más brillante cuando está enfocado
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Define un estilo común para los botones principales
  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      // <-- CAMBIO: 0.8 * 255 = 204
      backgroundColor: const Color(0xFF333A56).withAlpha(204),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Bienvenida a Auna', 'Tu espacio personal de registro.'),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white), // <-- Texto que escribes es blanco
          decoration: _buildInputDecoration('Correo'), // <-- Usa la nueva decoración
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white), // <-- Texto que escribes es blanco
          decoration: _buildInputDecoration('Contraseña'), // <-- Usa la nueva decoración
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
            final name = 'Ana Pérez'; // Ejemplo
            Provider.of<UserProvider>(context, listen: false).login(name, email);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScaffold()),
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
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white), // <-- Texto que escribes es blanco
          decoration: _buildInputDecoration('Nombre'), // <-- Usa la nueva decoración
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white), // <-- Texto que escribes es blanco
          decoration: _buildInputDecoration('Correo'), // <-- Usa la nueva decoración
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white), // <-- Texto que escribes es blanco
          decoration: _buildInputDecoration('Contraseña'), // <-- Usa la nueva decoración
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
              MaterialPageRoute(builder: (context) => const MainScaffold()),
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
              // <-- CAMBIO: 0.8 * 255 = 204
              color: Colors.white.withAlpha(204),
              fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(thickness: 1, color: Colors.white70)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('O ingresa con', style: TextStyle(color: Colors.white70)),
        ),
        Expanded(child: Divider(thickness: 1, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSocialButton(String imagePath) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Image.asset(
          imagePath,
          height: 30,
          width: 30,
        ),
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
          onPressed: () {
            setState(() {
              _isLoginView = !_isLoginView;
            });
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(_isLoginView ? 'Regístrate' : 'Inicia sesión'),
        ),
      ],
    );
  }
}