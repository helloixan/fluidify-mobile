import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PortalTransitionPage extends StatefulWidget {
  const PortalTransitionPage({super.key});

  @override
  State<PortalTransitionPage> createState() => _PortalTransitionPageState();
}

class _PortalTransitionPageState extends State<PortalTransitionPage> {
  late VideoPlayerController _videoController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset("assets/videos/portal_transition.mp4")
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController.play();
            }
          });

    _videoController.addListener(() {
      if (_videoController.value.isInitialized) {
        if (!_videoController.value.isPlaying &&
            _videoController.value.position >=
                _videoController.value.duration &&
            !_isTransitioning) {
          _isTransitioning = true;

          Navigator.pop(context, true);
        }
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _videoController.value.isInitialized
            // --- BAGIAN YANG DIUPDATE ---
            ? FractionallySizedBox(
                widthFactor:
                    0.85, // Set 0.85 artinya video mengambil 85% lebar layar. Bisa kamu kecilkan lagi jadi 0.7 atau 0.8 kalau masih kebesaran.
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
