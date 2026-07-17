import 'dart:io';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PreviewSimulasiPage extends StatefulWidget {
  final String? videoUrl;
  final String? videoPath;
  final String essentialQuestion;

  const PreviewSimulasiPage({
    super.key,
    this.videoUrl,
    this.videoPath,
    required this.essentialQuestion,
  });

  @override
  State<PreviewSimulasiPage> createState() => _PreviewSimulasiPageState();
}

class _PreviewSimulasiPageState extends State<PreviewSimulasiPage> {
  VideoPlayerController? _videoController;
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Prioritaskan file lokal (jika guru baru saja memilih video dari galeri)
    if (widget.videoPath != null && widget.videoPath!.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(widget.videoPath!))
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.addListener(_videoListener);
        });
    } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.addListener(_videoListener);
        });
    }
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (!_videoController!.value.isPlaying &&
          _videoController!.value.position >= _videoController!.value.duration &&
          !_isVideoFinished) {
        setState(() {
          _isVideoFinished = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        title: Text("Pratinjau Simulasi", style: fBoldTextStyle.copyWith(color: regularBlue)),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: (_videoController != null && _videoController!.value.isInitialized)
                ? Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController!.value.size.width,
                              height: _videoController!.value.size.height,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                        ),
                        if (_isVideoFinished)
                          GestureDetector(
                            onTap: () {
                              _videoController!.seekTo(Duration.zero);
                              _videoController!.play();
                              setState(() {
                                _isVideoFinished = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: const Icon(
                                Icons.replay,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: Text("Memuat video...", style: fMediumTextStyle.copyWith(color: Colors.grey)),
                  ),
          ),
          if (_isVideoFinished)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: FButtonWidget(
                  text: "Berikutnya",
                  action: () {
                    _videoController?.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviewPertanyaanPemantikPage(
                          essentialQuestion: widget.essentialQuestion,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _isVideoFinished = false;
                      });
                      _videoController?.seekTo(Duration.zero);
                    });
                  }),
            )
          else
            const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class PreviewPertanyaanPemantikPage extends StatelessWidget {
  final String essentialQuestion;

  const PreviewPertanyaanPemantikPage({super.key, required this.essentialQuestion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Pratinjau Pertanyaan Pemantik", style: fBoldTextStyle.copyWith(fontSize: 20, color: regularBlue)),
        centerTitle: true,
      ),
      backgroundColor: appBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: FluidywithBubble(
                text: essentialQuestion.isNotEmpty 
                    ? essentialQuestion 
                    : "Belum ada pertanyaan pemantik yang diisi.",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                enabled: false,
                maxLines: 10,
                minLines: 10,
                decoration: InputDecoration(
                  hintText: "Siswa akan mengetik jawabannya di sini...",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  disabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: FButtonWidget(
                text: "Tutup Pratinjau",
                action: () {
                  // Pop 2 kali untuk kembali ke halaman form kelola video
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}