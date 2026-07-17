import 'package:fluidify_mobile/components/teacher_navbar.dart';
import 'package:fluidify_mobile/pages/student/leaderboard_page.dart';
import 'package:fluidify_mobile/pages/profilepage.dart';
import 'package:fluidify_mobile/pages/teacher/teacher_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class TeacherMainWrapper extends StatefulWidget {
  const TeacherMainWrapper({super.key});

  @override
  State<TeacherMainWrapper> createState() => _TeacherMainWrapperState();
}

class _TeacherMainWrapperState extends State<TeacherMainWrapper> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const StudentLeaderBoardPage(),
    const TeacherDashboardPage(),
    const UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // _initializeGemini();
  }

  // Future<void> _initializeGemini() async {
  //   final apiKey = await SupabaseService().getGeminiApiKey();
  //   if (apiKey != null && apiKey.isNotEmpty) {
  //     Gemini.init(apiKey: apiKey);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: TeacherNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
