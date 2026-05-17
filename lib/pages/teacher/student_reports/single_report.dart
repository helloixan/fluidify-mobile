import 'dart:developer';

import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SingleStudentReportPage extends StatefulWidget {
  final String studentId;
  const SingleStudentReportPage({super.key, required this.studentId});

  @override
  State<SingleStudentReportPage> createState() => _SingleStudentReportPageState();
}

class _SingleStudentReportPageState extends State<SingleStudentReportPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Map<String, dynamic> _student = {};
  Map<String, dynamic> _studentProgress = {};
  Map<String, dynamic> _studentGamification = {};

  @override
  void initState() {
    super.initState();
    _fetchStudent();
  }

  Future<void> _fetchStudent() async {
    try {
      final studentProgress = await _supabaseService.getStudentProgress(widget.studentId);
      final studentGamification = await _supabaseService.getStudentGamificationData(widget.studentId);
      final student = await _supabaseService.getProfileById(widget.studentId);
      if (student != null) {
        setState(() {
          _student = student;
          if (studentProgress != null) _studentProgress = studentProgress;
          if (studentGamification != null) _studentGamification = studentGamification;
        });
      }
    } catch (e) {
      log('Error fetching student: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color color = regularBlue}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: fBoldTextStyle.copyWith(fontSize: 12, color: Colors.grey)),
            Text(value, style: fBoldTextStyle.copyWith(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Laporan Siswa",
            style: fBoldTextStyle.copyWith(color: regularBlue),
          ),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: regularBlue))
            : _student.isEmpty ? const Center(child: Text("Gagal memuat data siswa"))
            : Padding(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start, 
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.black.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(_student['avatar_url'] ?? dummyAvatarUrl),
                            backgroundColor: appBackgroundColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nama Lengkap", style: fBoldTextStyle.copyWith(color: Colors.black)),
                            Text(
                              "${_student['display_name']}",
                              style: fMediumTextStyle.copyWith(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            Text("Kelas", style: fBoldTextStyle.copyWith(color: Colors.black)),
                            Text(
                              "${_student['classes']?['class_name'] ?? '-'}",
                              style: fMediumTextStyle.copyWith(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ])
                      ]),
                    ),
                  ),
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.black.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text("Progress Belajar", style: fHeading2TextStyle.copyWith(color: Colors.black)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // column kiri
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatItem(Icons.menu_book, "Chapter Selesai", "${_studentProgress['chapter_done'] ?? 0}"),
                                    const SizedBox(height: 15),
                                    _buildStatItem(Icons.bookmark_added, "Subchapter Selesai", "${_studentProgress['subchapter_done'] ?? 0}"),
                                    const SizedBox(height: 15),
                                    _buildStatItem(Icons.calendar_month, "Terakhir Aktif", "${_studentGamification['last_active_date'] ?? '-'}"),

                                  ]
                                ),
                              ),
                              // column kanan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatItem(Icons.water_drop, "Total Poin", "${_studentGamification['total_points'] ?? 0}", color: regularBlue),
                                    const SizedBox(height: 15),
                                    _buildStatItem(streakIcon, "Current Streak", "${_studentGamification['current_streak'] ?? 0} Hari", color: darkOrange),
                                    const SizedBox(height: 15),
                                    _buildStatItem(Icons.emoji_events, "Level Selesai", "${_studentGamification['levels_done'] ?? 0}", color: softGray),
                                  ]
                                ),
                              ),
                            ]
                          ),
                        ],
                      ),
                    ),
                  )
                ]),
            ));
  }
}
