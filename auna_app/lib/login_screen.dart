// login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'main_scaffold.dart';
import 'user_provider.dart'; 
import 'dart:ui'; // esta importación permite usar backdropfilter para el efecto glass

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // estado para alternar entre vista de inicio de sesión y registro
  bool _isLoginView = true;

  // controladores de texto para leer y escribir en los inputs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // liberar controladores para evitar fugas de memoria
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // usamos un stack para poner el fondo como imagen a pantalla completa
      body: Stack(
        children: [
          // 1) capa de fondo: imagen a pantalla completa con cover
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/imagenes/florero_0_abiertas.png'),
                fit: BoxFit.cover, // cubre toda la pantalla, recortando de ser necesario
              ),
            ),
          ),

          // 2) capa de contenido: formulario con efecto glass
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // logo/imagotipo de la app
                    Image.asset(
                      'assets/imagenes/auna05.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 10),

                    // título principal de la pantalla
                    const Text(
                      'AUNA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // contenedor glass: desenfoque + borde + fondo translúcido
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            // fondo blanco translúcido (aprox 20% opacidad)
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            // borde blanco tenue (aprox 30% opacidad)
                            border: Border.all(color: Colors.white.withAlpha(77)),
                          ),
                          // animatedswitcher permite transiciones suaves entre login y signup
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

                    // separador con texto “o ingresa con”
                    _buildDivider(),

                    const SizedBox(height: 20),

                    // botones sociales (sólo visual por ahora)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton('assets/imagenes/google_logo.png'),
                        const SizedBox(width: 20),
                        _buildSocialButton('assets/imagenes/apple_logo.png'),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // texto inferior para alternar entre login y registro
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

  // construcción común de decoración para los inputs (estilo glass coherente)
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),

      // fondo translúcido interno del campo
      filled: true,
      fillColor: Colors.white.withAlpha(26),

      // borde cuando no está enfocado (blanco suave)
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withAlpha(102)),
        borderRadius: BorderRadius.circular(12),
      ),

      // borde cuando está enfocado (blanco sólido)
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // estilo común para botones principales (elevatedbutton)
  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF333A56).withAlpha(204), // color oscuro translúcido
      foregroundColor: Colors.white,                             // texto e ícono en blanco
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // formulario: iniciar sesión
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'), // clave para animatedswitcher
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Bienvenida a Auna', 'Tu espacio personal de registro.'),
        const SizedBox(height: 24),

        // campo correo
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white), // texto del input en blanco
          decoration: _buildInputDecoration('Correo'),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // campo contraseña
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Contraseña'),
          obscureText: true, // oculta el texto
        ),

        const SizedBox(height: 12),

        // enlace “olvidé mi contraseña”
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {}, // aquí iría la lógica de recuperación
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Olvidé mi contraseña'),
          ),
        ),

        const SizedBox(height: 20),

        // botón principal: iniciar sesión
        ElevatedButton(
          onPressed: () {
            // lectura simple de email y ejemplo de nombre
            final email = _emailController.text;
            final name = 'Ana Pérez'; // ejemplo fijo para pruebas

            // simula login y guarda usuario en provider
            Provider.of<UserProvider>(context, listen: false).login(name, email);

            // navega a la app principal reemplazando la pantalla actual
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

  // formulario: registro de nueva cuenta
  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup'), // clave para animatedswitcher
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Crea tu cuenta', 'Regístrate para empezar.'),
        const SizedBox(height: 24),

        // campo nombre
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Nombre'),
        ),

        const SizedBox(height: 16),

        // campo correo
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Correo'),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // campo contraseña
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Contraseña'),
          obscureText: true,
        ),

        const SizedBox(height: 30),

        // botón principal: registrarse
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text;
            final email = _emailController.text;

            // simula registro y guarda usuario en provider
            Provider.of<UserProvider>(context, listen: false).login(name, email);

            // navega a la app principal reemplazando la pantalla actual
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

  // cabecera de cada formulario con título y subtítulo
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
            color: Colors.white.withAlpha(204), // blanco con ~80% opacidad
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // separador visual con texto intermedio
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

  // botón circular para acceso social (placeholder visual)
  Widget _buildSocialButton(String imagePath) {
    return InkWell(
      onTap: () {}, // aquí iría la integración con el proveedor social
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

  // texto inferior para alternar entre iniciar sesión y registrarse
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
            // alterna entre las dos vistas y dispara animación
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
