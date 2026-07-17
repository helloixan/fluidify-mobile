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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  bool _isLoading = true;

  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _chapterKey = GlobalKey();
  final GlobalKey _simLevelKey = GlobalKey();
  final GlobalKey _expLevelKey = GlobalKey();
  final GlobalKey _cmapLevelKey = GlobalKey();
  final GlobalKey _fbLevelKey = GlobalKey();
  final GlobalKey _quizLevelKey = GlobalKey();
  final GlobalKey _treasureKey = GlobalKey();
  final GlobalKey _portalNextKey = GlobalKey();

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
      userProgressMap =
          await _supabaseService.getStudentLevelProgress(studentId);
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
    try {
      var data = await _supabaseService.getAllChapters();
      if (data != null) {
        setState(() {
          chapters = data;
        });
      }
      computeLevels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data chapter: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (chapters.isNotEmpty) {
        _checkAndShowTutorial();
      }
    }
  }

  void computeLevels() {
    for (var chapter in chapters) {
      if (chapter['subchapters'] != null) {
        for (var subchapter in chapter['subchapters']) {
          String subId = subchapter["subchapter_id"];

          bool isSubchapterActive = userProgressMap.containsKey(subId);
          int currentLevelIndex =
              isSubchapterActive ? userProgressMap[subId]! : 0;

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
              {
                "icon": Icons.play_arrow_rounded,
                "navigateTo": SimulationPage(
                    subChapterId: subId,
                    currentPoints: gamificationData['total_points'] ?? 0),
                "state": getStatus(0),
                "position": 0.50
              },
              {
                "icon": Icons.search_rounded,
                "navigateTo": LearningPage(
                    subChapterId: subId,
                    currentPoints: gamificationData['total_points'] ?? 0),
                "state": getStatus(1),
                "position": 0.35
              },
              {
                "icon": Icons.edit_rounded,
                "navigateTo": MindMapPage(
                    subChapterId: subId,
                    currentPoints: gamificationData['total_points'] ?? 0),
                "state": getStatus(2),
                "position": 0.20
              },
              {
                "icon": Icons.lightbulb,
                "navigateTo": FeedbackPage(
                    subChapterId: subId,
                    currentPoints: gamificationData['total_points'] ?? 0,
                    state: getStatus(3)),
                "state": getStatus(3),
                "position": 0.35
              },
              {
                "icon": Icons.question_mark_rounded,
                "navigateTo": QuizPage(
                    subChapterId: subId,
                    currentPoints: gamificationData['total_points'] ?? 0,
                    type: "ctl"),
                "state": getStatus(4),
                "position": 0.50
              },
            ];
          });
        }
      }
    }
  }

  void _checkAndShowTutorial() async {
    var profile = await _supabaseService.getUserProfile();
    bool done = profile?['tutorial_done'] ?? true;
    if (!done && mounted) {
      // Beri sedikit jeda agar UI ter-render secara utuh sebelum disorot
      Future.delayed(const Duration(milliseconds: 500), () {
        _showTutorial();
      });
    }
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "AppBarTarget",
        keyTarget: _appBarKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Status Belajarmu",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Di sini kamu bisa melihat total level yang diselesaikan, streak harian, dan poin yang sudah kamu kumpulkan.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "ChapterTarget",
        keyTarget: _chapterKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Judul Subchapter",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Bagian ini adalah judul atau banner dari submateri yang sedang kamu pelajari.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "SimLevelTarget",
        keyTarget: _simLevelKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tahap 1: Simulasi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tahap pertama dari pembelajaran kontekstual. Di sini kamu akan mengamati fenomena di dunia nyata yang berkaitan dengan materi.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "ExpLevelTarget",
        keyTarget: _expLevelKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tahap 2: Eksplorasi Materi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Setelah mengamati fenomena, kamu akan mengeksplorasi konsep dan teori yang mendasarinya secara interaktif.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "CMapLevelTarget",
        keyTarget: _cmapLevelKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tahap 3: Peta Konsep",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Hubungkan konsep-konsep yang telah kamu pelajari untuk membangun dan memvisualisasikan pemahaman yang utuh.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "FbLevelTarget",
        keyTarget: _fbLevelKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tahap 4: Umpan Balik",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Buka umpan balik dari proses belajarmu agar pemahamanmu semakin mantap dan terkoreksi.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "QuizLevelTarget",
        keyTarget: _quizLevelKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tahap 5: Kuis Kontekstual",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Uji seberapa baik pemahamanmu tentang keseluruhan materi di subchapter ini melalui kuis!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "TreasureTarget",
        keyTarget: _treasureKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hadiah Pencapaian!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Selesaikan 1 subchapter (seluruh tahapan) untuk membuka peti ini dan dapatkan poin tambahan sebagai hadiah!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Portal hanya akan di-highlight jika widget dirender di layar (jika chapters lebih dari 1)
    if (_portalNextKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "PortalTarget",
          keyTarget: _portalNextKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Portal Pindah Bab",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Jika kamu sudah menyelesaikan bab ini atau ingin melihat bab selanjutnya yang tersedia, gunakan portal ini!",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => controller.next(),
                      child: const Text("Selanjutnya ->", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    return targets;
  }

  void _showTutorial() {
    late TutorialCoachMark tutorialCoachMark;

    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: regularBlue, // Menyesuaikan tema warna aplikasi
      textSkip: "LEWATI",
      hideSkip: true,
      showSkipInLastTarget: true,
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () {
        _finishTutorial();
      },
      onSkip: () {
        _finishTutorial();
        return true;
      },
    );

    tutorialCoachMark.show(context: context);
  }

  void _finishTutorial() async {
    var userId = _supabaseService.getCurrentUserId();
    if (userId != null) {
      await _supabaseService.updateTutorialDone(userId);
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
                key: _appBarKey,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: correctGreen),
                      const SizedBox(width: 8),
                      Text("${gamificationData['levels_done']} levels",
                          style: fMediumTextStyle.copyWith(
                              color: correctGreen, fontSize: 21)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(streakIcon, color: darkOrange),
                      const SizedBox(width: 8),
                      Text("${gamificationData['current_streak']} streak",
                          style: fMediumTextStyle.copyWith(
                              color: darkOrange, fontSize: 21)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: lightBlue),
                      const SizedBox(width: 8),
                      Text("${gamificationData['total_points']} pts",
                          style: fMediumTextStyle.copyWith(
                              color: lightBlue, fontSize: 21)),
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
              title: Text("Fluidify", key: _appBarKey,
                  style: fSemiBoldTextStyle.copyWith(color: regularBlue)),
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
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const PortalTransitionPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
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
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          height: 100,
                          child: Image.asset(
                            "assets/img/custom_icons/portal_prev.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: chapters[currentChapterIndex]['subchapters']
                              ?.length ??
                          0,
                      itemBuilder: (context, chapterIndex) {
                        final subchapter = chapters[currentChapterIndex]
                            ['subchapters'][chapterIndex];
                        final levels = subchapter["levels"] ?? [];

                        var subchapter_state = "locked";
                        if (userProgressMap[subchapter["subchapter_id"]] !=
                            null) {
                          if (userProgressMap[subchapter["subchapter_id"]] ==
                              6) {
                            subchapter_state = "completed";
                          } else {
                            subchapter_state = "current";
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: ChapterBox(
                                    key: (currentChapterIndex == 0 && chapterIndex == 0) ? _chapterKey : null,
                                    chapterName: subchapter["subchapter_title"],
                                    state: subchapter_state)),
                            const SizedBox(height: 10),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: levels.length,
                                itemBuilder: (context, index) {
                                  final level = levels[index];
                                  Widget buttonWidget = Padding(
                                    padding: EdgeInsets.only(
                                        top: currentChapterIndex == 0 ? 2 : 5,
                                        left: AppSize.screenWidth(context) *
                                            level["position"]),
                                    child: FluidyLevelButton(
                                        key: (currentChapterIndex == 0 && chapterIndex == 0)
                                            ? (index == 0 ? _simLevelKey
                                                : index == 1 ? _expLevelKey
                                                : index == 2 ? _cmapLevelKey
                                                : index == 3 ? _fbLevelKey
                                                : index == 4 ? _quizLevelKey : null)
                                            : null,
                                      action: () async {
                                        if (level["state"] ==
                                            ButtonStatus.locked) return;

                                        if (level["navigateTo"] != null) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  level["navigateTo"],
                                            ),
                                          );
                                          setState(() {
                                            _isLoading = true;
                                          });
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
                                          right: AppSize.screenWidth(context) *
                                              0.05,
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
                                          left: AppSize.screenWidth(context) *
                                              0.08,
                                          bottom: 20,
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
                            Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: AppSize.screenWidth(context) * 0.7,
                                  ),
                                  child: InkWell(
                                    key: (currentChapterIndex == 0 && chapterIndex == 0) ? _treasureKey : null,
                                    onTap: () {
                                      if (userProgressMap[
                                              subchapter["subchapter_id"]] ==
                                          5) {
                                        _showTreasureDialog(
                                            subchapter["subchapter_id"]);
                                      }
                                    },
                                    child: Image(
                                      image: getTreasureImage(userProgressMap[
                                              subchapter["subchapter_id"]] ??
                                          0),
                                      width: 85,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: AppSize.screenWidth(context) * 0.18,
                                  top: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: subchapter_state == "locked" || userProgressMap[subchapter["subchapter_id"]]! < 5
                                          ? Colors.grey[400]
                                          : userProgressMap[subchapter["subchapter_id"]] == 6
                                              ? correctGreen
                                              : lightBlue,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(subchapter_state == "locked" || userProgressMap[subchapter["subchapter_id"]]! < 5
                                          ? "Hadiah Terkunci"
                                          : userProgressMap[subchapter["subchapter_id"]] == 6
                                              ? "Hadiah Diklaim"
                                              : "Hadiah Tersedia",
                                      style: fBoldTextStyle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            if (currentChapterIndex > 0)
                              const SizedBox(height: 20),
                            if (currentChapterIndex < chapters.length - 1 &&
                                currentChapterIndex == 0)
                              Padding(
                                padding: EdgeInsets.only(
                                    left: AppSize.screenWidth(context) * 0.3),
                                child: InkWell(
                                  key: (currentChapterIndex == 0 && chapterIndex == 0) ? _portalNextKey : null,
                                  onTap: () async {
                                    final bool? isTransitionDone =
                                        await Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const PortalTransitionPage(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                              opacity: animation, child: child);
                                        },
                                        transitionDuration:
                                            const Duration(milliseconds: 500),
                                      ),
                                    );

                                    if (isTransitionDone == true) {
                                      setState(() {
                                        currentChapterIndex++;
                                      });
                                      _scrollController.jumpTo(0.0);
                                    }
                                  },
                                  child: SizedBox(
                                    height: 100,
                                    child: Image.asset(
                                      "assets/img/custom_icons/portal_next.png",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                  if (currentChapterIndex < chapters.length - 1 &&
                      currentChapterIndex != 0)
                    InkWell(
                      onTap: () async {
                        // Panggil halaman transisi dengan animasi Fade
                        final bool? isTransitionDone = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const PortalTransitionPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
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
                        child: Image.asset(
                          "assets/img/custom_icons/portal_next.png",
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
    List currentSubchapters =
        chapters[currentChapterIndex]['subchapters'] ?? [];
    int currentSubchapterIdx = currentSubchapters
        .indexWhere((s) => s['subchapter_id'] == subchapterId);

    String nextSubchapterId = '';
    String currentChapterId = chapters[currentChapterIndex]['id'] ??
        chapters[currentChapterIndex]['chapter_id'] ??
        '';
    String lastChapterId = currentChapterId;
    bool isChapterCompleted = false;

    if (currentSubchapterIdx != -1 &&
        currentSubchapterIdx < currentSubchapters.length - 1) {
      // User masih berada di chapter yang sama, temukan subchapter selanjutnya
      nextSubchapterId =
          currentSubchapters[currentSubchapterIdx + 1]['subchapter_id'];
    } else {
      // Chapter ini sudah selesai semua subchapter-nya
      isChapterCompleted = true;
      if (currentChapterIndex < chapters.length - 1) {
        // Persiapkan pindah ke chapter selanjutnya jika chapter masih tersedia
        var nextChapter = chapters[currentChapterIndex + 1];
        lastChapterId =
            nextChapter['id'] ?? nextChapter['chapter_id'] ?? currentChapterId;
        if (nextChapter['subchapters'] != null &&
            nextChapter['subchapters'].isNotEmpty) {
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
        backgroundColor: appBackgroundColor,
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
            SizedBox(
                height: 200,
                width: 180,
                child: Image.asset('assets/img/custom_icons/chest_opened.png')),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: regularBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  var studentId = _supabaseService.getCurrentUserId();
                  await computeGamificationData();
                  if (studentId != null &&
                      gamificationData['total_points'] != null) {
                    final newTotalPoints =
                        gamificationData['total_points'] + 100;
                    log("Updating points for studentId: $studentId, newTotalPoints: $newTotalPoints");
                    await _supabaseService.upsertUserPoints(
                        studentId, newTotalPoints);
                    await _supabaseService.updateStudentLevelProgress(
                        studentId, subchapterId, 6);
                    Navigator.of(context).pop();
                    setState(() {
                      _isLoading = true;
                    });
                    await _setNextSubChapter(studentId, subchapterId);
                    await computeGamificationData();
                    await computeChapters();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Gagal memperbarui poin: studentId atau total poin saat ini tidak ditemukan")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal memperbarui poin: $e")),
                  );
                }
              },
              child: Text("Terima Poin",
                  style: fMediumTextStyle.copyWith(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
