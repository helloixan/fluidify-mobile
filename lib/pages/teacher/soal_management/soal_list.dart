import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/quiz_form.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class SoalListPage extends StatefulWidget {
  const SoalListPage({super.key});

  @override
  State<SoalListPage> createState() => _SoalListPageState();
}

class _SoalListPageState extends State<SoalListPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _latihanSoalData = [];
  List<Map<String, dynamic>> _filteredLatihanSoalData = [];
  bool _isLoading = true;
  String _currentUserId = "";

  @override
  void initState() {
    super.initState();
    _fetchSoalList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSoalList() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _supabaseService.getAllQuizbyType("latihan_soal");
    final userId = await _supabaseService.getCurrentUserId();
    if (userId != null) {
      setState(() {
        _latihanSoalData = data;
        _currentUserId = userId;
        _filterSoal(_searchController.text);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSoal(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLatihanSoalData = List.from(_latihanSoalData);
      });
    } else {
      setState(() {
        _filteredLatihanSoalData = _latihanSoalData.where((soal) {
          final title = soal['title']?.toString().toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _deleteLatihanSoal(int index) {
    showDialog(
        context: context,
        builder: (context) => FConfirmationDialog(
              content: "Yakin ingin menghapus latihan soal ini?",
              action: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });
                try {
                  final quiz = _filteredLatihanSoalData[index];
                  await _supabaseService.deleteQuizById(quiz['id'].toString(), "latihan_soal");
                  await _fetchSoalList();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menghapus Latihan Soal!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                  }
                  setState(() => _isLoading = false);
                }
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBackgroundColor,
        title: Text(
          "Latihan Soal",
          style: fBoldTextStyle.copyWith(color: regularBlue),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: FluidywithBubble(
                    text: "Berikut adalah daftar latihan soal yang tersedia saat ini",
                    maskotPath: "assets/img/onboarding/fluidy_writing.png",
                    maskotSize: 65,
                    position: Bubbletail.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSoal,
                    decoration: InputDecoration(
                      hintText: "Cari judul latihan soal...",
                      prefixIcon: const Icon(Icons.search, color: regularBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: regularBlue),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: _filteredLatihanSoalData.length,
                      itemBuilder: (context, index) {
                        var soal = _filteredLatihanSoalData[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
                          child: Card(
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
                            trailing: _currentUserId == soal['created_by']
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                                    onPressed: () => _deleteLatihanSoal(index),
                                  )
                                : const SizedBox(
                                    width: 30,
                                    height: 30,
                                  ),
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizForm(subChapterId: soal['subchapter_id'], type: 'latihan_soal', isAuthor: _currentUserId == soal['created_by']),
                                ),
                              );
                              if (mounted) {
                                await _fetchSoalList();
                              }
                            },
                          ),
                        ),
                        );
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: AppSize.screenWidth(context) * 0.9,
                      child: FButtonWidget(
                        text: "Tambah Latihan Soal",
                        action: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const QuizForm(
                                      subChapterId: "",
                                      type: "latihan_soal",
                                      isAuthor: true)));
                          if (mounted) {
                            await _fetchSoalList();
                          }
                        },
                        icon: Icons.add,
                      )),
                ),
              ],
            ),
    );
  }
}
