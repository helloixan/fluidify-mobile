import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  // setup supabase
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_API_KEY,
  );

  //setup gemini
  Gemini.init(apiKey: GEMINI_API_KEY);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SplashScreen());
  }
}
