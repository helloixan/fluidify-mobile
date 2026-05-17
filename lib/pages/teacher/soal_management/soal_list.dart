import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
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

  List<Map<String, dynamic>> _latihanSoalData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSoalList();
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
                  final quiz = _latihanSoalData[index];
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
                const FluidywithBubble(
                  text: "Berikut adalah daftar latihan soal yang tersedia saat ini",
                  maskotPath: "assets/img/onboarding/fluidy_writing.png",
                  maskotSize: 100,
                  position: Bubbletail.right,
                ),
                const SizedBox(height: 20),
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: _latihanSoalData.length,
                    itemBuilder: (context, index) {
                      var soal = _latihanSoalData[index];
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                              onPressed: () => _deleteLatihanSoal(index),
                            ),
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizForm(subChapterId: soal['subchapter_id'], type: 'latihan_soal'),
                                ),
                              );
                              if (mounted) {
                                await _fetchSoalList();
                              }
                            },
                          ),
                        ),
                      );
                    })
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizForm(subChapterId: "", type: "latihan_soal")));
          if (mounted) {
            await _fetchSoalList();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah Latihan Soal"),
        backgroundColor: regularBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
