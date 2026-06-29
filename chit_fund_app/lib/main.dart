import 'screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ChitFundApp());
}

class ChitFundApp extends StatelessWidget {
  const ChitFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chit Fund Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

