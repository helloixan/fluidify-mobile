import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/subchapter_form_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class ChapterFormPage extends StatefulWidget {
  final String chapterId;
  const ChapterFormPage({super.key, required this.chapterId});

  @override
  State<ChapterFormPage> createState() => _ChapterFormPageState();
}

class _ChapterFormPageState extends State<ChapterFormPage> {
  final SupabaseService _supabaseService = SupabaseService();
  // ignore: prefer_final_fields
  TextEditingController _chapterTitleController = TextEditingController();
  TextEditingController _chapterSequenceController = TextEditingController();
  TextEditingController _subchapterTitleController = TextEditingController();
  TextEditingController _sequenceOrderController = TextEditingController();
  Map<String, dynamic>? _chapter;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getChapter();
  }

  Future<void> _getChapter() async {
    try {
      var chapterResponse = await _supabaseService.getChapterById(widget.chapterId);
      if (chapterResponse != null) {
        setState(() {
          _chapter = chapterResponse;
        });
        computeLevels();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: dangerColor));
      }
    }
  }

  void computeLevels() {
    if (_chapter!['subchapters'] != null) {
      for (var subchapter in _chapter!['subchapters']) {
        setState(() {
          subchapter["levels"] = [
            {"icon": Icons.play_arrow_rounded, "name": "Video Simulasi"},
            {"icon": Icons.search_rounded, "name": "Eksplorasi Materi"},
            {"icon": Icons.edit_rounded, "name": "Concept Map"},
            {"icon": Icons.lightbulb, "name": "Feedback"},
            {"icon": Icons.question_mark_rounded, "name": "Quiz"},
          ];
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _deleteChapter() async {
    try {
      await _supabaseService.deleteChapter(widget.chapterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data chapter ini berhasil dihapus", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: dangerColor));
      }
    }
  }

  Future<void> _editChapter() async {
    try {
      if (_chapterTitleController.text.trim().isNotEmpty && _chapterSequenceController.text.trim().isNotEmpty) {
        int sequenceOrder = int.parse(_chapterSequenceController.text);
        await _supabaseService.updateChapterData(widget.chapterId, _chapterTitleController.text, sequenceOrder);
        await _getChapter();
        if (mounted) {
          setState(() {
            _chapterTitleController.clear();
            _chapterSequenceController.clear();
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data chapter ini berhasil diubah", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen));
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Judul chapter dan urutan chapter tidak boleh kosong", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: warningColor));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception', 'Gagal Mengubah Data Chapter')), backgroundColor: dangerColor));
      }
    }
  }

  void _showDialogDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FConfirmationDialog(
            content: 'Seluruh subchapter yang ada pada chapter ini akan ikut dihapus, Apakah anda yakin ingin menghapus chapter ${_chapter!['chapter_title']}?',
            action: () async {
              await _deleteChapter();
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
      },
    );
  }

  void _showEditDialog() {
    _chapterTitleController.text = _chapter!['chapter_title'] ?? "Judul Baru";
    _chapterSequenceController.text = _chapter!['chapter_sequence'].toString();
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
                Text('Edit Chapter', style: fBoldTextStyle),
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
                FButtonWidget(text: "Simpan", action: () => _editChapter()),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
  }

  Future<void> _addSubChapter() async {
    try {
      if (_subchapterTitleController.text.trim().isNotEmpty && _sequenceOrderController.text.trim().isNotEmpty) {
        int sequenceOrder = int.parse(_sequenceOrderController.text);
        await _supabaseService.insertSubchapter(widget.chapterId, _subchapterTitleController.text, sequenceOrder);
        await _getChapter();
        setState(() {
          _subchapterTitleController.clear();
          _sequenceOrderController.clear();
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Chapter ${_subchapterTitleController.text} berhasil ditambahkan", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception', 'Gagal menambahkan subchapter')), backgroundColor: dangerColor));
      }
    }
  }

  void _showCreateSubchapterForm() {
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
                Text('Tambah Subchapter Baru', style: fBoldTextStyle),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subchapterTitleController,
                  cursorColor: regularBlue,
                  decoration: const InputDecoration(
                    labelText: 'Judul Subchapter',
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _sequenceOrderController,
                  cursorColor: regularBlue,
                  decoration: const InputDecoration(
                    labelText: 'Urutan Subchapter pada Chapter',
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: regularBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FButtonWidget(text: "Simpan", action: () => _addSubChapter()),
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
          "Kelola Chapter",
          style: fBoldTextStyle.copyWith(color: regularBlue),
        ),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.book, color: regularBlue, size: 100),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Urutan Chapter: ${_chapter!['chapter_sequence']}"),
                              Text("Judul Chapter: ${_chapter!['chapter_title']}"),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: 150, child: FButtonWidget(text: "Edit", action: () => _showEditDialog(), icon: Icons.edit, color: regularBlue)),
                          SizedBox(width: 150, child: FButtonWidget(text: "Hapus", action: () => _showDialogDeleteConfirmation(), color: dangerColor, icon: Icons.delete)),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Text("Subchapter List", style: fHeading2TextStyle.copyWith(color: regularBlue)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _chapter!['subchapters'].length,
                            itemBuilder: (context, index) {
                              var subchapter = _chapter!['subchapters'][index];
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                      color: Colors.white,
                                      child: ListTile(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SubchapterFormPage(subchapter_id: subchapter['subchapter_id']),
                                            ),
                                          );
                                          if (mounted) {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            await _getChapter();
                                          }
                                        },
                                        leading: Text(subchapter['subchapter_order'].toString(), style: fHeading1TextStyle.copyWith(color: regularBlue)),
                                        title: Text(subchapter['subchapter_title']),
                                      )));
                            }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10.0),
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
                              onPressed: () => _showCreateSubchapterForm(),
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
