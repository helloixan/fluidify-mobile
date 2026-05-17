import 'dart:developer';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = true;
  String _basePrompt = "";
  late TextEditingController _additionalRulesCtrl;

  @override
  void initState() {
    super.initState();
    _additionalRulesCtrl = TextEditingController();
    _fetchFeedbackPrompt();
  }

  @override
  void dispose() {
    _additionalRulesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFeedbackPrompt() async {
    setState(() => _isLoading = true);
    try {
      String? promptData = await _supabaseService.getPromptbySubChapter("", "feedback");
      if (promptData != null && promptData != "none") {
        _splitPrompt(promptData);
      }
    } catch (e) {
      log("Error fetching feedback prompt: $e");
    }
    setState(() => _isLoading = false);
  }

  void _splitPrompt(String prompt) {
    const separator = "Additional rules:\n";
    if (prompt.contains(separator)) {
      final parts = prompt.split(separator);
      _basePrompt = parts[0];
      _additionalRulesCtrl.text = parts.sublist(1).join(separator);
    } else {
      _basePrompt = "$prompt\n\n$separator";
      _additionalRulesCtrl.text = "";
    }
  }

  Future<void> _savePrompt() async {
    setState(() => _isLoading = true);
    try {
      final newPrompt = _basePrompt + _additionalRulesCtrl.text;
      await _supabaseService.upsertPrompt("feedback", newPrompt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan Prompt!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Kelola Feedback Prompt",
          style: fBoldTextStyle.copyWith(color: regularBlue),
        ),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.save, color: regularBlue), onPressed: _savePrompt),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Base Prompt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: SingleChildScrollView(
                        child: Text(_basePrompt, style: const TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Additional Rules", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _additionalRulesCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: "- Tambahkan aturan tambahan di sini...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}