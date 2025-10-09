// login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. importa el paquete provider
import 'main_scaffold.dart';
import 'user_provider.dart'; // <-- 2. importa tu user_provider

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginView = true;

  // 3. crea los controladores para leer el texto de los campos.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 4. es muy importante "limpiar" los controladores cuando la pantalla se destruye para evitar fugas de memoria.
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // tu logo.
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
                    color: Color(0xFF333A56),
                  ),
                ),
                const SizedBox(height: 30),

                // contenedor principal del formulario.
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // una sombra sutil para darle profundidad.
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  // usamos un widget animado para una transición suave entre login y registro.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    // mostramos un formulario u otro dependiendo del valor de _isloginview.
                    child: _isLoginView
                        ? _buildLoginForm()
                        : _buildSignUpForm(),
                  ),
                ),
                const SizedBox(height: 20),

                // divisor con texto para las opciones de redes sociales.
                _buildDivider(),

                const SizedBox(height: 20),

                // botones para iniciar sesión con google y apple.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                        'assets/imagenes/google_logo.png'), // necesitas agregar esta imagen.
                    const SizedBox(width: 20),
                    _buildSocialButton(
                        'assets/imagenes/apple_logo.png'), // necesitas agregar esta imagen.
                  ],
                ),

                const SizedBox(height: 30),

                // texto y botón para cambiar entre las vistas de login y registro.
                _buildBottomText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // widget que construye el formulario de inicio de sesión.
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'), // una 'key' para ayudar a la animación.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Bienvenida a Auna', 'Tu espacio personal de registro.'),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController, // <-- 5. asigna el controlador
          decoration: const InputDecoration(hintText: 'Correo'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController, // <-- 5. asigna el controlador
          decoration: const InputDecoration(hintText: 'Contraseña'),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        // botón para recuperar contraseña.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // aquí va la lógica para recuperar la contraseña.
            },
            child: const Text('Olvidé mi contraseña'),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // 6. lee el texto del controlador.
            final email = _emailController.text;
            
            // como en el login no pedimos el nombre, usaremos uno genérico para este ejemplo.
            // en una app real, aquí buscarías el nombre en la base de datos con el email.
            final name = 'Ana Pérez';

            // 7. llama al provider para guardar los datos del usuario.
            Provider.of<UserProvider>(context, listen: false).login(name, email);
            
            // 8. navega a la pantalla principal.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScaffold()),
            );
          },
          child: const Text('Iniciar sesión'),
        ),
      ],
    );
  }

  // widget que construye el formulario de registro.
  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup'), // una 'key' para ayudar a la animación.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormTitle('Crea tu cuenta', 'Regístrate para empezar.'),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController, // <-- 5. asigna el controlador
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController, // <-- 5. asigna el controlador
          decoration: const InputDecoration(hintText: 'Correo'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController, // <-- 5. asigna el controlador
          decoration: const InputDecoration(hintText: 'Contraseña'),
          obscureText: true,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // 6. lee el texto de los controladores.
            final name = _nameController.text;
            final email = _emailController.text;

            // 7. llama al provider para guardar los datos del nuevo usuario.
            Provider.of<UserProvider>(context, listen: false).login(name, email);
            
            // 8. navega a la pantalla principal.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScaffold()),
            );
          },
          child: const Text('Registrarse'),
        ),
      ],
    );
  }

  // ... el resto de tus widgets (_buildFormTitle, _buildDivider, etc.) no cambian ...
  // widget reutilizable para los títulos del formulario.
  Widget _buildFormTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333A56),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  // widget reutilizable para el divisor "o ingresa con".
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('O ingresa con', style: TextStyle(color: Colors.grey[600])),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  // widget reutilizable para los botones de redes sociales.
  Widget _buildSocialButton(String imagePath) {
    return InkWell(
      onTap: () {
        // aquí va la lógica para el inicio de sesión con google o apple.
      },
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

  // widget para el texto inferior que permite cambiar de vista.
  Widget _buildBottomText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginView ? '¿No tienes una cuenta?' : '¿Ya tienes una cuenta?',
          style: const TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed: () {
            // usamos setstate para notificar a flutter que debe redibujar la pantalla.
            setState(() {
              _isLoginView = !_isLoginView; // invertimos el valor (true a false o viceversa).
            });
          },
          child: Text(_isLoginView ? 'Regístrate' : 'Inicia sesión'),
        ),
      ],
    );
  }
}