import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/onboarding_page.dart';
import 'package:fluidify_mobile/pages/student/student_main.dart';
import 'package:fluidify_mobile/pages/teacher/teacher_main.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseService _supabaseService = SupabaseService();
    return StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: appBackgroundColor,
              body: Center(
                child: CircularProgressIndicator(color: regularBlue),
              ),
            );
          }

          // kalo udh login
          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) {
            return FutureBuilder<String?>(
              future: _supabaseService.getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: appBackgroundColor,
                    body: Center(
                      child: CircularProgressIndicator(color: regularBlue),
                    ),
                  );
                }

                if (roleSnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: appBackgroundColor,
                    body: Center(
                      child: Text('Terjadi kesalahan saat memuat data: ${roleSnapshot.error}'),
                    ),
                  );
                }

                final role = roleSnapshot.data;
                if (role == 'student') {
                  return const StudentMainWrapper();
                } else if (role == 'teacher') {
                  return const TeacherMainWrapper();
                } else {
                  return const Scaffold(
                    backgroundColor: appBackgroundColor,
                    body: Center(
                      child: Text('Akses ditolak: Role tidak valid atau tidak ditemukan.'),
                    ),
                  );
                }
              },
            );
          } else {
            return const OnboardingPage();
          }
        });
  }
}
