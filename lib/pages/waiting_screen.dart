import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoLoadingPage extends StatefulWidget {
  final String videoAssetPath;

  const VideoLoadingPage({super.key, required this.videoAssetPath});

  @override
  State<VideoLoadingPage> createState() => _VideoLoadingPageState();
}

class _VideoLoadingPageState extends State<VideoLoadingPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi video dari path asset yang dikirim melalui parameter
    _controller = VideoPlayerController.asset(widget.videoAssetPath)
      ..initialize().then((_) {
        // Play video dan buat looping (berulang)
        _controller.setLooping(true);
        _controller.play();
        // Update state setelah video berhasil diinisialisasi
        setState(() {});
      });
  }

  @override
  void dispose() {
    // Pastikan controller dihapus dari memori saat halaman ditutup
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope (atau WillPopScope di Flutter versi lama) mencegah user
    // menekan tombol back device saat proses loading berlangsung
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white, // Sesuai dengan background videomu
        body: Center(
          child: _controller.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit
                        .cover, // Membuat video memenuhi layar vertikal 9:16
                    child: SizedBox(
                      width: _controller.value.size.width * 0.8,
                      height: _controller.value.size.height * 0.8,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const CircularProgressIndicator(
                  color: Colors
                      .blue), // Indikator loading sementara video disiapkan
        ),
      ),
    );
  }
}
