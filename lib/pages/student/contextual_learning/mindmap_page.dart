import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/student/getpoint_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:developer' as dev;

class MindMapNode {
  final String sequence;
  final String subject;
  final List<MindMapNode> children = [];

  MindMapNode({required this.sequence, required this.subject});

  int get leafCount => children.isEmpty
      ? 1
      : children.fold(0, (sum, child) => sum + child.leafCount);

  double get treeWidth => leafCount * 140.0;
}

class MindMapPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;
  const MindMapPage(
      {super.key, required this.subChapterId, required this.currentPoints});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, String> userAnswers = {};
  String? activeSequence;

  Map<String, MindMapNode> nodesMap = {};
  MindMapNode? rootNode;

  List<String> options = [];
  String? mindMapId;
  int attempts = 0;
  bool isAlreadySolved = false;

  @override
  void initState() {
    super.initState();
    loadMindmap();
  }

  Future<void> loadMindmap() async {
    final data =
        await _supabaseService.getMindmapBySubChapter(widget.subChapterId);
    dev.log("MINDMAP DATA: $data");

    if (data == null) return;
    mindMapId = data['id'];
    final rawSubjects = List<Map<String, dynamic>>.from(data['subjects']);

    List<Map<String, dynamic>> validNodesData =
        rawSubjects.where((e) => e['sequence'] != 0).toList();

    validNodesData.sort((a, b) => a['sequence']
        .toString()
        .length
        .compareTo(b['sequence'].toString().length));

    nodesMap.clear();

    for (var d in validNodesData) {
      String seq = d['sequence'].toString();

      if (seq.endsWith('.0')) seq = seq.substring(0, seq.length - 2);

      var node = MindMapNode(sequence: seq, subject: d['subject']);
      nodesMap[seq] = node;

      if (seq == "1") {
        rootNode = node;
      } else {
        String parentSeq = "";
        for (var existingSeq in nodesMap.keys) {
          if (seq.startsWith(existingSeq) && seq != existingSeq) {
            if (existingSeq.length > parentSeq.length) {
              parentSeq = existingSeq;
            }
          }
        }
        if (parentSeq.isNotEmpty) {
          nodesMap[parentSeq]!.children.add(node);
        }
      }
    }

    final optionItems =
        rawSubjects.where((e) => e['sequence'].toString() != "1").toList();
    options = optionItems.map((e) => e['subject'] as String).toList();
    options.shuffle(Random());

    final studentId = _supabaseService.getCurrentUserId();
    if (studentId != null && mindMapId != null) {
      final attemptData = await _supabaseService.getStudentMindmapAttempts(
          studentId, mindMapId!);
      if (attemptData != null) {
        attempts = attemptData['attempts'] ?? 0;
        if (attemptData['result'] == 'benar') {
          isAlreadySolved = true;
        }
      }
    }

    if (isAlreadySolved) {
      for (var seq in nodesMap.keys) {
        if (seq != "1") {
          userAnswers[seq] = nodesMap[seq]!.subject; // Isi dengan jawaban benar
        }
      }
      activeSequence = null; // Tidak ada node yang aktif/fokus
    } else {
      activeSequence = _findNextEmptyNode();
    }
    setState(() {});
  }

  String? _findNextEmptyNode() {
    for (var seq in nodesMap.keys) {
      if (seq != "1" && userAnswers[seq] == null) return seq;
    }
    return null;
  }

  List<String> _getCorrectEdges(MindMapNode node) {
    List<String> edges = [];
    for (var child in node.children) {
      edges.add("${node.subject}|${child.subject}");
      edges.addAll(_getCorrectEdges(child));
    }
    return edges;
  }

  List<String> _getUserEdges(MindMapNode node) {
    List<String> edges = [];
    String nodeSubject = node.sequence == "1"
        ? node.subject
        : (userAnswers[node.sequence] ?? "");
    for (var child in node.children) {
      String childSubject = userAnswers[child.sequence] ?? "";
      edges.add("$nodeSubject|$childSubject");
      edges.addAll(_getUserEdges(child));
    }
    return edges;
  }

  void checkAnswer() async {
    if (rootNode == null) return;

    List<String> correctEdges = _getCorrectEdges(rootNode!);
    List<String> userEdges = _getUserEdges(rootNode!);

    int correctCount = 0;
    List<String> remainingCorrectEdges = List.from(correctEdges);

    for (var uEdge in userEdges) {
      if (remainingCorrectEdges.contains(uEdge)) {
        correctCount++;
        remainingCorrectEdges.remove(uEdge);
      }
    }

    int totalEdges = nodesMap.length - 1;
    int wrongCount = totalEdges - correctCount;

    bool isCorrect = (wrongCount == 0);
    attempts++;

    var studentId = _supabaseService.getCurrentUserId();
    if (studentId != null && mindMapId != null) {
      var score = 0;
      if (isCorrect) {
        score = calculateNodeScore(attempts);
      }
      await _supabaseService.upsertStudentMindmapAttempts(
        studentId,
        attempts,
        isCorrect ? "benar" : "salah",
        mindMapId!,
        score,
      );
    }

    if (isCorrect) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: correctGreen, width: 2),
          ),
          backgroundColor: Colors.white,
          title: Text("Jawaban Benar!",
              style: fBoldTextStyle.copyWith(color: correctGreen)),
          content: SizedBox(
              height: 250,
              width: 200,
              child: Image.asset('assets/img/fluidy_happy.png')),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      var gainPoin = calculateNodeScore(attempts);
      if (mounted) {
        var studentId = _supabaseService.getCurrentUserId();
        if (studentId != null) {
          Map<String, int> currentProgressMap =
              await _supabaseService.getStudentLevelProgress(studentId);
          int currentLevel = currentProgressMap[widget.subChapterId] ?? 0;

          if (currentLevel < 3) {
            await _supabaseService.updateStudentLevelProgress(
                studentId, widget.subChapterId, 3);
          }
        }

        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GetPointPage(
                title: "Pemetaan Konsep Berhasil Diselesaikan!",
                description:
                    "Kamu mendapatkan $gainPoin poin dari menyelesaikan level ini.",
                pointsEarned: gainPoin,
                currentPoints: widget.currentPoints),
          ),
        );
      }
    } else {
      String message;
      if (wrongCount == totalEdges) {
        message = "Semua pemetaan materi masih belum tepat";
      } else {
        message = "$wrongCount alur cabang masih belum tepat nih";
      }

      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: darkRed, width: 2),
          ),
          backgroundColor: Colors.white,
          title: Text("Jawaban Salah",
              style: fBoldTextStyle.copyWith(color: darkRed)),
          content: FluidywithBubble(
            text: message,
            maskotPath: "assets/img/fluidy_confuse.png",
            maskotSize: 100,
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  userAnswers.clear();
                  activeSequence = _findNextEmptyNode();
                });
              },
              child: Text(
                "Coba Lagi",
                style: fSemiBoldTextStyle.copyWith(color: Colors.white),
              ),
            )
          ],
        ),
      );
    }
  }

  int calculateNodeScore(int attempts) {
    if (attempts == 1) return 100;
    if (attempts == 2) return 80;
    if (attempts == 3) return 60;
    if (attempts == 4) return 40;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    bool fullFilled =
        (userAnswers.length == nodesMap.length - 1) && (nodesMap.length > 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FluidywithBubble(
                text:
                    "Berdasarkan apa yang kamu pelajari, yuk susun rangkuman kamu dalam mind map berikut",
                maskotPath: "assets/img/fluidy_pencil.png",
                maskotSize: 100,
              ),
            ),

            Expanded(
              flex: isAlreadySolved ? 3 : 2,
              child: rootNode == null
                  ? const Center(child: CircularProgressIndicator(color: regularBlue,))
                  : Stack(
                      children: [
                        // Area Kanvas Graf
                        Positioned.fill(
                          child: InteractiveViewer(
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(80),
                            minScale: 0.1,
                            maxScale: 2.0,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildTree(rootNode!),
                            ),
                          ),
                        ),
                        // Overlay Indikator Geser (Kanan Bawah)
                        Positioned(
                          bottom: 10,
                          right: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pan_tool_alt_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Geser & Zoom",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            /// OPSI JAWABAN & TOMBOL SIMPAN FIX DI BAWAH (DITAMBAH SCROLLBAR)
            if (!isAlreadySolved)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, -2))
                    ],
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                child: Column(
                  children: [
                    // AREA OPSI SCROLLABLE DENGAN SCROLLBAR
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility:
                            true, // Membuat indikator selalu terlihat
                        thickness: 6,
                        radius: const Radius.circular(10),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                              right:
                                  20), // Beri jarak agar scrollbar tidak menimpa button
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: options.map((option) {
                              bool isSelected =
                                  userAnswers.values.contains(option);
                              return OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: const BorderSide(color: darkBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: isSelected
                                      ? darkBlue.withOpacity(0.1)
                                      : Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (activeSequence != null) {
                                      userAnswers.removeWhere(
                                          (key, value) => value == option);
                                      userAnswers[activeSequence!] = option;
                                      activeSequence = _findNextEmptyNode() ??
                                          activeSequence;
                                    }
                                  });
                                },
                                child: Text(
                                  option,
                                  style: fSemiBoldTextStyle.copyWith(
                                      color: darkBlue),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // TOMBOL SIMPAN STATIS DI BAWAH
                    if (fullFilled)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: FButtonWidget(
                          text: "Simpan Jawaban",
                          action: checkAnswer,
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// RECURSIVE WIDGET UNTUK MENGGAMBAR GRAF
  Widget _buildTree(MindMapNode node) {
    bool isRoot = node.sequence == "1";
    bool isActive = activeSequence == node.sequence;
    String? answer = userAnswers[node.sequence];

    Widget nodeUI = GestureDetector(
      onTap:
          (isRoot||isAlreadySolved) ? null : () => setState(() => activeSequence = node.sequence),
      child: Container(
        width: 120,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isRoot ? darkBlue : Colors.white,
          border: isRoot
              ? null
              : Border.all(
                  color: isActive ? darkBlue : Colors.grey.shade400,
                  width: isActive ? 2 : 1,
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isRoot ? node.subject : (answer ?? ". . ."),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isRoot
                ? Colors.white
                : (answer != null ? darkBlue : Colors.grey),
            fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );

    if (node.children.isEmpty) {
      return SizedBox(
        width: node.treeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [nodeUI],
        ),
      );
    }

    return SizedBox(
      width: node.treeWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          nodeUI,
          CustomPaint(
            size: Size(node.treeWidth, 40),
            painter: DynamicMindMapPainter(node),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children.map((child) => _buildTree(child)).toList(),
          ),
        ],
      ),
    );
  }
}

class DynamicMindMapPainter extends CustomPainter {
  final MindMapNode parentNode;

  DynamicMindMapPainter(this.parentNode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(size.width / 2, 0);

    double currentX = 0;

    for (var child in parentNode.children) {
      double childAreaWidth = child.treeWidth;
      double childCenterX = currentX + (childAreaWidth / 2);

      canvas.drawLine(startPoint, Offset(childCenterX, size.height), paint);
      currentX += childAreaWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
