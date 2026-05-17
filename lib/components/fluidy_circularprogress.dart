import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FluidyCircularProgression extends StatefulWidget {
  // Opsional: Tambahkan parameter ukuran agar bisa di-custom saat dipanggil
  final double size;

  const FluidyCircularProgression({
    super.key,
    this.size = 150.0, // Default ukuran 150x150
  });

  @override
  State<FluidyCircularProgression> createState() => _FluidyCircularProgressionState();
}

class _FluidyCircularProgressionState extends State<FluidyCircularProgression> {
  final String videoAssetPath = 'assets/videos/fluidy_loading.mp4';
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(videoAssetPath)
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();

        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // KITA BUANG POPSCOPE DAN SCAFFOLD
    return Center(
      child: _controller.value.isInitialized
          ? SizedBox(
              width: widget.size,
              height: widget.size, // Membatasi ukuran agar aman di dalam Column
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- LAYER 1: VIDEO MASKOT ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15), // Biar sudutnya manis
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),

                  // --- LAYER 2: TEKS ---
                  // Karena ini sekarang komponen kecil, mungkin teks panjang
                  // "Menyiapkan ruang belajar..." akan kebesaran.
                  // Saya sesuaikan posisinya agar proporsional.
                  Positioned(
                    bottom: 10.0,
                    left: 5,
                    right: 5,
                    child: Text(
                      "Loading...", // Teks dipersingkat karena areanya kecil
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.1, // Responsif terhadap ukuran widget
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              width: widget.size,
              height: widget.size,
            ),
    );
  }
}
