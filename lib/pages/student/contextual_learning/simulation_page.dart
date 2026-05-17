import 'dart:developer';
import 'package:fluidify_mobile/components/fluidy_bubble.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/studentopinion_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SimulationPage extends StatefulWidget {
  final String subChapterId;
  final int currentPoints;
  const SimulationPage({super.key, required this.subChapterId, required this.currentPoints});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _isVideoFinished = false;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroBottomSheet();
    });

    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _isVideoFinished = false;
    _isLoadingVideo = true;
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final videoData =
        await _supabaseService.getVideoBySubChapter(widget.subChapterId);

    if (videoData != null) {
      final videoUrl = videoData['video_url'] as String;
      final videoName = videoData['video_name'] as String;

      log("Berhasil memuat video: $videoName");

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _isLoadingVideo = false;
          });

          _videoController?.setLooping(false);
          _videoController?.play();

          _videoController?.addListener(() {
            if (!_videoController!.value.isInitialized) return;
            final value = _videoController!.value;
            log(value.toString());
            if (value.isPlaying == false && !_isVideoFinished) {
              setState(() {
                _isVideoFinished = true;
              });
            }
          });
        }).catchError((error) {
          log("Error initializing video: $error");
          setState(() {
            _isLoadingVideo = false;
          });
        });
    } else {
      setState(() {
        _isLoadingVideo = false;
      });
    }
  }

  void _showIntroBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Simulasi Pengenalan Fluida",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Pernah ga sih kamu bertanya kenapa .....",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 70),
              const FluidywithBubble(
                  text: "Perhatikan simulasi berikut dengan cermat ya!"),
              const SizedBox(height: 50),
              FButtonWidget(
                  text: "Berikutnya",
                  action: () {
                    Navigator.pop(context);
                  })
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Simulasi",
            style: fHeading3TextStyle.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingVideo
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : (_videoController != null &&
                        _videoController!.value.isInitialized)
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
                                  _initializeVideo();
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
                        child: Text(
                          "Gagal memuat video simulasi",
                          style: fMediumTextStyle.copyWith(color: Colors.white),
                        ),
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
                        builder: (context) => StudentOpinionPage(
                            subChapterId: widget.subChapterId, currentPoints: widget.currentPoints),
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
