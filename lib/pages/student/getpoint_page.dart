import 'dart:developer';

import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class GetPointPage extends StatefulWidget {
  final String title;
  final String description;
  final int pointsEarned;
  final int currentPoints;

  const GetPointPage({super.key, required this.title, required this.description, required this.pointsEarned, required this.currentPoints});

  @override
  State<GetPointPage> createState() => _GetPointPageState();
}

class _GetPointPageState extends State<GetPointPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool isUpdating = true;
  Map<String, dynamic> gamificationData = {};

  @override
  void initState() {
    super.initState();
    _updatePoints();
    _updateStreak();
  }

  Future<void> _updatePoints() async {
    try {
      var studentId = _supabaseService.getCurrentUserId();
      final newTotalPoints = widget.currentPoints + widget.pointsEarned;
      log("Updating points for studentId: $studentId, newTotalPoints: $newTotalPoints");
      await _supabaseService.upsertUserPoints(studentId!, newTotalPoints);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui poin: $e")),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isUpdating = false;
    });
  }

  Future<void> _updateStreak() async {
  var studentId = _supabaseService.getCurrentUserId();
  if (studentId != null) {
   await computeGamificationData(studentId);
      
      // Ambil data streak dan tanggal dari map
      int currentStreak = gamificationData['current_streak'] ?? 0;
      var lastActiveStr = gamificationData['last_active_date'];
      
      // Parse String ke DateTime, jika null gunakan DateTime.now()
      DateTime lastActiveDate = lastActiveStr != null 
          ? DateTime.tryParse(lastActiveStr.toString()) ?? DateTime.now()
          : DateTime.now();

   await _supabaseService.upsertUserStreak(studentId, currentStreak, lastActiveDate);
  } else {
   log("User ID Not Found");
  }
 }

  Future<void> computeGamificationData(String studentId) async {
    try {
      var data = await _supabaseService.getStudentGamificationData(studentId);
      if (data != null) {
        setState(() {
          gamificationData = data;
        });
      }
    } catch (e) {
      log("Error fetching gamification data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: AppSize.screenHeight(context) * 0.15),
            const SizedBox(height: 16),
            Image.asset("assets/img/fluidy_happy.png", width: 400),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.title,
                style: fHeading1TextStyle.copyWith(color: regularBlue),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.description,
                style: fSemiBoldTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop, color: lightBlue, size: 28),
                const SizedBox(width: 8),
                const Icon(Icons.add, color: lightBlue, size: 28),
                Text("${widget.pointsEarned} pts", style: fHeading2TextStyle.copyWith(color: lightBlue, fontSize: 32)),
              ],
            ),
            const SizedBox(height: 64),
            if (!isUpdating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: FButtonWidget(
                  text: "Beranda",
                  action: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
