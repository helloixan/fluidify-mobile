import 'package:fluidify_mobile/components/toggle_switch.dart';
import 'package:fluidify_mobile/components/top_student.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class StudentLeaderBoardPage extends StatefulWidget {
  const StudentLeaderBoardPage({super.key});

  @override
  State<StudentLeaderBoardPage> createState() => _StudentLeaderBoardPageState();
}

class _StudentLeaderBoardPageState extends State<StudentLeaderBoardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLeaderboardTab = true;

  List<Map<String, dynamic>> _leaderboardData = [];
  Map<String, dynamic> _currentUserData = {};
  int _currentUserRank = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _supabaseService.getAllStudentsGamification();

    if (data.isNotEmpty) {
      setState(() {
        _leaderboardData = data;
        _isLoading = false;
      });

      var userId = _supabaseService.getCurrentUserId();
      if (userId != null) {
        for (var student in _leaderboardData) {
          if (student['user_id'] == userId) {
            setState(() {
              _currentUserData = student;
              _currentUserRank = _leaderboardData.indexOf(student) + 1;
            });
            break;
          }
        }
      }
    }
  }

  // --- Fungsi Baru: Menyingkat Nama Belakang ---
  String _formatName(String name) {
    if (name.trim().isEmpty) return name;

    // Pecah nama berdasarkan spasi
    List<String> words = name.trim().split(' ');
    // Hapus elemen kosong (berjaga-jaga jika ada spasi ganda)
    words = words.where((w) => w.isNotEmpty).toList();

    // Jika hanya 1 kata, kembalikan apa adanya
    if (words.length <= 1) return name.trim();

    // Ambil kata pertama secara utuh
    String formattedName = words.first;

    // Looping sisa kata, ambil huruf pertamanya, jadikan kapital, dan tambah titik
    for (int i = 1; i < words.length; i++) {
      formattedName += " ${words[i][0].toUpperCase()}.";
    }

    return formattedName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 50),
          if (_currentUserData.isNotEmpty)
            Center(
              child: FluidifyToggleSwitch(
                  leftText: "Leaderboard",
                  rightText: "Streak",
                  onChanged: (bool isLeftSelected) {
                    setState(() {
                      _isLeaderboardTab = isLeftSelected;
                    });
                  }),
            ),
          if (_currentUserData.isNotEmpty) const SizedBox(height: 20),
          Expanded(
            child: _isLeaderboardTab || _currentUserData.isEmpty ? _buildLeaderboardView() : _buildStreakView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_leaderboardData.isEmpty) {
      return const Center(child: Text("Belum ada data leaderboard."));
    }

    final rank1 = _leaderboardData.isNotEmpty ? _leaderboardData[0] : null;
    final rank2 = _leaderboardData.length > 1 ? _leaderboardData[1] : null;
    final rank3 = _leaderboardData.length > 2 ? _leaderboardData[2] : null;

    List<Map<String, dynamic>> remainingStudents = [];
    if (_leaderboardData.length > 3) {
      remainingStudents = _leaderboardData.sublist(3);
    }

    return Column(
      children: [
        Text("Top Siswa", style: fBoldTextStyle.copyWith(fontSize: 20)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Rank 2 (Kiri)
            if (rank2 != null)
              TopStudentProfile(
                name: _formatName(rank2['name'] ?? "Siswa"),
                rank: 2,
                avatarUrl: rank2['avatar_url'] ?? "",
                points: rank2['total_points'] ?? 0,
              ),
            if (rank2 != null) const SizedBox(width: 40),

            // Rank 1 (Tengah)
            if (rank1 != null) TopStudentProfile(name: _formatName(rank1['name'] ?? "Siswa"), rank: 1, avatarUrl: rank1['avatar_url'] ?? "", points: rank1['total_points'] ?? 0),
            if (rank3 != null) const SizedBox(width: 40),

            // Rank 3 (Kanan)
            if (rank3 != null) TopStudentProfile(name: _formatName(rank3['name'] ?? "Siswa"), rank: 3, avatarUrl: rank3['avatar_url'] ?? "", points: rank3['total_points'] ?? 0),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 5),
              itemCount: remainingStudents.length,
              itemBuilder: (context, index) {
                final student = remainingStudents[index];
                final rank = index + 4;

                final rawName = student['name'] ?? "Siswa Tanpa Nama";
                // Terapkan fungsi format nama di sini
                final displayName = _formatName(rawName);

                final points = student['total_points'] ?? 0;

                return Column(
                  children: [
                    ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          "$rank",
                          style: fHeading1TextStyle.copyWith(color: darkBlue),
                        ),
                      ),
                      title: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(student['avatar_url'] ?? dummyAvatarUrl),
                            backgroundColor: appBackgroundColor,
                          ),
                          const SizedBox(width: 20),
                          Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Text(
                        "$points pts",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Divider(height: 1, color: Colors.blueGrey),
                    const SizedBox(height: 5),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: AppSize.screenHeight(context) * 0.1),
          Icon(
            streakIcon,
            size: 150,
            color: darkOrange,
            shadows: [
              Shadow(
                color: Colors.yellow[300]!,
                blurRadius: 80,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          Text("${_currentUserData['current_streak']}", style: fExtraBoldTextStyle.copyWith(fontSize: 48, color: darkOrange)),
          const Text("Hari Streak!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Text("Belajar setiap hari untuk pertahankan api semangat belajar kamu!", style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, color: lightBlue),
              const SizedBox(width: 8),
              Text("${_currentUserData['total_points']} pts", style: fMediumTextStyle.copyWith(color: lightBlue, fontSize: 21)),
              const SizedBox(width: 30),
              const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
              const SizedBox(width: 5),
              Text("Peringkat ke-$_currentUserRank", style: fMediumTextStyle.copyWith(color: Colors.black, fontSize: 21)),
            ],
          )
        ],
      ),
    );
  }
}
