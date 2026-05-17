import 'package:fluidify_mobile/components/teacher_navbar.dart';
import 'package:fluidify_mobile/pages/student/leaderboard_page.dart';
import 'package:fluidify_mobile/pages/profilepage.dart';
import 'package:fluidify_mobile/pages/teacher/teacher_dashboard.dart';
import 'package:flutter/material.dart';

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
