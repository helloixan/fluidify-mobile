import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/chat_messages.dart';
import 'package:flutter/material.dart';

class PreviewEksplorasiMateri extends StatefulWidget {
  final List<Map<String, dynamic>> flowData;

  const PreviewEksplorasiMateri({super.key, required this.flowData});

  @override
  State<PreviewEksplorasiMateri> createState() => _PreviewEksplorasiMateriState();
}

class _PreviewEksplorasiMateriState extends State<PreviewEksplorasiMateri> {
  Map<String, dynamic> chatData = {};
  List<ChatMessage> messages = [];
  String currentNode = "step_1";
  bool isTyping = false;
  bool isImageLoading = false;
  String? activeLoadingImageRef;
  double currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeChatData();
  }

  void _initializeChatData() {
    if (widget.flowData.isEmpty) {
      return;
    }

    Map<String, dynamic> mappedData = {};
    for (var node in widget.flowData) {
      mappedData[node['nodeId']] = node;
    }

    setState(() {
      chatData = mappedData;
      if (chatData.containsKey("step_1")) {
        currentNode = "step_1";
      } else {
        currentNode = chatData.keys.first;
      }
    });

    _loadNode(currentNode);
  }

  void _loadNode(String nodeId) async {
    if (nodeId == "end" || !chatData.containsKey(nodeId)) {
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

    if (!mounted) return;

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
      messages.insert(0, ChatMessage(text: option['text'], isBot: false));
      isTyping = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      isTyping = false;
      messages.insert(0, ChatMessage(text: option['reply'], isBot: true));
    });

    _loadNode(option['nextNode']);
  }

  @override
  Widget build(BuildContext context) {
    if (chatData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: appBackgroundColor,
          elevation: 0,
        ),
        body: const Center(child: Text("Belum ada data materi eksplorasi.")),
      );
    }

    var nodeData = chatData[currentNode];
    List<dynamic> currentOptions =
        nodeData != null && !isTyping ? nodeData['options'] ?? [] : [];

    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: appBackgroundColor,
        backgroundColor: appBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.grey),
        title: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: currentProgress,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blueAccent,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text("${(currentProgress * 100).toInt()}%", style: fMediumTextStyle.copyWith(color: regularBlue, fontSize: 12))
          ],
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
          if (!isTyping && !isImageLoading && currentNode == "end")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: FButtonWidget(
                text: "Tutup Pratinjau",
                action: () {
                  Navigator.pop(context);
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

  Widget _buildChatBubble(ChatMessage msg, bool showMascot, bool isLatestMessage) {
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