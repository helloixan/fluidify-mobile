import 'dart:developer';

import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/report_page.dart';
import 'package:fluidify_mobile/pages/student/getpoint_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;
  final String type;

  const QuizPage({super.key, required this.subChapterId, required this.currentPoints, required this.type});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final SupabaseService _supabaseService = SupabaseService();

  List<dynamic> _questions = [];
  String _quizTitle = "";
  String _quizId = "";
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _selectedOption;
  String _feedbackMessage = "";
  bool _isCorrect = false;

  // Variabel untuk Tracking History Jawaban
  List<Map<String, dynamic>> _attemptHistory = [];
  int _corrects = 0;
  int _wrongs = 0;
  late DateTime _questionStartTime;
  bool _firstAttemptRecorded = false;

  // --- Variabel State Review Mode ---
  bool _isReviewMode = false;
  int _previousScore = 0;
  Map<int, Map<String, dynamic>> _reviewAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final data = await _supabaseService.getQuizDatabySubChapter(widget.subChapterId, widget.type);

    if (data != null && data['question_jsonb'] != null) {
      // --- LOGIKA SHUFFLE OPSI JAWABAN ---
      List<dynamic> rawQuestions = data['question_jsonb'];
      List<Map<String, dynamic>> processedQuestions = [];

      for (var q in rawQuestions) {
        Map<String, dynamic> questionMap = Map<String, dynamic>.from(q);

        if (questionMap['opsi'] != null) {
          List<dynamic> shuffledOptions = List<dynamic>.from(questionMap['opsi']);
          shuffledOptions.shuffle();
          questionMap['opsi'] = shuffledOptions;
        }
        processedQuestions.add(questionMap);
      }
      // -----------------------------------

      setState(() {
        _quizId = data['id'].toString();
        _questions = processedQuestions;
        _quizTitle = data['title'] ?? 'Kuis Kontekstual';
      });

      // --- LOGIKA CEK REVIEW MODE ---
      var studentId = _supabaseService.getCurrentUserId();
      if (studentId != null) {
        final attemptData = await _supabaseService.getStudentQuizAttempt(_quizId, studentId);

        // Jika user sudah pernah attempt, aktifkan Review Mode
        if (attemptData != null) {
          setState(() {
            _isReviewMode = true;
            _previousScore = attemptData['score'] ?? 0;
            List<dynamic> history = attemptData['attempt_history'] ?? [];

            // Simpan history ke dalam Map agar mudah diakses berdasarkan index pertanyaan
            for (var item in history) {
              int qIndex = (item['question_id'] as int) - 1;
              _reviewAnswers[qIndex] = item;
            }
          });
        }
      }
      // --------------------------------

      setState(() {
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });

      // Jika masuk dalam mode review, siapkan state jawaban untuk soal pertama
      if (_isReviewMode) {
        _setupReviewStateForCurrentQuestion();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat ${widget.type == "ctl" ? "quiz" : "latihan soal"}. Coba lagi nanti.')),
      );
    }
  }

  // Fungsi khusus untuk mengatur UI jawaban di Review Mode
  void _setupReviewStateForCurrentQuestion() {
    if (_reviewAnswers.containsKey(_currentIndex)) {
      final pastAnswer = _reviewAnswers[_currentIndex]!;
      final currentQ = _questions[_currentIndex];

      setState(() {
        _selectedOption = pastAnswer['selected_option'];
        _isCorrect = pastAnswer['is_correct'] ?? false;

        if (_isCorrect) {
          _feedbackMessage = currentQ['feedback_benar'];
        } else {
          _feedbackMessage = currentQ['feedback_salah'][_selectedOption] ?? 'Jawaban kurang tepat pada percobaan sebelumnya.';
        }
      });
    }
  }

  void _checkAnswer(String selected) {
    // Jika sedang dalam Review Mode atau jawaban sudah benar, cegah interaksi
    if (_isReviewMode || _isCorrect) return;

    final currentQ = _questions[_currentIndex];
    final correctAnswer = currentQ['jawaban_benar'];
    final bool isAnswerCorrect = (selected == correctAnswer);

    if (!_firstAttemptRecorded) {
      final int timeSpent = DateTime.now().difference(_questionStartTime).inSeconds;

      _attemptHistory.add({
        "question_id": _currentIndex + 1,
        "step_type": currentQ['tipe'] ?? 'konsep',
        "selected_option": selected,
        "is_correct": isAnswerCorrect,
        "time_spent_sec": timeSpent,
        "answered_at": DateTime.now().toUtc().toIso8601String()
      });

      if (isAnswerCorrect) {
        _corrects++;
      } else {
        _wrongs++;
      }

      _firstAttemptRecorded = true;
    }

    setState(() {
      _selectedOption = selected;
      if (isAnswerCorrect) {
        _isCorrect = true;
        _feedbackMessage = currentQ['feedback_benar'];
      } else {
        _isCorrect = false;
        _feedbackMessage = currentQ['feedback_salah'][selected] ?? 'Jawaban kurang tepat, coba lagi ya!';
      }
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;

        if (_isReviewMode) {
          _setupReviewStateForCurrentQuestion();
        } else {
          final pastAttempts = _attemptHistory.where((a) => a['question_id'] == _currentIndex + 1).toList();
          if (pastAttempts.isNotEmpty && pastAttempts.any((a) => a['is_correct'] == true)) {
            final correctAttempt = pastAttempts.firstWhere((a) => a['is_correct'] == true);
            _selectedOption = correctAttempt['selected_option'];
            _isCorrect = true;
            _feedbackMessage = _questions[_currentIndex]['feedback_benar'];
            _firstAttemptRecorded = true;
          }
        }
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;

        if (_isReviewMode) {
          _setupReviewStateForCurrentQuestion();
        } else {
          final pastAttempts = _attemptHistory.where((a) => a['question_id'] == _currentIndex + 1).toList();
          if (pastAttempts.isNotEmpty && pastAttempts.any((a) => a['is_correct'] == true)) {
            final correctAttempt = pastAttempts.firstWhere((a) => a['is_correct'] == true);
            _selectedOption = correctAttempt['selected_option'];
            _isCorrect = true;
            _feedbackMessage = _questions[_currentIndex]['feedback_benar'];
            _firstAttemptRecorded = true;
          } else {
            _selectedOption = null;
            _isCorrect = false;
            _feedbackMessage = "";
            _firstAttemptRecorded = false;
            _questionStartTime = DateTime.now();
          }
        }
      });
    } else {
      if (_isReviewMode) {
        // Jika Review Mode, tidak perlu submit data lagi
        _showCompletionDialog(_previousScore);
      } else {
        _submitQuizData();
      }
    }
  }

  Future<void> _submitQuizData() async {
    setState(() {
      _isSubmitting = true;
    });

    int calculatedScore = ((_corrects / _questions.length) * 100).round();
    var studentId = _supabaseService.getCurrentUserId();

    if (studentId != null) {
      log("saving quiz attempt for studentId: $studentId with score: $calculatedScore, corrects: $_corrects, wrongs: $_wrongs");
      await _supabaseService.insertStudentQuizAttempt(
        _quizId,
        studentId,
        calculatedScore,
        _wrongs,
        _corrects,
        _attemptHistory,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        _showCompletionDialog(calculatedScore);
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. User tidak terdeteksi.')),
      );
    }
  }

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Keluar dari ${widget.type == "ctl" ? "quiz" : "latihan soal"}?"),
        content: FluidywithBubble(
          text: "Kamu belum menyelesaikan ${widget.type == "ctl" ? "quiz" : "latihan soal"} ini. Jika keluar sekarang, progress jawaban dan skormu tidak akan disimpan.",
          maskotPath: "assets/img/fluidy_confuse.png",
          maskotSize: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(int finalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: appBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isReviewMode ? "Ulasan Selesai" : "Luar Biasa! 🎉",
          textAlign: TextAlign.center,
          style: fBoldTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isReviewMode ? "Kamu telah melihat kembali ${widget.type == "ctl" ? "quiz" : "latihan soal"} ini." : "Kamu telah berhasil menyelesaikan seluruh langkah pembelajaran ini dengan baik.",
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
              onPressed: () async {
                if (!_isReviewMode) {
                  var studentId = _supabaseService.getCurrentUserId();
                  if (studentId != null) {
                    if (widget.type == "ctl") {
                      Map<String, int> currentProgressMap = await _supabaseService.getStudentLevelProgress(studentId);
                      int currentLevel = currentProgressMap[widget.subChapterId] ?? 0;

                      if (currentLevel < 5) {
                        await _supabaseService.updateStudentLevelProgress(studentId, widget.subChapterId, 5);
                      }
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GetPointPage(
                            title: "${widget.type == "ctl" ? "Quiz" : "Latihan Soal"} ini Berhasil Diselesaikan!",
                            description: "Kamu mendapatkan $finalScore poin dari menyelesaikan ${widget.type == "ctl" ? "quiz" : "latihan soal"} ini.",
                            pointsEarned: finalScore, // Jangan kasih poin lagi kalau cuma review
                            currentPoints: widget.currentPoints),
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: Text("Selesai", style: fMediumTextStyle.copyWith(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_isLoading || _questions.isEmpty || _isSubmitting) {
          Navigator.of(context).pop();
          return;
        }

        // Jika dalam Review Mode, boleh langsung keluar tanpa konfirmasi skor hilang
        if (_isReviewMode) {
          Navigator.of(context).pop();
          return;
        }

        final bool shouldPop = await _showExitConfirmationDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          title: Text(
            _quizTitle,
            style: fSemiBoldTextStyle,
          ),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
          IconButton(
            icon: Icon(Icons.report_problem_outlined, color: dangerColor),
            tooltip: 'Laporkan Masalah',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(
                    reportedPage: 'Kuis',
                    subChapterId: widget.subChapterId,
                  ),
                ),
              );
            },
          ),
        ],
        ),
        body: _isLoading || _isSubmitting
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const CircularProgressIndicator(color: regularBlue), const SizedBox(height: 16), Text(_isSubmitting ? "Menyimpan jawaban..." : "Memuat ${widget.type == "ctl" ? "quiz" : "latihan soal"}...")],
                ),
              )
            : _questions.isEmpty
                ? Center(child: Text("Tidak ada ${widget.type == "ctl" ? "quiz" : "latihan soal"} tersedia."))
                : _buildQuizContent(),
      ),
    );
  }

  Widget _buildQuizContent() {
    final currentQ = _questions[_currentIndex];
    final List<dynamic> options = currentQ['opsi'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KETERANGAN KUIS & INDIKATOR MODE REVIEW
          if (_isReviewMode)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade600)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${widget.type == "ctl" ? "quiz" : "latihan soal"} sudah diselesaikan, Skor Akhir : $_previousScore",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Soal ${_currentIndex + 1} dari ${_questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // 2. GAMBAR (MEDIA)
          if (currentQ['url_media'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: NetworkImage(currentQ['url_media']),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  height: 150,
                  child: Center(child: Text(currentQ['alt_media'] != null && currentQ['alt_media'].isNotEmpty ? "{alt: ${currentQ['alt_media']}}" : "Gagal memuat gambar", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])))),
              ),
            ),
          const SizedBox(height: 20),

          // 3. PERTANYAAN
          Text(
            currentQ['pertanyaan'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 4. OPSI JAWABAN
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
            } else if ((_isCorrect || _isReviewMode) && option == currentQ['jawaban_benar']) {
              // Jika jawaban saat ini salah di Review Mode, kita tetap berikan highlight hijau pada opsi yang aslinya benar
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

          // 5. FEEDBACK SECTION
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
                      _feedbackMessage,
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

          // 6. TOMBOL NAVIGASI
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
              if (_currentIndex > 0 && (_isCorrect || _isReviewMode)) const SizedBox(width: 16),
              if (_isCorrect || _isReviewMode)
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
                      _currentIndex == _questions.length - 1 && _isReviewMode ? "Tutup Ulasan" : "Berikutnya",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
