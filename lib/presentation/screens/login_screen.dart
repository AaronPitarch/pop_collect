import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pop_collect/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {

  //Controladores de los campo de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; //Instancia de Firebase Auth



  //Funcion para manejar el inicio de sesion
  Future<void> _handleLogin() async{
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim(),
      );
      //si el inicio de sesion es exitoso, navega a la pantalla principal
      Fluttertoast.showToast(msg: 'Inicio de sesion exitoso');
      _navigateToHomeScreen();
    } on FirebaseAuthException catch (e) {
      //Manejo de errores 
      _showErrorToast(e.code);
    }
  }

  //Funcion para manegar el registro
  Future<void> _handleRegister() async{
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      //si el registro es exitoso, navega a la pantalla principal
      Fluttertoast.showToast(msg: 'Registro exitoso');
      _navigateToHomeScreen();
    } on FirebaseAuthException catch (e) {
      _showErrorToast(e.code);
    }
  }

  //Funcion para mostrar mensajes de error
  void _showErrorToast(String errorCode) {
    String errorMessage;
    switch (errorCode) {
      case 'invalid-email':
        errorMessage = 'El correo electronico no es valido';
        break;
      case 'user-not-found':
        errorMessage = 'No se encontro un usuario con ese correo';
        break;
      case 'wrong-password':
        errorMessage = 'Contraseña incorrecta';
        break;
      case 'email-already-in-use':
        errorMessage = 'El correo ya esta registrado';
        break;
      case 'weak-password':
        errorMessage = 'La contraseña es demasiado debil';
        break;
      default:
        errorMessage = 'Ha ocurrido un error. Intentelo de nuevo';
    }
    Fluttertoast.showToast(msg: errorMessage);
  }

  //Navegar a la pantalla principal (ajustar el flujo de navegacion)
  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //campo de texto para el correo 
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            //Campo de texto para la contraseña
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            //Boton de iniciar sesion
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Iniciar sesion'),
            ),
            const SizedBox(height: 8),
            //Boton de registrar
            OutlinedButton(
              onPressed: _handleRegister, 
              child: const Text('Registrar'),
            )
          ],
        ),
      ),
    );
  }
}