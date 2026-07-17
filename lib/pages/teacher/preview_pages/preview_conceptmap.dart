import 'dart:math';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class PreviewMindMapNode {
  final String sequence;
  final String subject;
  final List<PreviewMindMapNode> children = [];

  PreviewMindMapNode({required this.sequence, required this.subject});

  int get leafCount => children.isEmpty
      ? 1
      : children.fold(0, (sum, child) => sum + child.leafCount);

  double get treeWidth => leafCount * 140.0;
}

class PreviewConceptmap extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;

  const PreviewConceptmap({super.key, required this.subjects});

  @override
  State<PreviewConceptmap> createState() => _PreviewConceptmapState();
}

class _PreviewConceptmapState extends State<PreviewConceptmap> {
  Map<String, String> userAnswers = {};
  String? activeSequence;

  Map<String, PreviewMindMapNode> nodesMap = {};
  PreviewMindMapNode? rootNode;

  List<String> options = [];

  @override
  void initState() {
    super.initState();
    _loadMindmap();
  }

  void _loadMindmap() {
    if (widget.subjects.isEmpty) return;

    // Filter subject valid (sequence == 0 adalah pengecoh/distractor)
    List<Map<String, dynamic>> validNodesData =
        widget.subjects.where((e) => e['sequence'] != 0).toList();

    validNodesData.sort((a, b) => a['sequence']
        .toString()
        .length
        .compareTo(b['sequence'].toString().length));

    nodesMap.clear();

    for (var d in validNodesData) {
      String seq = d['sequence'].toString();
      // Hapus format .0 jika terbaca sebagai double dari form
      if (seq.endsWith('.0')) seq = seq.substring(0, seq.length - 2);

      var node = PreviewMindMapNode(sequence: seq, subject: d['subject']);
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

    // Options termasuk distractor, asalkan sequence-nya bukan 1 (bukan akar/root)
    final optionItems =
        widget.subjects.where((e) => e['sequence'].toString() != "1" && e['sequence'].toString() != "1.0").toList();
    options = optionItems.map((e) => e['subject'] as String).toList();
    options.shuffle(Random());

    activeSequence = _findNextEmptyNode();
    setState(() {});
  }

  String? _findNextEmptyNode() {
    for (var seq in nodesMap.keys) {
      if (seq != "1" && userAnswers[seq] == null) return seq;
    }
    return null;
  }

  List<String> _getCorrectEdges(PreviewMindMapNode node) {
    List<String> edges = [];
    for (var child in node.children) {
      edges.add("${node.subject}|${child.subject}");
      edges.addAll(_getCorrectEdges(child));
    }
    return edges;
  }

  List<String> _getUserEdges(PreviewMindMapNode node) {
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

  void _checkAnswer() {
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

    if (isCorrect) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: correctGreen, width: 2),
          ),
          backgroundColor: Colors.white,
          title: Text("Jawaban Benar!",
              style: fBoldTextStyle.copyWith(color: correctGreen)),
          content: SizedBox(
              height: 250,
              width: 200,
              child: Image.asset('assets/img/fluidy_happy.png')),
          actions: [
             FButtonWidget(
                text: "Tutup Pratinjau",
                action: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Tutup halaman pratinjau
                },
             )
          ]
        ),
      );
    } else {
      String message = wrongCount == totalEdges
          ? "Semua pemetaan materi masih belum tepat"
          : "$wrongCount alur cabang masih belum tepat nih";

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkRed, width: 2),
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

  @override
  Widget build(BuildContext context) {
    bool fullFilled =
        (userAnswers.length == nodesMap.length - 1) && (nodesMap.length > 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        title: Text("Pratinjau Concept Map", style: fBoldTextStyle.copyWith(fontSize: 20, color: regularBlue)),
        centerTitle: true,
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
              flex: 2,
              child: rootNode == null
                  ? const Center(child: Text("Belum ada data materi concept map.", style: TextStyle(color: Colors.grey)))
                  : Stack(
                      children: [
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
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(10),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 20),
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

                    if (fullFilled)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: FButtonWidget(
                          text: "Cek Jawaban",
                          action: _checkAnswer,
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

  Widget _buildTree(PreviewMindMapNode node) {
    bool isRoot = node.sequence == "1";
    bool isActive = activeSequence == node.sequence;
    String? answer = userAnswers[node.sequence];

    Widget nodeUI = GestureDetector(
      onTap:
          isRoot ? null : () => setState(() => activeSequence = node.sequence),
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
            painter: PreviewDynamicMindMapPainter(node),
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

class PreviewDynamicMindMapPainter extends CustomPainter {
  final PreviewMindMapNode parentNode;

  PreviewDynamicMindMapPainter(this.parentNode);

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
