import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/components/fluidy_outlinebutton.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class QuizForm extends StatefulWidget {
  final String subChapterId;
  final String type;

  const QuizForm({super.key, required this.subChapterId, required this.type});

  @override
  State<QuizForm> createState() => _QuizFormState();
}

class _QuizFormState extends State<QuizForm> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<dynamic, dynamic>> _questions = [];
  String _quizTitle = "";
  String _quizId = "";
  bool _isLoading = true;
  final TextEditingController _titleCtrl = TextEditingController();

  String _selectedSubChapterId = "";
  List<Map<String, dynamic>> _subChapters = [];

  @override
  void initState() {
    super.initState();
    _selectedSubChapterId = widget.subChapterId;
    _loadQuizData();
    if (_selectedSubChapterId.isEmpty) {
      _loadSubChapters();
    }
  }

  Future<void> _loadSubChapters() async {
    final data = await _supabaseService.getAllChapters();
    if (data != null) {
      List<Map<String, dynamic>> allSubchapters = [];
      for (var chapter in data) {
        if (chapter['subchapters'] != null) {
          for (var subchapter in chapter['subchapters']) {
            allSubchapters.add({
              'id': subchapter['subchapter_id'],
              'title': subchapter['subchapter_title'],
            });
          }
        }
      }
      setState(() {
        _subChapters = allSubchapters;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    setState(() => _isLoading = true);
    if (_selectedSubChapterId.isNotEmpty) {
      final data = await _supabaseService.getQuizDatabySubChapter(_selectedSubChapterId, widget.type);

      if (data != null && data['question_jsonb'] != null) {
        List<dynamic> rawQuestions = data['question_jsonb'];
        List<Map<dynamic, dynamic>> processedQuestions = [];

        for (var q in rawQuestions) {
          Map<dynamic, dynamic> questionMap = Map<dynamic, dynamic>.from(q);
          processedQuestions.add(questionMap);
        }

        setState(() {
          _quizId = data['id'].toString();
          _questions = processedQuestions;
          _quizTitle = data['title'] ?? (widget.type == 'ctl' ? 'Kuis Kontekstual' : 'Latihan Soal');
          _titleCtrl.text = _quizTitle;
        });
      } else {
        setState(() {
          _questions = [];
          _quizTitle = widget.type == 'ctl' ? 'Kuis Kontekstual' : 'Latihan Soal';
          _titleCtrl.text = _quizTitle;
        });
      }
    } else {
      setState(() {
        _questions = [];
        _quizTitle = widget.type == 'ctl' ? 'Kuis Kontekstual' : 'Latihan Soal';
        _titleCtrl.text = _quizTitle;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveAll() async {
    if (_selectedSubChapterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih subchapter terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabaseService.upsertQuizData(_selectedSubChapterId, widget.type, _titleCtrl.text, _questions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan Kuis!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openQuestionEditor([int? index]) async {
    final initialData = index != null ? _questions[index] : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditorScreen(initialData: initialData),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _questions[index] = result;
        } else {
          _questions.add(result);
        }
      });
    }
  }

  void _deleteQuestion(int index) {
    showDialog(
        context: context,
        builder: (context) => FConfirmationDialog(
            content: 'Yakin ingin menghapus soal ini?',
            action: () async {
              setState(() => _questions.removeAt(index));
              await _saveAll();
              Navigator.pop(context);
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Kelola ${widget.type == 'ctl' ? 'Quiz' : 'Latihan Soal'}",
          style: fBoldTextStyle.copyWith(color: regularBlue),
        ),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.save, color: regularBlue), onPressed: _saveAll),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.subChapterId == "" && widget.type == "latihan_soal")
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                    child: Text("Pilih Subchapter", style: fHeading3TextStyle.copyWith(color: Colors.black)),
                  ),
                if (widget.subChapterId == "" && widget.type == "latihan_soal")
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: appBackgroundColor,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                        filled: true,
                        fillColor: Colors.white
                      ),
                      value: _selectedSubChapterId.isEmpty ? null : _selectedSubChapterId,
                      items: _subChapters.map((sub) {
                        return DropdownMenuItem<String>(
                          value: sub['id'].toString(),
                          child: Text(sub['title'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSubChapterId = value ?? "");
                        _loadQuizData();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Text("Judul Kuis", style: fHeading3TextStyle.copyWith(color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                    ),
                  ),
                ),
                Expanded(
                  child: _questions.isEmpty
                      ? const Center(child: Text("Belum ada soal. Tambahkan soal baru!"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final q = _questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              color: appBackgroundColor,
                              child: ListTile(
                                title: Text(q['pertanyaan'] ?? 'Tanpa Pertanyaan', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text("Jawaban Benar: ${q['jawaban_benar']}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: regularBlue),
                                      onPressed: () => _openQuestionEditor(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteQuestion(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuestionEditor(),
        icon: const Icon(Icons.add),
        label: const Text("Tambah Soal"),
        backgroundColor: regularBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class QuestionEditorScreen extends StatefulWidget {
  final Map<dynamic, dynamic>? initialData;
  const QuestionEditorScreen({super.key, this.initialData});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  late TextEditingController _pertanyaanCtrl;
  late TextEditingController _urlMediaCtrl;
  late TextEditingController _tipeCtrl;

  List<Map<String, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ??
        {
          "pertanyaan": "",
          "url_media": "",
          "tipe": "pilihan_biasa",
          "jawaban_benar": "",
          "feedback_benar": "",
          "opsi": [],
          "feedback_salah": {},
        };

    _pertanyaanCtrl = TextEditingController(text: data['pertanyaan']);
    _urlMediaCtrl = TextEditingController(text: data['url_media'] ?? "");
    _tipeCtrl = TextEditingController(text: data['tipe'] ?? "pilihan_biasa");

    String correctAns = data['jawaban_benar'] ?? "";
    List<dynamic> rawOptions = data['opsi'] ?? [];
    Map<dynamic, dynamic> feedbackSalah = data['feedback_salah'] ?? {};
    String feedbackBenar = data['feedback_benar'] ?? "";

    if (rawOptions.isEmpty) {
      _options = List.generate(
          4,
          (index) => {
                "textCtrl": TextEditingController(text: ""),
                "isCorrect": index == 0,
                "feedbackCtrl": TextEditingController(text: ""),
              });
    } else {
      for (var opt in rawOptions) {
        bool isCorrect = (opt == correctAns);
        _options.add({
          "textCtrl": TextEditingController(text: opt),
          "isCorrect": isCorrect,
          "feedbackCtrl": TextEditingController(text: isCorrect ? feedbackBenar : (feedbackSalah[opt] ?? "")),
        });
      }
    }
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _urlMediaCtrl.dispose();
    _tipeCtrl.dispose();
    for (var o in _options) {
      o['textCtrl'].dispose();
      o['feedbackCtrl'].dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_pertanyaanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pertanyaan harus diisi!')));
      return;
    }

    bool hasCorrect = _options.any((o) => o['isCorrect']);
    if (!hasCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harus ada 1 jawaban benar!')));
      return;
    }

    List<String> opsiStrings = [];
    String jawabanBenar = "";
    String feedbackBenar = "";
    Map<dynamic, String> feedbackSalah = {};

    for (var opt in _options) {
      String text = opt['textCtrl'].text.trim();
      String feedback = opt['feedbackCtrl'].text.trim();

      if (text.isEmpty) continue; // skip empty options

      opsiStrings.add(text);
      if (opt['isCorrect']) {
        jawabanBenar = text;
        feedbackBenar = feedback;
      } else {
        feedbackSalah[text] = feedback;
      }
    }

    if (opsiStrings.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal harus ada 2 opsi jawaban!')));
      return;
    }

    final result = {
      "pertanyaan": _pertanyaanCtrl.text.trim(),
      "url_media": _urlMediaCtrl.text.trim().isEmpty ? null : _urlMediaCtrl.text.trim(),
      "tipe": _tipeCtrl.text.trim(),
      "opsi": opsiStrings,
      "jawaban_benar": jawabanBenar,
      "feedback_benar": feedbackBenar,
      "feedback_salah": feedbackSalah,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: const Text("Konfigurasi Soal", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.check, color: regularBlue), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Text("Pertanyaan", style: fBoldTextStyle.copyWith(color: Colors.black)),
          ),
          TextField(controller: _pertanyaanCtrl, maxLines: 3, decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)), border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Text("URL Media / Gambar (Opsional)", style: fBoldTextStyle.copyWith(color: Colors.black)),
          ),
          TextField(controller: _urlMediaCtrl, decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                  border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Text("Tipe Soal (default: pilihan_biasa)", style: fBoldTextStyle.copyWith(color: Colors.black)),
          ),
          TextField(controller: _tipeCtrl, decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                  border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
          const Divider(height: 32, thickness: 2),
          Text("Opsi Jawaban", style: fHeading2TextStyle),
          const SizedBox(height: 12),
          ..._options.asMap().entries.map((entry) {
            int index = entry.key;
            var opt = entry.value;
            return Card(
              color: opt['isCorrect'] ? Colors.green.shade50 : Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: opt['isCorrect'] ? Colors.green : Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                              controller: opt['textCtrl'], decoration: InputDecoration(labelText: "Teks Opsi ${index + 1}", border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                              )),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text("Benar?", style: fSemiBoldTextStyle),
                            Switch(
                              value: opt['isCorrect'],
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    for (var o in _options) {
                                      o['isCorrect'] = false;
                                    }
                                  }
                                  opt['isCorrect'] = val;
                                });
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: opt['feedbackCtrl'],
                        decoration: InputDecoration(
                            labelText: opt['isCorrect'] ? "Feedback Jika Benar" : "Feedback Jika Memilih Ini (Salah)", border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: regularBlue)),
                        )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          FOutlinedButton(icon: Icons.add, text: "Tambah Opsi Lain", action: () {
              setState(() {
                _options.add({
                  "textCtrl": TextEditingController(text: ""),
                  "isCorrect": false,
                  "feedbackCtrl": TextEditingController(text: ""),
                });
              });
            }),
          const SizedBox(height: 10),
          FButtonWidget(text: "Terapkan ke Kuis", action: _save, icon: Icons.save)
        ],
      ),
    );
  }
}
