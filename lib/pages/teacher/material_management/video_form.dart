import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluidify_mobile/components/fluidy_button.dart';
import 'package:fluidify_mobile/components/fluidy_outlinebutton.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/components/confirmation_dialog.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoFormPage extends StatefulWidget {
  final String subchapterId;

  const VideoFormPage({super.key, required this.subchapterId});

  @override
  State<VideoFormPage> createState() => _VideoFormPageState();
}

class _VideoFormPageState extends State<VideoFormPage> {
  SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _videoNameController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _essentialQuestionController = TextEditingController();
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic>? _video;
  VideoPlayerController? _videoPlayerController;
  String? _essentialFeedbackId;
  bool _showVideoControls = false;
  PlatformFile? _videoFile;

  @override
  void initState() {
    super.initState();
    computeVideo();
  }

  Future<void> computeVideo() async {
    var data = await _supabaseService.getVideoBySubchapterId(widget.subchapterId);
    await _fetchEssentialQuestion();
    if (data != null) {
      setState(() {
        _video = data;
        _videoNameController.text = data['video_name'];
      });
      if (data['video_url'] != null) {
        setState(() {
          _videoUrlController.text = data['video_url'];
        });
        _initializeVideo(data['video_url']);
      }
    } else {
      setState(() {
        isEditing = true;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchEssentialQuestion() async {
    var essentialFeedbacks = await _supabaseService.getEssentialQuestionBySubChapter(widget.subchapterId);
    setState(() {
      if (essentialFeedbacks != null) {
        _essentialQuestionController.text = essentialFeedbacks['essential_question'];
        _essentialFeedbackId = essentialFeedbacks['id'];
      }
    });
  }

  Future<void> _initializeVideo(String url) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.addListener(() {
          if (mounted) setState(() {});
        });
      }).catchError((error) {
        log("Error initializing video: $error");
      });
  }

  Future<void> _initializeLocalVideo(String path) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.addListener(() {
          if (mounted) setState(() {});
        });
      }).catchError((error) {
        log("Error initializing local video: $error");
      });
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: false, type: FileType.custom, allowedExtensions: ['mp4']);

      if (result != null) {
        setState(() {
          _videoFile = result.files.first;
        });
        if (_videoFile!.path != null) {
          _initializeLocalVideo(_videoFile!.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal Mengambil Video dari Galeri')),
        );
      }
    }
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) {
        return FConfirmationDialog(
          title: "Hapus Video",
          content: "Apakah Anda yakin ingin menghapus video ini dari materi?",
          action: () async {
            try {
              if (_videoUrlController.text.trim().isNotEmpty) {
                await _supabaseService.deleteVideofromTable(_video!['id'], _videoUrlController.text);
                setState(() {
                  _videoPlayerController?.dispose();
                  _videoPlayerController = null;
                  _videoUrlController.clear();
                  _videoFile = null;
                });
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Berhasil menghapus video untuk materi ini!'), backgroundColor: Colors.lightGreenAccent),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menghapus video : ${e.toString()}')),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _saveData() async {
    try {
      if (_videoNameController.text.trim().isNotEmpty && _videoFile != null) {
        var videoName = _videoNameController.text;
        var videoPath = _videoFile!.path!;
        if (_video == null) {
          await _supabaseService.insertVideo(widget.subchapterId, videoName, videoPath);
        } else if (_videoUrlController.text.trim().isNotEmpty) {
          await _supabaseService.updateVideoSimulation(_video!['id'], videoName, videoPath, _videoUrlController.text);
        }
        setState(() {
          isLoading = true;
          _videoFile = null;
        });
        await computeVideo();
      } else if (_videoNameController.text.trim().isEmpty || _videoUrlController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Judul Video dan Video tidak boleh kosong!'), backgroundColor: warningColor),
          );
        }
      }
      if (_essentialQuestionController.text.trim().isNotEmpty) {
        await _supabaseService.upsertEssentialQuestion(widget.subchapterId, _essentialQuestionController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data video: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Kelola Video",
            style: fBoldTextStyle.copyWith(color: regularBlue),
          ),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: regularBlue))
            : Padding(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 25),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Judul Video", style: fHeading3TextStyle),
                        const SizedBox(height: 10),
                        TextFormField(
                            enabled: isEditing,
                            minLines: 1,
                            maxLines: 2,
                            controller: _videoNameController,
                            cursorColor: regularBlue,
                            decoration: InputDecoration(
                                labelStyle: fSemiBoldTextStyle.copyWith(color: Colors.black, fontSize: 14),
                                floatingLabelStyle: fBoldTextStyle.copyWith(color: Colors.black),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: Colors.black),
                                ),
                                focusColor: Colors.black,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: regularBlue),
                                ))),
                        const SizedBox(height: 10),
                        Text("URL Video Tersimpan", style: fHeading3TextStyle),
                        const SizedBox(height: 10),
                        TextFormField(
                            enabled: false,
                            minLines: 1,
                            maxLines: 2,
                            controller: _videoUrlController,
                            cursorColor: regularBlue,
                            decoration: InputDecoration(
                                labelStyle: fSemiBoldTextStyle.copyWith(color: Colors.black, fontSize: 14),
                                floatingLabelStyle: fBoldTextStyle.copyWith(color: Colors.black),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: Colors.black),
                                ),
                                focusColor: Colors.black,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: regularBlue),
                                ))),
                        const SizedBox(height: 10),
                        Text("Pratinjau Video", style: fHeading3TextStyle),
                        const SizedBox(height: 10),
                        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showVideoControls = !_showVideoControls;
                              });
                            },
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.black,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                                    child: VideoPlayer(_videoPlayerController!),
                                  ),
                                  if (!_videoPlayerController!.value.isPlaying || _showVideoControls)
                                    IconButton(
                                      icon: Icon(
                                        _videoPlayerController!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration ? Icons.replay_circle_filled : Icons.play_circle_filled),
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_videoPlayerController!.value.isPlaying) {
                                            _videoPlayerController!.pause();
                                          } else if (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration) {
                                            _videoPlayerController!.seekTo(Duration.zero);
                                            _videoPlayerController!.play();
                                          } else {
                                            _videoPlayerController!.play();
                                          }
                                          if (_videoPlayerController!.value.isPlaying) {
                                            _showVideoControls = false;
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          )
                        else if (_videoUrlController.text.isNotEmpty)
                          Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: CircularProgressIndicator(color: regularBlue)))
                        else if (_videoFile != null)
                          Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: CircularProgressIndicator(color: regularBlue)))
                        else
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Tidak ada pratinjau video",
                                style: fMediumTextStyle.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: FButtonWidget(
                                  icon: Icons.upload_file,
                                  text: "Upload Video",
                                  action: _pickVideo,
                                ),
                              ),
                              if (_videoUrlController.text.trim().isNotEmpty && _videoPlayerController != null) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FOutlinedButton(
                                    icon: Icons.delete,
                                    text: "Hapus Video",
                                    action: _deleteVideo,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 10),
                        Text("Pertanyaan Pemantik", style: fHeading3TextStyle),
                        const SizedBox(height: 10),
                        TextFormField(
                            enabled: isEditing,
                            minLines: 1,
                            maxLines: 8,
                            controller: _essentialQuestionController,
                            cursorColor: regularBlue,
                            decoration: InputDecoration(
                                labelStyle: fSemiBoldTextStyle.copyWith(color: Colors.black, fontSize: 14),
                                floatingLabelStyle: fBoldTextStyle.copyWith(color: Colors.black),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: Colors.black),
                                ),
                                focusColor: Colors.black,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0, color: regularBlue),
                                ))),
                      ],
                    ),
                  ),
                  if (!isEditing)
                    FButtonWidget(
                        icon: Icons.edit,
                        text: "Edit",
                        action: () {
                          setState(() {
                            isEditing = true;
                          });
                        })
                  else
                    Row(
                      mainAxisAlignment: _video != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                      children: [
                        if (_video != null)
                          SizedBox(
                            width: AppSize.screenWidth(context) * 0.45,
                            child: FOutlinedButton(
                                icon: Icons.cancel,
                                text: "Batal",
                                action: () {
                                  setState(() {
                                    isEditing = false;
                                  });
                                }),
                          ),
                        if (_video != null) const SizedBox(width: 10),
                        SizedBox(
                          width: _video != null ? AppSize.screenWidth(context) * 0.45 : AppSize.screenWidth(context) * 0.9,
                          child: FButtonWidget(
                              icon: Icons.save,
                              text: "Simpan",
                              action: () async {
                                await _saveData();
                                setState(() {
                                  isEditing = false;
                                });
                              }),
                        ),
                      ],
                    ),
                ]),
              ));
  }
}
