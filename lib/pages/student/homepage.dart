import 'dart:developer';

import 'package:fluidify_mobile/components/chapter_box.dart';
import 'package:fluidify_mobile/components/level_button.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/feedback_page.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/learning_page.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/mindmap_page.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/quiz_page.dart';
import 'package:fluidify_mobile/pages/student/contextual_learning/simulation_page.dart';
import 'package:fluidify_mobile/pages/student/portaltransition_page.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> chapters = [];
  Map<String, dynamic> gamificationData = {};
  Map<String, int> userProgressMap = {};
  int currentChapterIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    computeGamificationData();
    computeChapters();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> computeGamificationData() async {
    var studentId = _supabaseService.getCurrentUserId();
    if (studentId != null) {
      // Ambil data progress user terlebih dahulu
      userProgressMap = await _supabaseService.getStudentLevelProgress(studentId);
      if (userProgressMap.isNotEmpty) {
        int totalDone = 0;
        userProgressMap.forEach((key, value) {
          totalDone += (value == 6) ? 5 : value;
        });

        _supabaseService.upsertUserLevelsDone(studentId, totalDone);
      }

      var data = await _supabaseService.getStudentGamificationData(studentId);
      if (data != null) {
        setState(() {
          gamificationData = data;
        });
      }
    } else {
      log("User ID Not Found");
    }
  }

  Future<void> computeChapters() async {
    // Ambil data chapters
    var data = await _supabaseService.getAllChapters();
    if (data != null) {
      setState(() {
        chapters = data;
      });
    }
    computeLevels();
  }

  void computeLevels() {
    for (var chapter in chapters) {
      if (chapter['subchapters'] != null) {
        for (var subchapter in chapter['subchapters']) {
          String subId = subchapter["subchapter_id"];

          bool isSubchapterActive = userProgressMap.containsKey(subId);
          int currentLevelIndex = isSubchapterActive ? userProgressMap[subId]! : 0;

          ButtonStatus getStatus(int index) {
            if (!isSubchapterActive) {
              return ButtonStatus.locked;
            }
            if (index < currentLevelIndex) return ButtonStatus.done;
            if (index == currentLevelIndex) return ButtonStatus.active;
            return ButtonStatus.locked;
          }

          setState(() {
            subchapter["levels"] = [
              {"icon": Icons.play_arrow_rounded, "navigateTo": SimulationPage(subChapterId: subId, currentPoints: gamificationData['total_points'] ?? 0), "state": getStatus(0), "position": 0.45},
              {"icon": Icons.search_rounded, "navigateTo": LearningPage(subChapterId: subId, currentPoints: gamificationData['total_points'] ?? 0), "state": getStatus(1), "position": 0.30},
              {"icon": Icons.edit_rounded, "navigateTo": MindMapPage(subChapterId: subId, currentPoints: gamificationData['total_points'] ?? 0), "state": getStatus(2), "position": 0.15},
              {
                "icon": Icons.lightbulb,
                "navigateTo": FeedbackPage(subChapterId: subId, currentPoints: gamificationData['total_points'] ?? 0, state: getStatus(3)),
                "state": getStatus(3),
                "position": 0.30
              },
              {"icon": Icons.question_mark_rounded, "navigateTo": QuizPage(subChapterId: subId, currentPoints: gamificationData['total_points'] ?? 0, type: "ctl"), "state": getStatus(4), "position": 0.45},
            ];
          });
        }
      }
    }
  }

  AssetImage getTreasureImage(int progress) {
    if (progress == 5) {
      return const AssetImage("assets/img/treasure_active.png");
    } else if (progress < 5) {
      return const AssetImage("assets/img/treasure_passive.png");
    } else {
      return const AssetImage("assets/img/custom_icons/chest_opened.png");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gamificationData.isNotEmpty
          ? AppBar(
              centerTitle: true,
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.5),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: correctGreen),
                      const SizedBox(width: 8),
                      Text("${gamificationData['levels_done']} levels", style: fMediumTextStyle.copyWith(color: correctGreen, fontSize: 21)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(streakIcon, color: darkOrange),
                      const SizedBox(width: 8),
                      Text("${gamificationData['current_streak']} streak", style: fMediumTextStyle.copyWith(color: darkOrange, fontSize: 21)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: lightBlue),
                      const SizedBox(width: 8),
                      Text("${gamificationData['total_points']} pts", style: fMediumTextStyle.copyWith(color: lightBlue, fontSize: 21)),
                    ],
                  ),
                ],
              ),
            )
          : AppBar(
              centerTitle: true,
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.5),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text("Fluidify", style: fSemiBoldTextStyle.copyWith(color: regularBlue)),
            ),
      backgroundColor: Colors.white,
      body: chapters.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.blue,
            ))
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (currentChapterIndex > 0)
                    InkWell(
                      onTap: () async {
                        // Panggil halaman transisi dengan animasi Fade
                        final bool? isTransitionDone = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const PortalTransitionPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );

                        // Jika video selesai dan mengembalikan "true", baru update state
                        if (isTransitionDone == true) {
                          setState(() {
                            currentChapterIndex--;
                          });
                          _scrollController.jumpTo(0.0);
                        }
                      },
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: Image.asset(
                          "assets/img/custom_icons/chapter_portal.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: chapters[currentChapterIndex]['subchapters']?.length ?? 0,
                      itemBuilder: (context, chapterIndex) {
                        final subchapter = chapters[currentChapterIndex]['subchapters'][chapterIndex];
                        final levels = subchapter["levels"] ?? [];

                        var subchapter_state = "locked";
                        if (userProgressMap[subchapter["subchapter_id"]] != null) {
                          if (userProgressMap[subchapter["subchapter_id"]] == 6) {
                            subchapter_state = "completed";
                          } else {
                            subchapter_state = "current";
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            Center(child: ChapterBox(chapterName: subchapter["subchapter_title"], state: subchapter_state)),
                            const SizedBox(height: 30),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: levels.length,
                                itemBuilder: (context, index) {
                                  final level = levels[index];
                                  Widget buttonWidget = Padding(
                                    padding: EdgeInsets.only(top: 5, left: AppSize.screenWidth(context) * level["position"]),
                                    child: FluidyLevelButton(
                                      action: () async {
                                        if (level["state"] == ButtonStatus.locked) return;

                                        if (level["navigateTo"] != null) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => level["navigateTo"],
                                            ),
                                          );
                                          await computeGamificationData();
                                          await computeChapters();
                                        }
                                      },
                                      icon: level["icon"],
                                      state: level["state"],
                                    ),
                                  );
                                  if (index == 2) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        buttonWidget,
                                        Positioned(
                                          right: AppSize.screenWidth(context) * 0.1,
                                          bottom: -20,
                                          child: subchapter_state == "locked"
                                              ? ColorFiltered(
                                                  colorFilter: greyscale,
                                                  child: Image.asset(
                                                    "assets/img/fluidy_hello.png",
                                                    width: 125,
                                                  ),
                                                )
                                              : Image.asset(
                                                  "assets/img/fluidy_hello.png",
                                                  width: 125,
                                                ),
                                        ),
                                      ],
                                    );
                                  }
                                  if (index == 4) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        buttonWidget,
                                        Positioned(
                                          left: AppSize.screenWidth(context) * 0.08,
                                          bottom: -40,
                                          child: subchapter_state == "locked"
                                              ? ColorFiltered(
                                                  colorFilter: greyscale,
                                                  child: Image.asset(
                                                    "assets/img/fluidy_reading.png",
                                                    width: 100,
                                                  ),
                                                )
                                              : Image.asset(
                                                  "assets/img/fluidy_reading.png",
                                                  width: 100,
                                                ),
                                        ),
                                      ],
                                    );
                                  }
                                  return buttonWidget;
                                }),
                            Padding(
                              padding: EdgeInsets.only(
                                left: AppSize.screenWidth(context) * 0.7,
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (userProgressMap[subchapter["subchapter_id"]] == 5) {
                                    _showTreasureDialog(subchapter["subchapter_id"]);
                                  }
                                },
                                child: Image(
                                  image: getTreasureImage(userProgressMap[subchapter["subchapter_id"]] ?? 0),
                                  width: 90,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                  if (currentChapterIndex < chapters.length - 1)
                    InkWell(
                      onTap: () async {
                        // Panggil halaman transisi dengan animasi Fade
                        final bool? isTransitionDone = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const PortalTransitionPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );

                        // Jika video selesai dan mengembalikan "true", baru update state
                        if (isTransitionDone == true) {
                          setState(() {
                            currentChapterIndex++;
                          });
                          _scrollController.jumpTo(0.0);
                        }
                      },
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: Image.asset(
                          "assets/img/custom_icons/chapter_portal.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Future<void> _setNextSubChapter(String studentId, String subchapterId) async {
    // 1. Menentukan ID subchapter dan chapter berikutnya berdasarkan List chapters yang sudah ditarik
    List currentSubchapters = chapters[currentChapterIndex]['subchapters'] ?? [];
    int currentSubchapterIdx = currentSubchapters.indexWhere((s) => s['subchapter_id'] == subchapterId);

    String nextSubchapterId = '';
    String currentChapterId = chapters[currentChapterIndex]['id'] ?? chapters[currentChapterIndex]['chapter_id'] ?? '';
    String lastChapterId = currentChapterId;
    bool isChapterCompleted = false;

    if (currentSubchapterIdx != -1 && currentSubchapterIdx < currentSubchapters.length - 1) {
      // User masih berada di chapter yang sama, temukan subchapter selanjutnya
      nextSubchapterId = currentSubchapters[currentSubchapterIdx + 1]['subchapter_id'];
    } else {
      // Chapter ini sudah selesai semua subchapter-nya
      isChapterCompleted = true;
      if (currentChapterIndex < chapters.length - 1) {
        // Persiapkan pindah ke chapter selanjutnya jika chapter masih tersedia
        var nextChapter = chapters[currentChapterIndex + 1];
        lastChapterId = nextChapter['id'] ?? nextChapter['chapter_id'] ?? currentChapterId;
        if (nextChapter['subchapters'] != null && nextChapter['subchapters'].isNotEmpty) {
          nextSubchapterId = nextChapter['subchapters'][0]['subchapter_id'];
        }
      }
    }

    // 2. Eksekusi fungsi update untuk mencatat metadata progress yang baru dan inisialisasi level 0
    await _supabaseService.updateProgressToNextSubchapter(
      studentId,
      lastChapterId,
      subchapterId,
      nextSubchapterId,
      isChapterCompleted,
    );
  }

  void _showTreasureDialog(String subchapterId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Subchapter Selesai!",
          textAlign: TextAlign.center,
          style: fBoldTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Kamu mendapatkan 100 poin dari menyelesaikan subchapter ini.",
              textAlign: TextAlign.center,
              style: fSemiBoldTextStyle,
            ),
            SizedBox(height: 200, width: 180, child: Image.asset('assets/img/custom_icons/chest_opened.png')),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: regularBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  var studentId = _supabaseService.getCurrentUserId();
                  if (studentId != null && gamificationData['total_points'] != null) {
                    final newTotalPoints = gamificationData['total_points'] + 100;
                    log("Updating points for studentId: $studentId, newTotalPoints: $newTotalPoints");
                    await _supabaseService.upsertUserPoints(studentId, newTotalPoints);
                    await _supabaseService.updateStudentLevelProgress(studentId, subchapterId, 6);

                    await _setNextSubChapter(studentId, subchapterId);
                    await computeGamificationData();
                    await computeChapters();
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal memperbarui poin: studentId atau total poin saat ini tidak ditemukan")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal memperbarui poin: $e")),
                  );
                }
              },
              child: Text("Terima Poin", style: fMediumTextStyle.copyWith(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
