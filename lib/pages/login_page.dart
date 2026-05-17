import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: warningColor,
            content: Text('Username dan password tidak boleh kosong!',
                style: fMediumTextStyle.copyWith(color: Colors.white))),
      );
      return;
    }

    try {
      await authService.signInWithEmailPassword(email, password);

      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      String pesanError = 'Terjadi kesalahan pada sistem.';

      if (e.message.toLowerCase().contains('invalid login credentials')) {
        pesanError = 'Username atau password yang kamu masukkan salah.';
      } else if (e.message.toLowerCase().contains('rate limit') ||
          e.statusCode == 429) {
        pesanError = 'Terlalu banyak percobaan. Tunggu beberapa saat dan coba lagi.';
      } else {
        pesanError = "error: ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            pesanError,
            style: fMediumTextStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: dangerColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 100, left: 40, right: 40),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text("Welcome!", style: fHeading1TextStyle)),
                const Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 40),
                  child: Image(image: AssetImage("assets/img/fluidy_login.png")),
                ),
                Text(
                  "Username",
                  style: fMediumTextStyle.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hint: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        const Text("Username"),
                      ],
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Password",
                  style: fMediumTextStyle.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hint: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        const Text("Password"),
                      ],
                    ),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400])),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {},
                        child: Text("Lupa Password?",
                            style:
                                fMediumTextStyle.copyWith(color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    login();
                    // Navigator.of(context).pushReplacement(MaterialPageRoute(
                    //     builder: (_) => const StudentMainWrapper()));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: regularBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text("Login",
                      style: fMediumTextStyle.copyWith(color: Colors.white)),
                )
              ],
            ),
          ),
        ));
  }
}
