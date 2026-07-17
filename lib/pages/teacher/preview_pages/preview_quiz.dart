import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class PreviewQuiz extends StatefulWidget {
  final String title;
  final List<Map<dynamic, dynamic>> questions;

  const PreviewQuiz({super.key, required this.title, required this.questions});

  @override
  State<PreviewQuiz> createState() => _PreviewQuizState();
}

class _PreviewQuizState extends State<PreviewQuiz> {
  int _currentIndex = 0;
  String? _selectedOption;
  String _feedbackMessage = "";
  bool _isCorrect = false;

  List<Map<dynamic, dynamic>> _processedQuestions = [];

  @override
  void initState() {
    super.initState();
    _processQuestions();
  }

  void _processQuestions() {
    for (var q in widget.questions) {
      Map<dynamic, dynamic> questionMap = Map<dynamic, dynamic>.from(q);
      if (questionMap['opsi'] != null) {
        List<dynamic> shuffledOptions = List<dynamic>.from(questionMap['opsi']);
        shuffledOptions.shuffle();
        questionMap['opsi'] = shuffledOptions;
      }
      _processedQuestions.add(questionMap);
    }
  }

  void _checkAnswer(String selected) {
    if (_isCorrect) return; // Mencegah klik setelah jawaban benar di preview

    final currentQ = _processedQuestions[_currentIndex];
    final correctAnswer = currentQ['jawaban_benar'];
    final bool isAnswerCorrect = (selected == correctAnswer);

    setState(() {
      _selectedOption = selected;
      if (isAnswerCorrect) {
        _isCorrect = true;
        _feedbackMessage = currentQ['feedback_benar'] ?? 'Jawaban benar!';
      } else {
        _isCorrect = false;
        // Menangani null pada feedback salah
        _feedbackMessage = currentQ['feedback_salah']?[selected] ?? 'Jawaban kurang tepat, coba lagi ya!';
      }
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOption = null;
        _isCorrect = false;
        _feedbackMessage = "";
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _processedQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isCorrect = false;
        _feedbackMessage = "";
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: appBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Luar Biasa! 🎉",
          textAlign: TextAlign.center,
          style: fBoldTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Kamu telah berhasil melihat pratinjau kuis ini hingga selesai.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 200, width: 180, child: Image.asset('assets/img/fluidy_happy.png')),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: regularBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke form
              },
              child: Text("Tutup Pratinjau", style: fMediumTextStyle.copyWith(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_processedQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          title: Text("Pratinjau Kuis", style: fSemiBoldTextStyle),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: Text("Belum ada soal untuk dipratinjau.")),
      );
    }

    final currentQ = _processedQuestions[_currentIndex];
    final List<dynamic> options = currentQ['opsi'] ?? [];

    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title.isNotEmpty ? "Pratinjau: ${widget.title}" : "Pratinjau Kuis",
          style: fSemiBoldTextStyle,
        ),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Soal ${_currentIndex + 1} dari ${_processedQuestions.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (currentQ['url_media'] != null && currentQ['url_media'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  currentQ['url_media'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              currentQ['pertanyaan'] ?? "Tanpa Pertanyaan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...options.map((option) {
              bool isSelected = _selectedOption == option;
              Color buttonColor = Colors.white;
              Color borderColor = Colors.grey.shade400;

              if (isSelected) {
                if (_isCorrect) {
                  buttonColor = Colors.green.shade50;
                  borderColor = Colors.green;
                } else {
                  buttonColor = Colors.red.shade50;
                  borderColor = Colors.red;
                }
              } else if (_isCorrect && option == currentQ['jawaban_benar']) {
                buttonColor = Colors.green.shade50;
                borderColor = Colors.green;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => _checkAnswer(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            if (_selectedOption != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCorrect ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect ? Icons.check_circle : Icons.error_outline,
                      color: _isCorrect ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                         _feedbackMessage.isNotEmpty ? _feedbackMessage : (_isCorrect ? "Benar!" : "Salah!"),
                        style: TextStyle(
                          fontSize: 15,
                          color: _isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        side: const BorderSide(color: regularBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _previousQuestion,
                      child: Text(
                        "Sebelumnya",
                        style: fBoldTextStyle.copyWith(color: regularBlue, fontSize: 16),
                      ),
                    ),
                  ),
                if (_currentIndex > 0 && _isCorrect) const SizedBox(width: 16),
                if (_isCorrect)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _nextQuestion,
                      child: Text(
                        _currentIndex == _processedQuestions.length - 1 ? "Selesai" : "Berikutnya",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}