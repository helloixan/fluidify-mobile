import 'dart:developer';

import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/quiz_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class LatihanSoalPage extends StatefulWidget {
  const LatihanSoalPage({super.key});

  @override
  State<LatihanSoalPage> createState() => _LatihanSoalPageState();
}

class _LatihanSoalPageState extends State<LatihanSoalPage> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _latihanSoalData = [];
  bool _isLoading = true;
  int _userCurrentPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchSoalList();
    _fetchUserCurrentPoints();
  }

  Future<void> _fetchSoalList() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _supabaseService.getAllQuizbyType("latihan_soal");

    if (data.isNotEmpty) {
      setState(() {
        _latihanSoalData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserCurrentPoints() async {
    var studentId = _supabaseService.getCurrentUserId();
    if (studentId != null) {
      var data = await _supabaseService.getStudentGamificationData(studentId);
      if (data != null) {
        setState(() {
          _userCurrentPoints = data['total_points'];
        });
      }
    } else {
      log("User ID Not Found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBackgroundColor,
        title: Center(
          child: Text(
            "Latihan Soal",
            style: fHeading1TextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      backgroundColor: appBackgroundColor,
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: regularBlue))
      : Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const FluidywithBubble(
            text: "Guru akan memberikan kamu soal latihan tambahan disini",
            maskotPath: "assets/img/onboarding/fluidy_writing.png",
            maskotSize: 100,
            position: Bubbletail.right,
          ),
          const SizedBox(height: 50),
          ListView.builder(
              shrinkWrap: true,
              itemCount: _latihanSoalData.length,
              itemBuilder: (context, index) {
                var soal = _latihanSoalData[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(
                      Icons.assignment_rounded,
                      color: darkOrange,
                      size: 35,
                    ),
                    title: Text(
                      soal["title"],
                      style: fHeading3TextStyle,
                    ),
                    subtitle: Text("dibuat oleh ${soal['creator_name']}", style: fMediumTextStyle),
                    onTap: () async {
                       Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizPage(subChapterId: soal['subchapter_id'], currentPoints: _userCurrentPoints, type: 'latihan_soal'),
                              ),
                            );
                    },
                  ),
                );
              })
        ],
      ),
    );
  }
}
