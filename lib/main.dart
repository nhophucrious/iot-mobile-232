import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hcmut_iot/screens/home_screen.dart';
import 'package:hcmut_iot/screens/welcome_screen.dart';
import 'package:hcmut_iot/repository/user_defaults_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var username = await UserDefaultsRepository.getUsername();
  var key = await UserDefaultsRepository.getKey();
  runApp(MyApp(initialRoute: (username != null && key != null) ? '/' : '/welcome'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCMUT IoT',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const HomeScreen(),
        '/welcome': (context) => WelcomeScreen(),
      },
    );
  }
}
