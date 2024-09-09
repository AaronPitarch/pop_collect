import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pop_collect/data/providers/app_provider.dart';
import 'package:pop_collect/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PopCollect());
}

class PopCollect extends StatelessWidget {
  const PopCollect({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pop Collect',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginScreen(), //Inicia la app con la pantalla de login
      ),
    );
  }
}

