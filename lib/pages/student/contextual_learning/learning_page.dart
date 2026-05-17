import 'dart:math';

import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/chat_messages.dart';
import 'package:fluidify_mobile/pages/student/getpoint_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class LearningPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;

  const LearningPage({super.key, required this.subChapterId, required this.currentPoints});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, dynamic> chatData = {};
  List<ChatMessage> messages = [];
  String currentNode = "step_1";
  bool isTyping = false;
  bool isLoading = true;
  bool isImageLoading = false;
  String materialId = "";

  String? activeLoadingImageRef;
  double currentProgress = 0.0;
  double score = 0.0;

  // 🔥 ADD: SCORING STATE
  double totalWeight = 0.0;
  int totalAnswered = 0;
  String finalLevel = "";

  bool isHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchChatbotData();
  }

  Future<void> _fetchChatbotData() async {
    final rawData =
        await _supabaseService.getChatbotFlowBySubChapter(widget.subChapterId);

    if (rawData != null) {
      Map<String, dynamic> mappedData = {};
      for (var node in rawData['flow_data']) {
        node['options'].shuffle(Random());
        mappedData[node['nodeId']] = node;
      }

      setState(() {
        chatData = mappedData;
        materialId = rawData['id'];
      });

      // 🔥 CEK HISTORY SEBELUM MEMULAI FLOW BARU
      var studentId = _supabaseService.getCurrentUserId();
      if (studentId != null) {
        final historyData = await _supabaseService.getStudentExplorationHistory(
            studentId, materialId);

        // Jika history ada, langsung load semua chat
        if (historyData != null && historyData['chat_history'] != null) {
          List<dynamic> rawHistory = historyData['chat_history'];

          setState(() {
            messages = rawHistory
                .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
                .toList();
            currentNode = "end";
            currentProgress = 1.0;
            score = (historyData['score'] ?? 0).toDouble();
            isHistoryLoaded = true;
            isLoading = false;
          });
          return; // Stop fungsi di sini, jangan panggil _loadNode()
        }
      }

      // Jika tidak ada history, jalankan flow normal
      setState(() {
        isLoading = false;
      });

      if (chatData.isNotEmpty) {
        _loadNode(currentNode);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _loadNode(String nodeId) async {
    if (nodeId == "end") {
      setState(() {
        currentNode = "end";
        currentProgress = 1.0;
      });
      return;
    }

    setState(() {
      isTyping = true;
      currentProgress = (chatData[nodeId]['progress'] as num).toDouble();
      currentNode = nodeId;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isTyping = false;

      String? imageRef = chatData[nodeId]['imageRef'];

      if (imageRef != null && imageRef.startsWith('http')) {
        activeLoadingImageRef = imageRef;
        isImageLoading = true;
      } else {
        activeLoadingImageRef = null;
        isImageLoading = false;
      }

      messages.insert(
        0,
        ChatMessage(
          text: chatData[nodeId]['botMessage'],
          isBot: true,
          imageRef: imageRef,
        ),
      );
    });
  }

  void _handleUserOption(Map<String, dynamic> option) async {
    setState(() {
      // 🔥 SCORING LOGIC
      double weight = (option['weight'] ?? 0).toDouble();
      totalWeight += weight;
      totalAnswered += 1;
      score = totalWeight / totalAnswered;

      messages.insert(0, ChatMessage(text: option['text'], isBot: false));
      isTyping = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      isTyping = false;
      messages.insert(0, ChatMessage(text: option['reply'], isBot: true));
    });

    _loadNode(option['nextNode']);
  }

  // 🔥 ADD: LEVEL CLASSIFICATION
  String _getLevel(double score) {
    if (score >= 0.8) return "strong_understanding";
    if (score >= 0.5) return "partial";
    if (score >= 0.2) return "misconception";
    return "naive";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: regularBlue,)),
      );
    }

    if (chatData.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Materi belum tersedia.")),
      );
    }

    var nodeData = chatData[currentNode];
    List<dynamic> currentOptions =
        nodeData != null && !isTyping ? nodeData['options'] : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.grey),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: currentProgress,
            backgroundColor: Colors.grey.shade300,
            color: Colors.blueAccent,
            minHeight: 8,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                bool isPreviousItemBot = false;

                if (index > 0) {
                  if (isTyping && index == 1) {
                    isPreviousItemBot = true;
                  } else {
                    int prevMsgIndex = isTyping ? (index - 2) : (index - 1);
                    isPreviousItemBot = messages[prevMsgIndex].isBot;
                  }
                }
                bool showMascot = (index == 0) || !isPreviousItemBot;

                if (isTyping && index == 0) {
                  return _buildTypingIndicator(showMascot);
                }

                final msg = messages[isTyping ? index - 1 : index];
                bool isLatestMessage = isTyping ? (index == 1) : (index == 0);

                return _buildChatBubble(msg, showMascot, isLatestMessage);
              },
            ),
          ),
          if (!isTyping && !isImageLoading && currentNode == "end" && !isHistoryLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: FButtonWidget(
                text: "Berikutnya",
                action: () async {
                  var studentId = _supabaseService.getCurrentUserId();
                  var gainPoin = (score * 100).floor();

                  if (studentId != null) {
                    // 🔥 Hanya lakukan UPSERT jika ini adalah flow baru (bukan load history)
                    if (!isHistoryLoaded) {
                      finalLevel = _getLevel(score);

                      // Convert list of ChatMessage ke bentuk JSON array
                      List<Map<String, dynamic>> chatHistoryJson =
                          messages.map((m) => m.toMap()).toList();

                      await _supabaseService.upsertStudentExplorationScore(
                          studentId,
                          score,
                          materialId,
                          finalLevel,
                          chatHistoryJson);

                      Map<String, int> currentProgressMap =
                          await _supabaseService
                              .getStudentLevelProgress(studentId);
                      int currentLevel =
                          currentProgressMap[widget.subChapterId] ?? 0;

                      if (currentLevel < 2) {
                        await _supabaseService.updateStudentLevelProgress(
                            studentId, widget.subChapterId, 2);
                      }
                    }
                  }

                  // Lanjut ke GetPointPage (kamu bisa modifikasi jika load history ingin ke page lain)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GetPointPage(
                          title: "Eksplorasi Materi Berhasil Diselesaikan!",
                          description: "Kamu mendapatkan $gainPoin poin dari menyelesaikan materi ini.",
                          pointsEarned: gainPoin, // Jangan kasih poin lagi kalau cuma review
                          currentPoints: widget.currentPoints),
                    ),
                  );
                },
              ),
            )
          else if (!isTyping && !isImageLoading && currentOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const Text("Pilih tanggapan kamu",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  ...currentOptions.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => _handleUserOption(option),
                          child: Text(
                            option['text'],
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
      ChatMessage msg, bool showMascot, bool isLatestMessage) {
    if (msg.isBot) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FluidywithBubble(
              text: msg.text,
              position: Bubbletail.left,
              showMascot: showMascot,
            ),
            if (msg.imageRef != null && msg.imageRef!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(left: 130.0, top: 4.0, right: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: msg.imageRef!.startsWith('http')
                      ? Image.network(
                          msg.imageRef!,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              if (isLatestMessage &&
                                  activeLoadingImageRef == msg.imageRef) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted &&
                                      activeLoadingImageRef == msg.imageRef) {
                                    setState(() {
                                      activeLoadingImageRef = null;
                                      isImageLoading = false;
                                    });
                                  }
                                });
                              }
                              return child;
                            }

                            double value = progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : 0.0;

                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey.shade100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: value > 0 ? value : null,
                                    color: regularBlue,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${(value * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: regularBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (isLatestMessage &&
                                activeLoadingImageRef == msg.imageRef) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    activeLoadingImageRef == msg.imageRef) {
                                  setState(() {
                                    activeLoadingImageRef = null;
                                    isImageLoading = false;
                                  });
                                }
                              });
                            }
                            return Container(
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Image.asset(msg.imageRef!),
                ),
              )
          ],
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }
  }

  Widget _buildTypingIndicator(bool showMascot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FluidywithBubble(
        text: "...",
        position: Bubbletail.left,
        showMascot: showMascot,
      ),
    );
  }
}
