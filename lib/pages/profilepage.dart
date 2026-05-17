import 'dart:developer';

import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final authService = SupabaseService();

  String? displayName;
  String? kelas;
  String? avatarUrl;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    fetchProfile();
    super.initState();
  }

  Future<void> fetchProfile() async {
    final data = await authService.getUserProfile();
    log("Data profil berhasil diambil: $data");
    if (data != null) {
      log("tes123");
      setState(() {
        displayName = data['display_name'];
        kelas = data['classes']?['class_name'];
        avatarUrl = data['avatar_url'];
        role = data['role'];
        isLoading = false;
      });
    }
  }

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();
    final List<Map<String, dynamic>> buttonOptions = [
      {"icon": Icons.notifications_rounded, "title": "Notifikasi", "color": Colors.grey, "onTap": () {}},
      {"icon": Icons.help, "title": "Bantuan", "color": Colors.grey, "onTap": () {}},
      {
        "icon": Icons.logout,
        "title": "Keluar",
        "color": Colors.red,
        "onTap": () {
          logout();
        },
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: regularBlue,
            ))
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: regularBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Text("Profil", style: fHeading1TextStyle.copyWith(color: Colors.white)),
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                          child: avatarUrl == null || avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                        ),
                        const SizedBox(height: 20),
                        Text(displayName ?? "Unknown Student", style: fHeading1TextStyle.copyWith(color: Colors.white)),
                        const SizedBox(height: 5),
                        Text(currentEmail.toString(), style: fMediumTextStyle.copyWith(color: Colors.white)),
                        const SizedBox(height: 10),
                        if (role == 'student') Text((kelas == null || kelas!.trim().isEmpty) ? "Belum ada kelas" : kelas!, style: fSemiBoldTextStyle.copyWith(color: Colors.white)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: buttonOptions.length,
                    itemBuilder: (context, index) {
                      final option = buttonOptions[index];
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: Icon(option["icon"], color: option["color"]),
                          title: Text(option["title"]),
                          onTap: option["onTap"],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
