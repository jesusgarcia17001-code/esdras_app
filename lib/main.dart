import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'services/iglesia_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esdra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                    color: Colors.white),
              ),
            );
          }
          if (snapshot.hasData) {
            return FutureBuilder(
              future: IglesiaService().getUsuario(),
              builder: (context, userSnap) {
                if (userSnap.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                          color: Colors.white),
                    ),
                  );
                }
                final usuario = userSnap.data;
                if (usuario?.iglesiaId == null) {
                  return SetupScreen();
                }
                return const HomeScreen();
              },
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}