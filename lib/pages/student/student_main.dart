import 'package:fluidify_mobile/pages/student/homepage.dart';
import 'package:fluidify_mobile/pages/student/latihansoal_page.dart';
import 'package:fluidify_mobile/pages/student/leaderboard_page.dart';
import 'package:fluidify_mobile/pages/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:fluidify_mobile/components/navbar.dart';

class StudentMainWrapper extends StatefulWidget {
  const StudentMainWrapper({super.key});

  @override
  State<StudentMainWrapper> createState() => _StudentMainWrapperState();
}

class _StudentMainWrapperState extends State<StudentMainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StudentHomePage(),
    const LatihanSoalPage(),
    const StudentLeaderBoardPage(),
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],

      bottomNavigationBar: CustomBottomNavBar(
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
