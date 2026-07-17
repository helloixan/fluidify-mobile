import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  final String? reportedPage;
  final String? subChapterId;

  const ReportPage({super.key, this.reportedPage, this.subChapterId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _reportController = TextEditingController();

  void _submitReport() {
    // TODO: Tambahkan fungsi simpan laporan Anda ke database (misalnya menggunakan fungsi SupabaseService)
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Laporan berhasil dikirim', style: fBoldTextStyle.copyWith(color: Colors.black)), backgroundColor: correctGreen,),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Laporkan Masalah", style: fBoldTextStyle.copyWith(fontSize: 20, color: regularBlue)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reportedPage != null) ...[
              Text(
                'Konteks masalah: ${widget.reportedPage}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _reportController,
              maxLines: 6,
              decoration: InputDecoration(
                fillColor: regularBlue,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: regularBlue),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Jelaskan kesalahan soal, jawaban, atau masalah sistem yang Anda temui secara detail...',
              ),
            ),
            const SizedBox(height: 24),
            FButtonWidget(text: "Kirim Laporan", action: _submitReport)
          ],
        ),
      ),
    );
  }
}