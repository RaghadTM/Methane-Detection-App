import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MethaneGuardApp());
}

class MethaneGuardApp extends StatelessWidget {
  const MethaneGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF08111D),
      ),
      home: const HomePage(),
    );
  }
}