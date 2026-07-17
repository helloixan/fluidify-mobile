import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/report_page.dart';
import 'package:fluidify_mobile/pages/student/getpoint_page.dart';
import 'package:fluidify_mobile/pages/waiting_screen.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:flutter_gemini/flutter_gemini.dart';

class StudentOpinionPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;
  const StudentOpinionPage({super.key, required this.subChapterId, required this.currentPoints});

  @override
  State<StudentOpinionPage> createState() => _StudentOpinionPageState();
}

class _StudentOpinionPageState extends State<StudentOpinionPage> {
  TextEditingController _studentAnswerController = TextEditingController();
  final Gemini gemini = Gemini.instance;
  final SupabaseService _supabaseService = SupabaseService();
  String _essentialFeedbackId = "";
  String _question = "";
  String _prompt = "";
  // String _feedback = "";
  bool isAlreadySubmitted = false;
  bool isGettingStudentAnswer = true;

  @override
  void initState() {
    _fetchExistingAnswer();
    super.initState();
  }

  Future<void> _fetchExistingAnswer() async {
    await _fetchEssentialQuestion();
    var studentId = _supabaseService.getCurrentUserId();
    log("essentialFeedbackId: $_essentialFeedbackId");
    if (studentId != null) {
      var existingFeedback = await _supabaseService.getStudentFeedbacksByEssentialFeedbackId(_essentialFeedbackId, studentId);
      if (existingFeedback != null && existingFeedback['student_answer'].isNotEmpty) {
        setState(() {
          _studentAnswerController.text = existingFeedback['student_answer'] ?? "";
          isAlreadySubmitted = true;
        });
      }
      setState(() {
        isGettingStudentAnswer = false;
      });
    }
  }

  Future<void> _fetchEssentialQuestion() async {
    var essentialFeedbacks = await _supabaseService.getEssentialQuestionBySubChapter(widget.subChapterId);
    setState(() {
      if (essentialFeedbacks != null) {
        _question = essentialFeedbacks['essential_question'];
        _essentialFeedbackId = essentialFeedbacks['id'];
      }
    });
  }

  Future<void> _fetchCheckingPrompt() async {
    try {
      if (_prompt == "") {
        String? promptData = await _supabaseService.getPromptbySubChapter("", "check_relevan_answer");
        if (promptData != null && promptData.isNotEmpty) {
          promptData = promptData.replaceAll("{question}", _question);
          promptData = promptData.replaceAll("{student_answer}", _studentAnswerController.text);
          log("Prompt : $promptData");

          setState(() {
            _prompt = promptData!;
          });
        } else {
          log("No feedback prompt found for subChapterId: ${widget.subChapterId}");
        }
      }
    } catch (e) {
      log("Error fetching feedback prompt: $e");
    }
  }

