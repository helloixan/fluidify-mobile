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

  @override
  void initState() {
    fetchProfile();
    super.initState();
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
                          const Text(
                            'Progress Pembelajaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pekan 8/16',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Custom Progress Bar menggunakan Expanded [cite: 9]
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 12,
                              color: const Color(0xFFE5E7EB), // Background track
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 50, // Persentase Progress (50%) [cite: 9]
                                    child: Container(
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 50, // Sisa bar kosong [cite: 9]
                                    child: SizedBox(),
                                  ),
                                ],
                              ),
                            ),
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
