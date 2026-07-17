import 'dart:developer';

import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/materi_management_page.dart';
import 'package:fluidify_mobile/pages/teacher/soal_management/soal_list.dart';
import 'package:fluidify_mobile/pages/teacher/student_reports/student_list.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();

  String? displayName;
  String? avatarUrl;
  bool isLoading = true;

  int progressPercent = 0;
  int _averageLevels = 0;
  int _totalLevels = 0;
  int _totalStudents = 0;


  @override
  void initState() {
    fetchProfile();
    fetchProgressData();
    super.initState();
  }

  Future<void> fetchProgressData() async {
    // 1. Get total subchapters
    int totalSubchapters = 0;
    final chapters = await _supabaseService.getAllChapters();
    if (chapters != null) {
      for (var chapter in chapters) {
        if (chapter['subchapters'] != null) {
          totalSubchapters += (chapter['subchapters'] as List).length;
        }
      }
    }
    
    int totalLevels = totalSubchapters * 5;
    if (totalLevels == 0) {
      if (mounted) setState(() => progressPercent = 0);
      return;
    }

    // 2. Get total students
    final students = await _supabaseService.getAllStudents();
    if (students == null || students.isEmpty) {
      if (mounted) setState(() => progressPercent = 0);
      return;
    }
    int totalStudents = students.length;

    // 3. Get all student progress
    final progresses = await _supabaseService.getAllStudentProgresses();
    
    int totalStudentLevels = 0;
    for (var progress in progresses) {
      final levelsProgress = progress['levels_progress'] as Map<String, dynamic>?;
      if (levelsProgress != null) {
        for (var value in levelsProgress.values) {
          totalStudentLevels += (value as num).toInt();
        }
      }
    }

    double averageLevels = totalStudentLevels / totalStudents;
    double progressFraction = averageLevels / totalLevels;
    log("averageLevels: $averageLevels, totalLevels: $totalLevels, progressFraction: $progressFraction");
    
    if (mounted) {
      setState(() {
        _averageLevels = averageLevels.toInt();
        _totalLevels = totalLevels;
        _totalStudents = totalStudents;
        progressPercent = (progressFraction * 100).toInt().clamp(0, 100);
      });
    }
  }

  Future<void> fetchProfile() async {
    final data = await _supabaseService.getUserProfile();
    log("Data profil berhasil diambil: $data");
    if (data != null) {
      setState(() {
        displayName = data['display_name'];
        avatarUrl = data['avatar_url'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 250,
              decoration: const BoxDecoration(
                color: regularBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),

            // 2. Konten Utama
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: Sapaan & Avatar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat pagi,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$displayName!',
                              style: fBoldTextStyle.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                          child: avatarUrl == null || avatarUrl!.isEmpty ? const Icon(Icons.person, size: 25, color: Colors.grey) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // --- Kartu Progress Pembelajaran ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                             Text(
                                'Progress Pembelajaran',
                                style: fBoldTextStyle.copyWith(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Siswa: $_totalStudents',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rata-rata Penyelesaian : $_averageLevels level/$_totalLevels total level',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Custom Progress Bar menggunakan Expanded [cite: 9]
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 12,
                                    color: const Color(0xFFE5E7EB), // Background track
                                    child: Row(
                                      children: [
                                        if (progressPercent > 0)
                                          Expanded(
                                            flex: progressPercent, // Persentase Progress
                                            child: Container(
                                              color: const Color(0xFFF59E0B),
                                            ),
                                          ),
                                        if (100 - progressPercent > 0)
                                          Expanded(
                                            flex: 100 - progressPercent, // Sisa bar kosong
                                            child: const SizedBox(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$progressPercent%',
                                style: fBoldTextStyle.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Grid Tombol Menu ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMenuButton(icon: Icons.book, label: 'Kelola Materi', iconColor: regularBlue, onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MateriManagementPage(),
                                ),
                              );
                            }),
                        _buildMenuButton(icon: Icons.edit_document, label: 'Kelola Soal', iconColor: regularBlue, onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SoalListPage(),
                                ),
                              );
                            }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _buildMenuButton(icon: Icons.insert_chart, label: 'Laporan Siswa', iconColor: regularBlue, onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudentListPage(),
                                ),
                              );
                      })
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required Color iconColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 145,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 54,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: fBoldTextStyle.copyWith(fontSize: 14, color: regularBlue),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
