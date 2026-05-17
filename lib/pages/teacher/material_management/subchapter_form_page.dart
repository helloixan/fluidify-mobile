import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/exploration_form.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/conceptmap_form.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/feedback_form.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/video_form.dart';
import 'package:fluidify_mobile/pages/teacher/material_management/quiz_form.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class SubchapterFormPage extends StatefulWidget {
  final String subchapter_id;
  const SubchapterFormPage({super.key, required this.subchapter_id});

  @override
  State<SubchapterFormPage> createState() => _SubchapterFormPageState();
}

class _SubchapterFormPageState extends State<SubchapterFormPage> {
  SupabaseService _supabaseService = SupabaseService();
  TextEditingController _subchapterTitleController = TextEditingController();
  TextEditingController _sequenceOrderController = TextEditingController();
  Map<String, dynamic>? _subchapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getSubchapter();
  }

  Future<void> _getSubchapter() async {
    try {
      var subchapterResponse = await _supabaseService.getSubchapterById(widget.subchapter_id);
      if (subchapterResponse != null) {
        setState(() {
          _subchapter = subchapterResponse;
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
    if (_subchapter != null) {
      setState(() {
        _subchapter!["levels"] = [
          {"icon": Icons.play_arrow_rounded, "name": "Video Simulasi", "navigateTo": VideoFormPage(subchapterId: _subchapter!['id'].toString())},
          {"icon": Icons.search_rounded, "name": "Eksplorasi Materi", "navigateTo": ExplorationMateriForm(subChapterId: _subchapter!['id'].toString())},
          {"icon": Icons.edit_rounded, "name": "Concept Map", "navigateTo": ConceptMapForm(subChapterId: _subchapter!['id'].toString())},
          {"icon": Icons.lightbulb, "name": "Feedback", "navigateTo": const FeedbackFormPage()},
          {"icon": Icons.question_mark_rounded, "name": "Quiz", "navigateTo": QuizForm(subChapterId: _subchapter!['id'].toString(), type: 'ctl')},
        ];
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteSubChapter() async {
    try {
      var lastTitle = _subchapter!['title'];
      await _supabaseService.deleteSubchapter(widget.subchapter_id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Subchapter $lastTitle berhasil dihapus", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: dangerColor));
      }
    }
  }

  void _showDialogDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FConfirmationDialog(
            content: 'Seluruh data level yang ada pada chapter ini akan ikut dihapus, Apakah anda yakin ingin menghapus Subchapter ${_subchapter!['title']}?',
            action: () async {
              await _deleteSubChapter();
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
      },
    );
  }

  Future<void> _editSubchapter() async {
    try {
      if (_subchapterTitleController.text.trim().isNotEmpty && _sequenceOrderController.text.trim().isNotEmpty) {
        int sequenceOrder = int.parse(_sequenceOrderController.text);
        await _supabaseService.updateSubchapterData(widget.subchapter_id, _subchapterTitleController.text, sequenceOrder);
        await _getSubchapter();
        if (mounted) {
          setState(() {
            _subchapterTitleController.clear();
            _sequenceOrderController.clear();
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Data subchapter ini berhasil diubah", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen));
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Judul subchapter dan urutan tidak boleh kosong", style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: warningColor));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception', 'Gagal Mengubah Data Subchapter')), backgroundColor: dangerColor));
      }
    }
  }

  void _showEditDialog() {
    _subchapterTitleController.text = _subchapter!['title'] ?? "Judul Baru";
    _sequenceOrderController.text = _subchapter!['sequence_order'].toString();
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
                  controller: _subchapterTitleController,
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
                  controller: _sequenceOrderController,
                  keyboardType: TextInputType.number,
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
                FButtonWidget(text: "Simpan", action: () => _editSubchapter()),
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
          "Kelola Subchapter",
          style: fBoldTextStyle.copyWith(color: regularBlue),
        ),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
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
                              Text("Urutan Subchapter: ${_subchapter!['sequence_order']}"),
                              const SizedBox(height: 10),
                              Text("Subchapter: ${_subchapter!['title']}"),
                            ],
                          ),
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
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: _subchapter!['levels'].length,
                    itemBuilder: (context, index) {
                      var level = _subchapter!['levels'][index];
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                              color: Colors.white,
                              child:
                                  ListTile(leading: Icon(level['icon'], color: regularBlue, size: 50), title: Text(level['name'], style: fBoldTextStyle.copyWith(color: regularBlue)), 
                                  onTap: () async {
                                    await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => level['navigateTo']
                                            ),
                                          );
                                  })));
                    })
              ],
            ),
    );
  }
}
