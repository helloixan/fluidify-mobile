import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/chapter_form.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class MateriManagementPage extends StatefulWidget {
  const MateriManagementPage({super.key});

  @override
  State<MateriManagementPage> createState() => _MateriManagementPageState();
}

class _MateriManagementPageState extends State<MateriManagementPage> {
  SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _chapterTitleController = TextEditingController();
  final TextEditingController _chapterSequenceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> chapters = [];
  List<Map<String, dynamic>> filteredChapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    computeChapters();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> computeChapters() async {
    var data = await _supabaseService.getAllChapters();
    if (data != null) {
      setState(() {
        chapters = data;
        _filterChapters(_searchController.text);
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void _filterChapters(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredChapters = List.from(chapters);
      });
    } else {
      setState(() {
        filteredChapters = chapters.where((chapter) {
          final title = chapter['chapter_title']?.toString().toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _addChapter() async {
    try {
      if (_chapterTitleController.text.trim().isNotEmpty && _chapterSequenceController.text.trim().isNotEmpty) {
        int chapterSequence = int.parse(_chapterSequenceController.text);
        await _supabaseService.insertChapter(_chapterTitleController.text, chapterSequence);
        await computeChapters();
        setState(() {
          _chapterTitleController.clear();
          _chapterSequenceController.clear();
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Chapter ${_chapterTitleController.text} berhasil ditambahkan", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: softGreen));
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Judul chapter tidak boleh kosong", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: warningColor));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception', 'Gagal Menambahkan Chapter')), backgroundColor: dangerColor));
      }
    }
  }

  void _showCreateChapterForm() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: appBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Chapter Baru', style: fBoldTextStyle),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _chapterTitleController,
                  cursorColor: regularBlue,
                  decoration: const InputDecoration(
                    labelText: 'Judul Chapter',
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _chapterSequenceController,
                  cursorColor: regularBlue,
                  decoration: const InputDecoration(
                    labelText: 'Urutan Chapter',
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FButtonWidget(text: "Simpan", action: () => _addChapter()),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Kelola Materi",
          style: fBoldTextStyle.copyWith(color: regularBlue),
        ),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 10, right: 10),
            child: FluidywithBubble(maskotPath: 'assets/img/fluidy_reading.png', text: 'Berikut adalah daftar chapter yang ada saat ini', maskotSize: 60,),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterChapters,
              decoration: InputDecoration(
                hintText: "Cari judul chapter...",
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: 0),
                      itemCount: filteredChapters.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var chapter = filteredChapters[index];
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                                color: Colors.white,
                                child: ListTile(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChapterFormPage(chapterId: chapter['chapter_id']),
                                      ),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      await computeChapters();
                                    }
                                  },
                                  leading: Text(chapter['chapter_sequence'].toString(), style: fHeading1TextStyle.copyWith(color: regularBlue)),
                                  title: Text(chapter['chapter_title'], style: fBoldTextStyle,),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text("Terdapat ${chapter['subchapters'].length} subchapter"),
                                      Text("Dibuat oleh: ${chapter['chapter_author_name']}"),
                                    ],
                                  ),
                                )));
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: regularBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 30),
                        onPressed: () => _showCreateChapterForm(),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
