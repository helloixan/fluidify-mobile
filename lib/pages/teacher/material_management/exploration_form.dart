import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/components/fluidy_outlinebutton.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:fluidify_mobile/pages/teacher/preview_pages/preview_materi.dart';
import 'package:flutter/material.dart';

class ExplorationMateriForm extends StatefulWidget {
  final String subChapterId;
  final bool isAuthor;

  const ExplorationMateriForm({super.key, required this.subChapterId, required this.isAuthor});

  @override
  State<ExplorationMateriForm> createState() => _ExplorationMateriFormState();
}

class _ExplorationMateriFormState extends State<ExplorationMateriForm> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _flowData = [];
  bool _isLoading = true;
  bool isEditing = false;


  @override
  void initState() {
    super.initState();
    _fetchChatbotData();
  }

  Future<void> _fetchChatbotData() async {
    setState(() => _isLoading = true);
    final rawData = await _supabaseService.getChatbotFlowBySubChapter(widget.subChapterId);

    if (rawData != null && rawData['flow_data'] != null) {
      setState(() {
        _flowData = List<Map<String, dynamic>>.from(rawData['flow_data']);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.upsertChatbotFlow(widget.subChapterId, _flowData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan materi eksplorasi!'), backgroundColor: Colors.green));
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
    final initialData = index != null ? _flowData[index] : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NodeEditorScreen(initialData: initialData),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _flowData[index] = result;
        } else {
          _flowData.add(result);
        }
      });
    }
  }

  void _deleteNode(int index) {
    showDialog(
      context: context,
      builder: (context) => FConfirmationDialog(content: "Yakin ingin menghapus step ini?", action: () {
              setState(() => _flowData.removeAt(index));
              Navigator.pop(context);
            })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            "Kelola Eksplorasi Materi",
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
          : _flowData.isEmpty
              ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: AppSize.screenHeight(context) * 0.4),
                    child: const Text("Belum ada data eksplorasi. Tambahkan step baru!"),
                  ),
                  if (widget.isAuthor)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: AppSize.screenWidth(context) * 0.9,
                                child: FButtonWidget(text: "Tambah Step", action: _openNodeEditor, icon: Icons.add,)
                              ),
                            ),
                ],
              ))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (widget.isAuthor)
                        Padding(
                          padding: const EdgeInsets.all(16),
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
                              itemCount: _flowData.length,
                              itemBuilder: (context, index) {
                                final node = _flowData[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: appBackgroundColor,
                                  elevation: 3,
                                  child: ListTile(
                                    title: Text(node['nodeId'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(node['botMessage'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
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
                                    ) : const SizedBox(width: 30, height: 30,)
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
                              child: FButtonWidget(text: "Tambah Step", action: _openNodeEditor, icon: Icons.add,)
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
                                    builder: (context) => PreviewEksplorasiMateri(
                                      flowData: _flowData,
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
                  ),
                ],
              ),
    );
  }
}

class NodeEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const NodeEditorScreen({super.key, this.initialData});

  @override
  State<NodeEditorScreen> createState() => _NodeEditorScreenState();
}

class _NodeEditorScreenState extends State<NodeEditorScreen> {
  late TextEditingController _nodeIdCtrl;
  late TextEditingController _botMsgCtrl;
  late TextEditingController _progressCtrl;
  late TextEditingController _imageRefCtrl;

  List<Map<dynamic, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {
      "nodeId": "step_",
      "botMessage": "",
      "progress": 0.0,
      "imageRef": "",
      "options": [
        {"text": "", "type": "correct", "reply": "", "weight": 1.0, "nextNode": "end"},
        {"text": "", "type": "partial", "reply": "", "weight": 0.66, "nextNode": "end"},
        {"text": "", "type": "misconception", "reply": "", "weight": 0.33, "nextNode": "end"},
        {"text": "", "type": "naive", "reply": "", "weight": 0.0, "nextNode": "end"}
      ]
    };

    _nodeIdCtrl = TextEditingController(text: data['nodeId']);
    _botMsgCtrl = TextEditingController(text: data['botMessage']);
    _progressCtrl = TextEditingController(text: data['progress'].toString());
    _imageRefCtrl = TextEditingController(text: data['imageRef'] ?? '');

    _options = (data['options'] as List).map((o) => {
      ...o,
      'textCtrl': TextEditingController(text: o['text']),
      'replyCtrl': TextEditingController(text: o['reply']),
      'nextCtrl': TextEditingController(text: o['nextNode']),
    }).toList();
  }

  @override
  void dispose() {
    _nodeIdCtrl.dispose();
    _botMsgCtrl.dispose();
    _progressCtrl.dispose();
    _imageRefCtrl.dispose();
    for (var o in _options) {
      o['textCtrl'].dispose();
      o['replyCtrl'].dispose();
      o['nextCtrl'].dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_nodeIdCtrl.text.isEmpty || _botMsgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Node ID dan Pesan Bot harus diisi')));
      return;
    }

    final result = {
      "nodeId": _nodeIdCtrl.text,
      "botMessage": _botMsgCtrl.text,
      "progress": double.tryParse(_progressCtrl.text) ?? 0.0,
      "imageRef": _imageRefCtrl.text.isEmpty ? null : _imageRefCtrl.text,
      "options": _options.map((o) => {
        "text": o['textCtrl'].text,
        "type": o['type'],
        "reply": o['replyCtrl'].text,
        "weight": o['weight'],
        "nextNode": o['nextCtrl'].text,
      }).toList()
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Konfigurasi Step", style: fBoldTextStyle.copyWith(color: regularBlue)),
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
          TextField(controller: _nodeIdCtrl, decoration: const InputDecoration(labelText: "Node ID (cth: step_1)", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _botMsgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Pesan Bot", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _progressCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Progress (0.0 - 1.0)", border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _imageRefCtrl, decoration: const InputDecoration(labelText: "Image URL (Opsional)", border: OutlineInputBorder()))),
            ],
          ),
          const Divider(height: 32, thickness: 2),
          const Text("Opsi Jawaban Siswa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._options.map((opt) {
            return Card(
              color: Colors.grey[100],
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tipe: ${opt['type'].toString().toUpperCase()} (Weight: ${opt['weight']})", style: const TextStyle(fontWeight: FontWeight.bold, color: regularBlue)),
                    const SizedBox(height: 8),
                    TextField(controller: opt['textCtrl'], decoration: const InputDecoration(labelText: "Teks Pilihan Siswa", filled: true, fillColor: Colors.white)),
                    const SizedBox(height: 8),
                    TextField(controller: opt['replyCtrl'], decoration: const InputDecoration(labelText: "Balasan Bot (Reply)", filled: true, fillColor: Colors.white)),
                    const SizedBox(height: 8),
                    TextField(controller: opt['nextCtrl'], decoration: const InputDecoration(labelText: "Node Selanjutnya (cth: step_2 / end)", filled: true, fillColor: Colors.white)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text("Terapkan ke Step"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: regularBlue, foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }
}