  Future<bool> _checkStudentAnswer(String studentAnswer) async {
    try {
      await _fetchCheckingPrompt();
      log("Check Prompt: $_prompt");
      if (_prompt != "") {
        final event = await gemini.prompt(parts: [Part.text(_prompt)]);
        String? response = event?.output;
        if (response != null && response.isNotEmpty) {
          log("Check Response: $response");
          if (response.toLowerCase().contains("ya")) {
            return true;
          } else {
            return false;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fluidy tidak dapat memeriksa jawaban kamu saat ini. Silakan coba lagi nanti."),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fluidy tidak dapat melakukan pengecekan jawaban kamu saat ini. Silakan coba lagi nanti."),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fluidy tidak dapat memeriksa jawaban kamu saat ini. Silakan coba lagi nanti."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appBackgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 250, width: 200, child: Image.asset('assets/img/fluidy_confuse.png')),
              Text(
                'Jawaban kamu tidak relevan dengan pertanyaan, harap masukkan kembali ya!',
                style: fSemiBoldTextStyle.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FButtonWidget(
                text: "Coba Lagi",
                action: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveStudentAnswer(String studentAnswer) async {
    try {
      var studentId = _supabaseService.getCurrentUserId();
      log("studentId: $studentId, essentialFeedbackId: $_essentialFeedbackId");
      if (_essentialFeedbackId != "" && studentId != null) {
        var studentFeedbackData = await _supabaseService.getStudentFeedbacks(_essentialFeedbackId, studentId);
        if (studentFeedbackData != null) {
          await _supabaseService.updateStudentFeedbacks(_essentialFeedbackId, studentAnswer, "", studentId);
        } else {
          await _supabaseService.insertStudentFeedbacks(_essentialFeedbackId, studentAnswer, "", studentId);
        }
      }
    } catch (e) {
      log("Error saving feedback to database: $e");
    }
  }

  Future<void> _showFeedbackDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appBackgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 250, width: 200, child: Image.asset('assets/img/fluidy_envelope.png')),
              Text(
                'Tersimpan',
                style: fBoldTextStyle.copyWith(fontSize: 21),
                textAlign: TextAlign.center,
              ),
              Text(
                'Yeay, Jawaban Kamu Berhasil Disimpan!',
                style: fSemiBoldTextStyle.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appBackgroundColor,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Apakah kamu yakin ingin menyimpan jawaban?',
                    style: fSemiBoldTextStyle.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 250, width: 200, child: Image.asset('assets/img/fluidy_confuse.png')),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: regularBlue, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Batal", style: fSemiBoldTextStyle.copyWith(color: regularBlue, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: FButtonWidget(
                        text: "Yakin",
                        action: () async {
                          Navigator.pop(dialogContext);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VideoLoadingPage(
                                videoAssetPath: 'assets/videos/fluidy_checking.mp4',
                              ),
                            ),
                          );

                          try {
                            bool isRelevant = await _checkStudentAnswer(_studentAnswerController.text);

                            if (mounted) {
                              Navigator.pop(context);
                            }

                            if (isRelevant) {
                              await _saveStudentAnswer(_studentAnswerController.text);

                              var studentId = _supabaseService.getCurrentUserId();
                              if (studentId != null) {
                                Map<String, int> currentProgressMap = await _supabaseService.getStudentLevelProgress(studentId);
                                int currentLevel = currentProgressMap[widget.subChapterId] ?? 0;

                                if (currentLevel < 1) {
                                  await _supabaseService.updateStudentLevelProgress(studentId, widget.subChapterId, 1);
                                }
                              }

                              if (mounted) {
                                _showFeedbackDialog(); // dialog sukses

                                await Future.delayed(const Duration(seconds: 2));
                                if (mounted) {
                                  var gainPoin = 50; // Contoh poin yang didapat
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GetPointPage(
                                          title: "Simulasi Berhasil Diselesaikan!",
                                          description: "Kamu mendapatkan $gainPoin poin dari menyelesaikan level ini.",
                                          pointsEarned: gainPoin,
                                          currentPoints: widget.currentPoints),
                                    ),
                                  );
                                }
                              }
                            } else {
                              setState(() {
                                _studentAnswerController.text = "";
                              });
                              if (mounted) {
                                _showErrorDialog();
                              }
                            }
                          } catch (e) {
                            log("Error saat menyimpan: $e");
                            if (mounted) {
                              // Pastikan loading screen ditutup jika terjadi error
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Terjadi kesalahan saat memproses jawaban. Coba lagi."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Pertanyaan Pemantik", style: fBoldTextStyle.copyWith(fontSize: 20, color: regularBlue)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.report_problem_outlined, color: dangerColor),
            tooltip: 'Laporkan Masalah',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(
                    reportedPage: 'Pertanyaan Pemantik', 
                    subChapterId: widget.subChapterId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: appBackgroundColor,
      body: isGettingStudentAnswer
          ? const Center(child: CircularProgressIndicator(color: regularBlue))
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: FluidywithBubble(text: _question),
                  ),
                  if (isAlreadySubmitted)
                    Text(
                      "Jawaban kamu sebelumnya:",
                      style: fSemiBoldTextStyle.copyWith(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextField(
                        enabled: !isAlreadySubmitted,
                        controller: _studentAnswerController,
                        maxLines: 10,
                        minLines: 10,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(),
                        )),
                  ),
                  if (!isAlreadySubmitted)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: FButtonWidget(
                          text: "Simpan Jawaban",
                          action: () {
                            if (_studentAnswerController.text.isNotEmpty) {
                              _showConfirmationDialog();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jawaban tidak boleh kosong!")));
                            }
                          }),
                    )
                ],
              ),
            ),
    );
  }
}
