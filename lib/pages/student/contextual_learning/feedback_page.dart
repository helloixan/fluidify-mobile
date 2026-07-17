import 'dart:developer';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/latex_syntax.dart';
import 'package:fluidify_mobile/pages/report_page.dart';
import 'package:fluidify_mobile/pages/student/getpoint_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class FeedbackPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;
  final ButtonStatus state;
  const FeedbackPage({super.key, required this.subChapterId, required this.currentPoints, required this.state});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final Gemini gemini = Gemini.instance;

  String _studentAnswer = "";
  String _explorationLevel = "";
  int _mindMapScore = 0;
  String _essentialQuestion = "";
  String _feedbackPrompt = "";
  bool _isLoadFeedback = true;
  String _feedback = "";
  String _essentialFeedbackId = "";
  String _studentId = "";

  bool _showChatInput = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _followUpMessages = [];
  bool _isTypingFollowUp = false;

  @override
  void initState() {
    _fetchFeedbackPrompt();
    super.initState();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchFeedbackVariables() async {
    try {
      var studentId = _supabaseService.getCurrentUserId();
      if (studentId != null) {
        var essentialFeedbacks = await _supabaseService.getEssentialQuestionBySubChapter(widget.subChapterId);
        if (essentialFeedbacks != null) {
          var existingFeedback = await _supabaseService.getStudentFeedbacksByEssentialFeedbackId(essentialFeedbacks['id'], studentId);
          if (existingFeedback != null) {
            setState(() {
              _essentialQuestion = essentialFeedbacks['essential_question'];
              _studentAnswer = existingFeedback['student_answer'];
              _essentialFeedbackId = essentialFeedbacks['id'];

              log("existingFeedback : {${existingFeedback['ai_feedback']}}");
              if (existingFeedback['ai_feedback'] != null && existingFeedback['ai_feedback'].isNotEmpty) {
                _feedback = existingFeedback['ai_feedback'];
                _isLoadFeedback = false;
              }
            });
          }
        } else {
          log("No essential feedback found for subChapterId: ${widget.subChapterId}");
        }

        if (_feedback == "") {
          var materialData = await _supabaseService.getChatbotFlowBySubChapter(widget.subChapterId);
          if (materialData != null && materialData['id'] != null) {
            var explorationData = await _supabaseService.getStudentExplorationHistory(studentId, materialData['id']);
            if (explorationData != null && explorationData['exploration_level'] != null) {
              setState(() {
                _explorationLevel = explorationData['exploration_level'];
              });
            }
          } else {
            log("No chatbot flow found for subChapterId: ${widget.subChapterId}");
          }

          var mindMapData = await _supabaseService.getMindmapBySubChapter(widget.subChapterId);
          if (mindMapData != null && mindMapData['id'] != null) {
            final attemptData = await _supabaseService.getStudentMindmapAttempts(studentId, mindMapData['id']);
            if (attemptData != null && attemptData['score'] != null) {
              setState(() {
                _mindMapScore = attemptData['score'];
              });
            }
          } else {
            log("No mindmap found for subChapterId: ${widget.subChapterId}");
          }

          setState(() {
            _studentId = studentId;
          });
        } else {
          log("Feedback already exists for studentId: $studentId and essentialFeedbackId: $_essentialFeedbackId");
        }
      } else {
        log("No student ID found for current user.");
      }
    } catch (e) {
      log("Error fetching feedback variables: $e");
    }
  }

  Future<void> _fetchFeedbackPrompt() async {
    try {
      await _fetchFeedbackVariables();
      log("feedback : $_feedback, isloadfeedback : $_isLoadFeedback");
      if (_feedback == "" && _isLoadFeedback == true) {
        String? promptData = await _supabaseService.getPromptbySubChapter('', "feedback");
        log("Feedback variables - studentAnswer: $_studentAnswer, explorationLevel: $_explorationLevel, mindMapScore: $_mindMapScore, essentialQuestion: $_essentialQuestion");
        if (promptData != null && promptData.isNotEmpty && _isLoadFeedback) {
          promptData = promptData.replaceAll("{answer_simulation}", _studentAnswer);
          promptData = promptData.replaceAll("{exploration_level}", _explorationLevel);
          promptData = promptData.replaceAll("{mindmap_score}", _mindMapScore.toString());
          promptData = promptData.replaceAll("{simulation_question}", _essentialQuestion);
          log("Prompt : $promptData");

          setState(() {
            _feedbackPrompt = promptData!;
          });

          await _getAIFeedback();
          if (_feedback.isNotEmpty && _feedback != "") {
            await _saveFeedbackToDatabase();
            setState(() {
              _isLoadFeedback = false;
            });
          }
        } else {
          log("No feedback prompt found for subChapterId: ${widget.subChapterId}");
        }
      }
    } catch (e) {
      log("Error fetching feedback prompt: $e");
    }
  }

  Future<void> _getAIFeedback() async {
    try {
      if (_feedbackPrompt != "") {
        log("Complete Prompt: $_feedbackPrompt");

        final event = await gemini.prompt(parts: [Part.text(_feedbackPrompt)]);
        String? response = event?.output;

        if (response != null && response.isNotEmpty) {
          setState(() {
            _feedback += response;
          });
        }
      } else {
        log("No prompt found for subChapterId: ${widget.subChapterId}");
      }
    } catch (e) {
      log("error : $e");
    }
  }

  Future<void> _sendFollowUpQuestion(String questionText) async {
    if (questionText.trim().isEmpty) return;

    setState(() {
      _followUpMessages.add({"text": questionText, "isBot": false});
      _isTypingFollowUp = true;
      _showChatInput = false;
      _chatController.clear();
    });
    _scrollToBottom();

    try {
      String combinedContext = "Ini adalah riwayat feedback kamu sebelumnya:\n$_feedback\n\n";
      for (var msg in _followUpMessages) {
        if (msg['text'] != questionText) {
          String role = msg['isBot'] ? "Bot:" : "User:";
          combinedContext += "$role ${msg['text']}\n\n";
        }
      }

      combinedContext += "User bertanya: $questionText\n\nBerikan jawaban lanjutan yang membantu dan ramah.";

      final event = await gemini.prompt(parts: [Part.text(combinedContext)]);
      String? response = event?.output;

      if (response != null && response.isNotEmpty) {
        setState(() {
          _followUpMessages.add({"text": response, "isBot": true});
        });
      }
    } catch (e) {
      log("Error follow up: $e");
      setState(() {
        _followUpMessages.add({"text": "Maaf, sistem sedang kesulitan memproses pertanyaanmu. Coba lagi ya!", "isBot": true});
      });
    } finally {
      setState(() {
        _isTypingFollowUp = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveFeedbackToDatabase() async {
    try {
      if (_studentId != "" && _essentialFeedbackId != "") {
        await _supabaseService.updateStudentFeedbacks(_essentialFeedbackId, '', _feedback, _studentId);
      }
    } catch (e) {
      log("Error saving feedback to database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> paragraphs = _feedback.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.grey),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Fluidy Feedback",
              style: TextStyle(color: regularBlue, fontWeight: FontWeight.bold),
            ),
            if (widget.state == ButtonStatus.done)
              Text(
                "(Kamu sudah menyelesaikan level ini)",
                style: fRegularTextStyle.copyWith(fontSize: 12, color: softGray),
              )
          ],
        ),
        actions: [
          IconButton(
      icon: const Icon(Icons.report_problem_outlined, color: Colors.red),
      tooltip: 'Laporkan Masalah',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPage(
              reportedPage: 'Feedback Page',
              subChapterId: widget.subChapterId,
            ),
          ),
        );
      },
    ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Initial Feedback Loading
                if (_isLoadFeedback)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: FluidywithBubble(
                      text: "Sebentar ya, Fluidy sedang menyiapkan feedback untukmu...",
                      position: Bubbletail.left,
                      showMascot: true,
                    ),
                  )
                else
                  // 2. Tampilkan Feedback Awal per paragraf
                  ...paragraphs.asMap().entries.map((entry) {
                    int index = entry.key;
                    String paragraphText = entry.value;
                    bool isFirstBubble = index == 0;

                    return _buildBotBubble(paragraphText, isFirstBubble);
                  }),

                // 3. Tampilkan Riwayat Tanya Lebih Lanjut
                if (_followUpMessages.isNotEmpty)
                  ..._followUpMessages.map((msg) {
                    if (msg['isBot'] == true) {
                      return _buildBotBubble(msg['text'], true);
                    } else {
                      return _buildUserBubble(msg['text']);
                    }
                  }),

                // 4. Indikator bot sedang mengetik jawaban lanjutan
                if (_isTypingFollowUp)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: FluidywithBubble(
                      text: "...",
                      position: Bubbletail.left,
                      showMascot: true,
                    ),
                  ),
              ],
            ),
          ),
          if (!_isLoadFeedback && !_isTypingFollowUp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: _showChatInput
                  // Jika tombol 'Tanya Lebih Lanjut' sudah diklik, tampilkan Text Input
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: "Ketik pertanyaanmu...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.blueAccent),
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) => _sendFollowUpQuestion(value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendFollowUpQuestion(_chatController.text),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    )
                  // Jika belum diklik (atau balasan AI sudah masuk), tampilkan 2 Tombol Opsi
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.state != ButtonStatus.done)
                          FButtonWidget(
                            text: "Sudah Paham",
                            action: () async {
                              var studentId = _supabaseService.getCurrentUserId();
                              if (studentId != null) {
                                Map<String, int> currentProgressMap = await _supabaseService.getStudentLevelProgress(studentId);
                                int currentLevel = currentProgressMap[widget.subChapterId] ?? 0;

                                if (currentLevel < 4) {
                                  await _supabaseService.updateStudentLevelProgress(studentId, widget.subChapterId, 4);
                                }
                              }

                              var gainPoin = 100;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GetPointPage(
                                      title: "Ulasan Pembelajaran Berhasil Diselesaikan!",
                                      description: "Kamu mendapatkan $gainPoin poin dari menyelesaikan level ini.",
                                      pointsEarned: gainPoin,
                                      currentPoints: widget.currentPoints),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showChatInput = true;
                            });
                            _scrollToBottom();
                          },
                          child: const Text(
                            "Tanya Lebih Lanjut",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  // WIDGET BANTUAN UNTUK BUBBLE CHAT BOT
  Widget _buildBotBubble(String text, bool showMascot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMascot)
            const CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              backgroundImage: AssetImage('assets/img/fluidy_hello.png'),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                  topLeft: showMascot ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: SelectionArea(
                child: MarkdownBody(
                  data: text,
                  selectable: false,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.black, fontSize: 16, height: 1.5),
                    strong: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    <md.InlineSyntax>[md.EmojiSyntax(), LatexSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
                  ),
                  builders: {
                    'span': LatexBuilder(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BANTUAN UNTUK BUBBLE CHAT USER
  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 40.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(0), // Lancip di kanan bawah
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
