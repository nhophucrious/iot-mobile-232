import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hcmut_iot/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'HCMUT IoT',
        theme: ThemeData(
          textTheme: GoogleFonts.nunitoSansTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
        ),
        home: const HomeScreen());
  }
}
