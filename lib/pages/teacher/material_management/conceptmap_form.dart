import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:fluidify_mobile/pages/teacher/preview_pages/preview_conceptmap.dart';

class ConceptMapForm extends StatefulWidget {
  final String subChapterId;
  final bool isAuthor;
  const ConceptMapForm({super.key, required this.subChapterId, required this.isAuthor});

  @override
  State<ConceptMapForm> createState() => _ConceptMapFormState();
}

class _ConceptMapFormState extends State<ConceptMapForm> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMindmapData();
  }

  Future<void> _fetchMindmapData() async {
    setState(() => _isLoading = true);
    final data = await _supabaseService.getMindmapBySubChapter(widget.subChapterId);

    if (data != null && data['subjects'] != null) {
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(data['subjects']);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.upsertMindmap(widget.subChapterId, _subjects);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan Concept Map!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openNodeEditor([int? index]) async {
    final initialData = index != null ? _subjects[index] : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConceptNodeEditorScreen(initialData: initialData),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _subjects[index] = result;
        } else {
          _subjects.add(result);
        }
      });
    }
  }

  void _deleteNode(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Node"),
        content: const Text("Yakin ingin menghapus node ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              setState(() => _subjects.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: Text(
            "Kelola Concept Map",
            style: fBoldTextStyle.copyWith(color: regularBlue),
          ),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: widget.isAuthor
            ? [
          IconButton(icon: const Icon(Icons.save, color: regularBlue), onPressed: _saveAll),
        ] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : _subjects.isEmpty
              ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: AppSize.screenHeight(context) * 0.4),
                    child: const Text("Belum ada data Concept Map. Tambahkan node baru!"),
                  ),
                  if (widget.isAuthor)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: AppSize.screenWidth(context) * 0.9,
                                child: FButtonWidget(text: "Tambah Node", action: _openNodeEditor, icon: Icons.add,)
                              ),
                            ),
                ],
              ))
              : Column(
                children: [
                  if (widget.isAuthor)
                  Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [ 
                          Text("Halaman ini adalah draft, Jangan lupa klik icon '", style: fBoldTextStyle.copyWith(color: softGray)),
                          Icon(Icons.save, color: softGray, size: 20),
                          Text("'", style: fBoldTextStyle.copyWith(color: softGray)),
                        ]),
                        Text("untuk menyimpan setiap perubahan yang kamu buat!", style: fBoldTextStyle.copyWith(color: softGray)),
                    ],
                  )),
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final node = _subjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            color: appBackgroundColor,
                            child: ListTile(
                              title: Text(node['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Sequence: ${node['sequence'] == 0 || node['sequence'] == 0.0 ? '0 (Distractor)' : node['sequence']}"),
                              trailing: widget.isAuthor
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          IconButton(
                                              icon: const Icon(Icons.edit, color: regularBlue),
                                              onPressed: () => _openNodeEditor(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteNode(index),
                                  ),
                                ],
                              ) : const SizedBox(width: 30, height: 30,),
                            ),
                          );
                        },
                      ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.isAuthor)
                            SizedBox(
                              width: AppSize.screenWidth(context) * 0.45,
                              child: FButtonWidget(text: "Tambah Pilihan", action: _openNodeEditor, icon: Icons.add,)
                            ),
                          SizedBox(
                            width: widget.isAuthor
                                ? AppSize.screenWidth(context) * 0.45 : AppSize.screenWidth(context) * 0.9,
                            child: FButtonWidget(
                              text: "Pratinjau", 
                              action: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PreviewConceptmap(
                                      subjects: _subjects,
                                    ),
                                  ),
                                );
                              }, 
                              icon: Icons.remove_red_eye,
                            )
                          )
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}

class ConceptNodeEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ConceptNodeEditorScreen({super.key, this.initialData});

  @override
  State<ConceptNodeEditorScreen> createState() => _ConceptNodeEditorScreenState();
}

class _ConceptNodeEditorScreenState extends State<ConceptNodeEditorScreen> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _sequenceCtrl;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {
      "subject": "",
      "sequence": 1.0,
    };

    _subjectCtrl = TextEditingController(text: data['subject']);
    _sequenceCtrl = TextEditingController(text: data['sequence'].toString());
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _sequenceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_subjectCtrl.text.isEmpty || _sequenceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject dan Sequence harus diisi')));
      return;
    }
    
    num sequenceVal = num.tryParse(_sequenceCtrl.text) ?? 0;

    final result = {
      "subject": _subjectCtrl.text,
      "sequence": sequenceVal,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Konfigurasi Node", style: fBoldTextStyle.copyWith(color: regularBlue)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.save, color: regularBlue), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subjek (Teks Node)", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _sequenceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Urutan (Sequence, misal: 1, 1.1, 0 untuk distractor)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text("Terapkan"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: regularBlue, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 20),
          Text("Catatan:", style: fBoldTextStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          const Text("1. Urutan (Sequence) menentukan posisi node dalam Concept Map. Nilai 0 atau 0.0 akan dianggap sebagai Distractor dan ditempatkan di bagian bawah tanpa garis penghubung."),
          const SizedBox(height: 8),
          const Text("2. Urutan dengan nilai desimal (misal: 1.1, 1.2) akan ditempatkan di antara urutan parent (misal: 1 dan 2)."),
          const SizedBox(height: 8),
          const Text("3. Jika 1.1 ingin memiliki child node, maka child node tersebut bisa diberi urutan 1.11, 1.12, dst untuk menandakan bahwa mereka adalah child dari 1.1"),
          const SizedBox(height: 8),
          const Text("4. Pastikan setiap node memiliki urutan yang unik untuk menghindari konflik penempatan."),
          const SizedBox(height: 8),
          const Text("5. Node dengan urutan yang lebih rendah akan ditempatkan lebih tinggi dalam Concept Map, sedangkan node dengan urutan yang lebih tinggi akan ditempatkan lebih rendah."),
          const SizedBox(height: 8),
          const Text("6. Node dengan urutan 1 akan ditempatkan sebagai 'root' atau node utama, sedangkan node dengan urutan 1.1, 1.2 akan ditempatkan sebagai child dari node 1."),
        ],
      ),
    );
  }
}
