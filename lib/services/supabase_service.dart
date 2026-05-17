import 'dart:developer';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // sign-in
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // sign-out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  //get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  //get user id
  String? getCurrentUserId() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

  //get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase.from('profiles').select('*, classes(class_name)').eq('id', user.id).single();
      return response;
    } catch (e) {
      print('Error fetching profile in service: $e');
      return null;
    }
  }

  // get user role
  Future<String?> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase.from('profiles').select('role').eq('id', user.id).single();
      log('[getUserRole] $response');
      return response['role'];
    } catch (e) {
      print('Error fetching profile in service: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVideoBySubChapter(String subChapterId) async {
    try {
      final response = await _supabase.from('videos').select('''
            video_name, 
            video_url, 
            sub_chapters!inner(id)
          ''').eq('sub_chapters.id', subChapterId).limit(1).single();

      return response;
    } catch (e) {
      print('Error fetching video for subchapter $subChapterId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEssentialQuestionBySubChapter(String subChapterId) async {
    try {
      final response = await _supabase.from('essential_feedbacks').select('id, essential_question').eq('subchapter_id', subChapterId).limit(1).maybeSingle();

      return response;
    } catch (e) {
      log('Error fetching essential question for subchapter $subChapterId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getAllChapters() async {
    try {
      final response = await _supabase.from('sub_chapters').select('''
            subchapter_id:id,
            subchapter_title:title,
            subchapter_state:state,
            sequence_order,
            chapter_id:chapters(id),
            chapter_title:chapters(title),
            chapter_sequence:chapters(sequence_order)
          ''');
      final Map<String, Map<String, dynamic>> groupedChapters = {};

      for (var item in response) {
        final chapterId = item['chapter_id']['id'];
        if (!groupedChapters.containsKey(chapterId)) {
          groupedChapters[chapterId] = {
            'chapter_id': chapterId,
            'chapter_title': item['chapter_title']['title'],
            'chapter_sequence': item['chapter_sequence']['sequence_order'],
            'subchapters': [],
          };
        }

        (groupedChapters[chapterId]!['subchapters'] as List).add({
          'subchapter_id': item['subchapter_id'],
          'subchapter_title': item['subchapter_title'],
          'subchapter_order': item['sequence_order'],
          'subchapter_state': item['subchapter_state'],
        });
      }

      final List<Map<String, dynamic>> chapters = groupedChapters.values.toList();

      final userRole = await getUserRole();
      if (userRole == 'teacher') {
        final responseChapters = await _supabase.from('chapters').select('*');
        for (var chapter in responseChapters) {
          final chapterId = chapter['id'];
          if (!groupedChapters.containsKey(chapterId)) {
            chapters.add({
              'chapter_id': chapterId,
              'chapter_title': chapter['title'],
              'chapter_sequence': chapter['sequence_order'],
              'subchapters': [],
            });
          }
        }
      }

      log("chapters: $chapters");
      chapters.sort((a, b) => a['chapter_sequence'].compareTo(b['chapter_sequence']));
      return chapters;
    } catch (e) {
      log('Error fetching all chapters: $e');
      return null;
    }
  }

  Future<String?> getPromptbySubChapter(String subChapterId, String type) async {
    try {
      var response;
      if (subChapterId != "") {
        response = await _supabase.from('prompts').select('prompt_text').eq('subchapter_id', subChapterId).eq('type', type).limit(1).maybeSingle();
      } else {
        response = await _supabase.from('prompts').select('prompt_text').eq('type', type).limit(1).maybeSingle();
      }

      String prompt = "none";
      if (response != null) {
        prompt = response['prompt_text'];
      }
      return prompt;
    } catch (e) {
      log('Error fetching prompt for subchapter $subChapterId: $e');
      return null;
    }
  }

  //get student feedbacks
  Future<Map<String, dynamic>?> getStudentFeedbacks(String essentialFeedbackId, String studentId) async {
    try {
      final response = await _supabase
          .from('student_feedbacks')
          .select('id, student_answer, ai_feedback, student_id, essential_feedback_id')
          .eq('essential_feedback_id', essentialFeedbackId)
          .eq('student_id', studentId)
          .limit(1)
          .maybeSingle();
      log("get student feedbacks response: $response");
      return response;
    } catch (e) {
      log('Error fetching student feedbacks for essentialFeedbackId $essentialFeedbackId: $e');
      return null;
    }
  }

  Future<void> updateStudentFeedbacks(String essentialFeedbackId, String studentAnswer, String geminiFeedback, String studentId) async {
    try {
      Map<String, dynamic> query = {'student_id': studentId};
      if (studentAnswer.isNotEmpty && studentAnswer != "") {
        query['student_answer'] = studentAnswer;
        log("[updateStudentFeedbacks] student answer: $studentAnswer");
      }
      if (geminiFeedback.isNotEmpty && geminiFeedback != "") {
        query['ai_feedback'] = geminiFeedback;
        log("[updateStudentFeedbacks] Gemini feedback: $geminiFeedback");
      }
      log("[updateStudentFeedbacks]  query: $query");

      await _supabase.from('student_feedbacks').update(query).eq('essential_feedback_id', essentialFeedbackId).eq('student_id', studentId);
      log('Successfully updated student feedbacks for essentialFeedbackId: $essentialFeedbackId');
    } catch (e) {
      log('Error updating student feedbacks: $e');
    }
  }

  Future<void> insertStudentFeedbacks(String essentialFeedbackId, String studentAnswer, String geminiFeedback, String studentId) async {
    try {
      await _supabase.from('student_feedbacks').insert({
        'essential_feedback_id': essentialFeedbackId,
        'student_id': studentId,
        'student_answer': studentAnswer,
        'ai_feedback': geminiFeedback,
      });
      log('Successfully inserted student feedbacks for essentialFeedbackId: $essentialFeedbackId');
    } catch (e) {
      log('Error inserting student feedbacks: $e');
    }
  }

  Future<Map<String, dynamic>?> getChatbotFlowBySubChapter(String subChapterId) async {
    try {
      final response = await _supabase.from('learning_materials').select('id, flow_data').eq('subchapter_id', subChapterId).limit(1).maybeSingle();

      if (response != null && response['flow_data'] != null) {
        return {
          'id': response['id'],
          'flow_data': response['flow_data'] as List<dynamic>,
        };
      }
      return null;
    } catch (e) {
      log('Error fetching chatbot flow for subchapter $subChapterId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentGamificationData(String studentId) async {
    try {
      final response = await _supabase.from('user_gamifications').select('*').eq('user_id', studentId).limit(1).maybeSingle();
      log("get student gamification data: $response");
      return response;
    } catch (e) {
      log('Error fetching student gamification data for studentId $studentId: $e');
      return null;
    }
  }

  Future<void> upsertUserStreak(String userId, int currentStreak, DateTime lastActiveDate) async {
    try {
      // 1. Ambil waktu sekarang
      DateTime nowUtc = DateTime.now().toUtc();

      // 2. Buat objek DateTime baru HANYA dengan Tahun, Bulan, dan Tanggal (Jam di-set 00:00)
      DateTime todayDate = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      DateTime lastDate = DateTime.utc(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);

      // 3. Hitung selisih hari yang bersih dari pengaruh jam
      int diffDays = todayDate.difference(lastDate).inDays.abs();
      log("[upsertUserStreak] diff days: $diffDays");

      if (diffDays == 0) {
        // Jika login di hari yang sama: Streak tetap (tidak ditambah).
        // Namun jika streak sebelumnya 0, jadikan 1.
        if (currentStreak == 0) {
          currentStreak = 1;
        }
      } else if (diffDays == 1) {
        // Jika login di hari berikutnya (streak berlanjut)
        currentStreak += 1;
      } else {
        // Jika bolong lebih dari 1 hari (streak putus)
        currentStreak = 1;
      }

      await _supabase.from('user_gamifications').upsert({
        'user_id': userId,
        'current_streak': currentStreak,
        'last_active_date': nowUtc.toIso8601String(), // Update ke tanggal dan jam hari ini
      }, onConflict: 'user_id');

      log('Successfully upserted user streak for userId: $userId. New Streak: $currentStreak');
    } catch (e) {
      log('Error updating user streak: $e');
    }
  }

  Future<void> upsertUserLevelsDone(String userId, int currentDone) async {
    try {
      await _supabase.from('user_gamifications').upsert({
        'user_id': userId,
        'levels_done': currentDone,
      }, onConflict: 'user_id');
      log('Successfully upserted user levels done for userId: $userId');
    } catch (e) {
      log('Error updating user levels done: $e');
    }
  }

  Future<void> upsertUserPoints(String userId, int currentPoints) async {
    try {
      await _supabase.from('user_gamifications').upsert({
        'user_id': userId,
        'total_points': currentPoints,
      }, onConflict: 'user_id');
      log('Successfully upserted user points for userId: $userId');
    } catch (e) {
      log('Error updating user points: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentProgress(String userId) async {
    try {
      final response = await _supabase.from('student_progress').select().eq('user_id', userId).maybeSingle();
      return response;
    } catch (e) {
      log('Error fetching student progress: $e');
      return null;
    }
  }

  Future<Map<String, int>> getStudentLevelProgress(String userId) async {
    try {
      final response = await _supabase.from('student_progress').select('levels_progress').eq('user_id', userId).maybeSingle();

      if (response != null && response['levels_progress'] != null) {
        // Konversi dari JSONB (Map<String, dynamic>) ke Map<String, int>
        Map<String, dynamic> rawData = response['levels_progress'];
        return rawData.map((key, value) => MapEntry(key, value as int));
      }
      return {};
    } catch (e) {
      log('Error fetching student level progress: $e');
      return {};
    }
  }

  Future<void> updateStudentLevelProgress(String userId, String subchapterId, int levelIndex) async {
    try {
      Map<String, int> currentProgress = await getStudentLevelProgress(userId);
      currentProgress[subchapterId] = levelIndex;

      await _supabase.from('student_progress').upsert({
        'user_id': userId,
        'levels_progress': currentProgress,
      }, onConflict: 'user_id');

      log('Successfully updated level progress for subchapter: $subchapterId');
    } catch (e) {
      log('Error updating student level progress: $e');
    }
  }

  Future<void> upsertStudentExplorationScore(
    String userId,
    double score,
    String materialId,
    String explorationLevel,
    List<Map<String, dynamic>> chatHistory, // 🔥 Tambahkan parameter ini
  ) async {
    try {
      await _supabase.from('student_exploration').upsert({
        'student_id': userId,
        'score': score,
        'exploration_level': explorationLevel,
        'material_id': materialId,
        'chat_history': chatHistory // 🔥 Simpan history ke kolom baru
      }, onConflict: 'student_id,material_id');

      log('Successfully upserted exploration score and history for materialId: $materialId');
    } catch (e) {
      log('Error upserting student exploration score: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentExplorationHistory(String userId, String materialId) async {
    try {
      final response = await _supabase.from('student_exploration').select('chat_history, score, exploration_level').eq('student_id', userId).eq('material_id', materialId).maybeSingle();

      return response;
    } catch (e) {
      log('Error fetching student exploration history: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMindmapBySubChapter(String subChapterId) async {
    try {
      final response = await _supabase.from('mind_maps').select('id,subjects').eq('subchapter_id', subChapterId).limit(1).maybeSingle();
      log("getMindmapBySubChapter response: $response, subchapterId: $subChapterId");
      if (response != null && response['subjects'] != null) {
        return {
          'id': response['id'],
          'subjects': response['subjects'] as List<dynamic>,
        };
      }
      return null;
    } catch (e) {
      log('Error fetching mindmap for subchapter $subChapterId: $e');
      return null;
    }
  }

  Future<void> upsertStudentMindmapAttempts(String userId, int attempts, String result, String mindMapId, int score) async {
    try {
      await _supabase.from('student_mindmap_attempts').upsert({
        'mindmap_id': mindMapId,
        'student_id': userId,
        'attempts': attempts,
        'result': result,
        'score': score,
      }, onConflict: 'student_id,mindmap_id');

      log('Successfully upserted mindmap attempts for userId: $userId and mindMapId: $mindMapId');
    } catch (e) {
      log('Error upserting student mindmap attempts: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentMindmapAttempts(String userId, String mindMapId) async {
    try {
      final response = await _supabase.from('student_mindmap_attempts').select('id,attempts,result,score').eq('student_id', userId).eq('mindmap_id', mindMapId).limit(1).maybeSingle();
      log("getStudentMindmapAttempts response: $response");
      if (response != null) {
        return {
          'id': response['id'],
          'attempts': response['attempts'],
          'result': response['result'],
          'score': response['score'],
        };
      }
      return null;
    } catch (e) {
      log('Error fetching student mindmap attempts : $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentFeedbacksByEssentialFeedbackId(String essentialFeedbackId, String studentId) async {
    try {
      final response = await _supabase
          .from('student_feedbacks')
          .select('id,student_answer,ai_feedback,student_id')
          .eq('essential_feedback_id', essentialFeedbackId)
          .eq('student_id', studentId)
          .limit(1)
          .maybeSingle();
      log("getStudentFeedbacksByEssentialFeedbackId response: $response, essentialFeedbackId: $essentialFeedbackId");
      if (response != null && response['student_answer'] != null) {
        return {
          'id': response['id'],
          'student_answer': response['student_answer'],
          'ai_feedback': response['ai_feedback'],
          'student_id': response['student_id'],
        };
      }
      return null;
    } catch (e) {
      log('Error fetching student feedback for essentialFeedbackId $essentialFeedbackId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getQuizDatabySubChapter(String subchapterId, String type) async {
    try {
      final response = await _supabase.from('quizzes').select('id,question_jsonb,type,title').eq('subchapter_id', subchapterId).eq('type', type).limit(1).maybeSingle();
      log("[getQuizDatabySubChapter] response: $response, subchapterId: $subchapterId");
      if (response != null && response['question_jsonb'] != null) {
        return {
          'id': response['id'],
          'question_jsonb': response['question_jsonb'],
          'type': response['type'],
          'title': response['title'],
        };
      }
      return null;
    } catch (e) {
      log('Error fetching quiz data for subchapter $subchapterId: $e');
      return null;
    }
  }

  Future<void> insertStudentQuizAttempt(String quizId, String studentId, int score, int wrongs, int corrects, List<Map<String, dynamic>> attemptHistory) async {
    try {
      await _supabase.from('student_attempts').insert({
        'quiz_id': quizId,
        'user_id': studentId,
        'score': score,
        'wrongs': wrongs,
        'corrects': corrects,
        'attempt_history': attemptHistory,
      });
      log('[insertStudentQuizAttempt] Successfully inserted student quiz attempt for quizId: $quizId');
    } catch (e) {
      log('[insertStudentQuizAttempt]Error inserting student quiz attempt: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentQuizAttempt(String quizId, String studentId) async {
    try {
      final response =
          await _supabase.from('student_attempts').select('id,quiz_id,user_id,score,wrongs,corrects,attempt_history').eq('quiz_id', quizId).eq('user_id', studentId).limit(1).maybeSingle();
      log("[getStudentQuizAttempt] response: $response, quizId: $quizId, studentId: $studentId");
      if (response != null) {
        return {
          'id': response['id'],
          'quiz_id': response['quiz_id'],
          'user_id': response['user_id'],
          'score': response['score'],
          'wrongs': response['wrongs'],
          'corrects': response['corrects'],
          'attempt_history': response['attempt_history'],
        };
      }
      return null;
    } catch (e) {
      log('Error fetching student quiz attempt for quizId $quizId and studentId $studentId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudentsGamification() async {
    try {
      final gamifications = await _supabase.from('user_gamifications').select('*').order('total_points', ascending: false);

      final profiles = await _supabase.from('profiles').select('id, display_name, avatar_url, role');

      final profileMap = {
        for (var p in profiles)
          p['id']: {
            'name': p['display_name'],
            'avatar_url': p['avatar_url'],
            'role': p['role'],
          }
      };

      final result = <Map<String, dynamic>>[];
      for (var item in gamifications) {
        final profile = profileMap[item['user_id']];

        if (profile?['role'] == 'student') {
          result.add({
            ...item,
            'name': profile?['name'] ?? 'Unknown',
            'avatar_url': profile?['avatar_url'],
          });
        }
      }

      log("[getAllStudentsGamification] response: $result");

      return result;
    } catch (e) {
      log('Error fetching all students gamification: $e');
      return [];
    }
  }

  Future<void> updateProgressToNextSubchapter(String userId, String lastChapterId, String lastSubchapterId, String nextSubchapterId, bool isChapterCompleted) async {
    try {
      // 1. Ambil data progress saat ini untuk mendapatkan counter sebelumnya
      final response = await _supabase.from('student_progress').select().eq('user_id', userId).maybeSingle();

      if (response != null) {
        int currentSubchapterDone = (response['subchapter_done'] ?? 0) as int;
        int currentChapterDone = (response['chapter_done'] ?? 0) as int;
        Map<String, dynamic> currentLevelsProgress = response['levels_progress'] ?? {};

        // 2. Inisialisasi progress subchapter berikutnya menjadi 0 (jika ada)
        if (nextSubchapterId.isNotEmpty) {
          currentLevelsProgress[nextSubchapterId] = 0;
        }

        // 3. Tambah counter
        currentSubchapterDone += 1;
        if (isChapterCompleted) {
          currentChapterDone += 1;
        }

        // 4. Update row dengan data kalkulasi yang baru
        await _supabase.from('student_progress').update({
          'subchapter_done': currentSubchapterDone,
          'chapter_done': currentChapterDone,
          'last_chapter': lastChapterId,
          'last_subchapter': nextSubchapterId.isNotEmpty ? nextSubchapterId : lastSubchapterId,
          'levels_progress': currentLevelsProgress,
        }).eq('user_id', userId);

        log('Successfully updated progress meta. Next subchapter initialized.');
      }
    } catch (e) {
      log('Error updating next subchapter progress: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllQuizbyType(String type) async {
    try {
      final quizzes = await _supabase.from('quizzes').select('*').eq('type', type);
      log("[getAllQuizbyType] type: $type, total: ${quizzes.length}");
      final profiles = await _supabase.from('profiles').select('id, display_name');

      final profileMap = {
        for (var p in profiles)
          p['id']: {
            'name': p['display_name'],
          }
      };

      final result = quizzes.map<Map<String, dynamic>>((item) {
        final profile = profileMap[item['created_by']];

        return {
          ...item,
          'creator_name': profile?['name'] ?? 'Unknown',
        };
      }).toList();

      // sudah pasti List
      if (result.isNotEmpty) {
        return List<Map<String, dynamic>>.from(result);
      }

      return []; // kalau kosong
    } catch (e) {
      log('Error fetching quiz data for type $type: $e');
      return []; // wajib return biar tidak null
    }
  }

  // ========== TEACHER/ADMIN THINGS ==========

  // CRUD Chapter

  Future<void> insertChapter(String title, int sequenceOrder) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menambahkan chapter.');
      }

      final existingChapter = await _supabase.from('chapters').select('id').eq('sequence_order', sequenceOrder).maybeSingle();
      if (existingChapter != null) {
        throw Exception('Urutan Chapter $sequenceOrder sudah digunakan!');
      }

      final userId = getCurrentUserId();
      await _supabase.from('chapters').insert({'title': title, 'sequence_order': sequenceOrder, 'created_by': userId});
      log('Successfully inserted new chapter with title: $title');
    } catch (e) {
      log('Error inserting chapter: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getChapterById(String chapterId) async {
    try {
      final chapter = await _supabase.from('chapters').select('*').eq('id', chapterId).maybeSingle();

      if (chapter == null) return null;

      final Map<String, dynamic> chapterData = {
        'chapter_id': chapter['id'],
        'chapter_title': chapter['title'],
        'chapter_sequence': chapter['sequence_order'],
        'subchapters': <Map<String, dynamic>>[],
      };

      final subchaptersResponse = await _supabase.from('sub_chapters').select('''
            subchapter_id:id,
            subchapter_title:title,
            subchapter_state:state,
            sequence_order
          ''').eq('chapter_id', chapterId);

      for (var item in subchaptersResponse) {
        (chapterData['subchapters'] as List<Map<String, dynamic>>).add({
          'subchapter_id': item['subchapter_id'],
          'subchapter_title': item['subchapter_title'],
          'subchapter_order': item['sequence_order'],
          'subchapter_state': item['subchapter_state'],
        });
      }

      log("getChapterById: $chapterData");
      (chapterData['subchapters'] as List<Map<String, dynamic>>).sort((a, b) => (a['subchapter_order'] as int).compareTo(b['subchapter_order'] as int));
      return chapterData;
    } catch (e) {
      log('Error fetching chapter by id $chapterId: $e');
      return null;
    }
  }

  Future<void> deleteChapter(String chapterId) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menghapus chapter.');
      }
      log("Deleting chapter...");
      await _supabase.from('chapters').delete().eq('id', chapterId);
      log('Successfully deleted chapter $chapterId');
    } catch (e) {
      log('Error deleting chapter $chapterId: $e');
      rethrow;
    }
  }

  Future<void> updateChapterData(String chapterId, String newTitle, int newSequenceOrder) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah judul chapter.');
      }

      final existingChapter = await _supabase.from('chapters').select('id').eq('sequence_order', newSequenceOrder).maybeSingle();
      if (existingChapter != null && existingChapter['id'] != chapterId) {
        throw Exception('Urutan Chapter $newSequenceOrder sudah digunakan!');
      }

      await _supabase.from('chapters').update({'title': newTitle, 'sequence_order': newSequenceOrder}).eq('id', chapterId);
      log('Successfully updated chapter $chapterId title to $newTitle');
    } catch (e) {
      log('Error updating chapter $chapterId: $e');
      rethrow;
    }
  }

  //CRUD Subchapter

  Future<void> insertSubchapter(String chapterId, String title, int sequenceOrder) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menambahkan subchapter.');
      }

      final existingSubchapter = await _supabase.from('sub_chapters').select('id').eq('chapter_id', chapterId).eq('sequence_order', sequenceOrder).maybeSingle();

      if (existingSubchapter != null) {
        throw Exception('Urutan subchapter $sequenceOrder sudah digunakan pada chapter ini.');
      }

      await _supabase.from('sub_chapters').insert({'title': title, 'chapter_id': chapterId, 'sequence_order': sequenceOrder});
      log('Successfully inserted new subchapter with title: $title');
    } catch (e) {
      log('Error inserting chapter: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSubchapterById(String subchapterId) async {
    try {
      final response = await _supabase.from('sub_chapters').select('*').eq('id', subchapterId).maybeSingle();
      return response;
    } catch (e) {
      log('Error fetching subchapter by id $subchapterId: $e');
      return null;
    }
  }

  Future<void> updateSubchapterData(String subchapterId, String newTitle, int newSequenceOrder) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah subchapter.');
      }

      final currentSubchapter = await _supabase.from('sub_chapters').select('chapter_id').eq('id', subchapterId).maybeSingle();
      if (currentSubchapter == null) {
        throw Exception('Subchapter tidak ditemukan.');
      }

      final chapterId = currentSubchapter['chapter_id'];

      final existingSubchapter = await _supabase.from('sub_chapters').select('id').eq('chapter_id', chapterId).eq('sequence_order', newSequenceOrder).maybeSingle();

      if (existingSubchapter != null && existingSubchapter['id'] != subchapterId) {
        throw Exception('Urutan Subchapter $newSequenceOrder sudah digunakan pada chapter ini!');
      }

      await _supabase.from('sub_chapters').update({'title': newTitle, 'sequence_order': newSequenceOrder}).eq('id', subchapterId);
      log('Successfully updated subchapter $subchapterId title to $newTitle');
    } catch (e) {
      log('Error updating subchapter $subchapterId: $e');
      rethrow;
    }
  }

  Future<void> deleteSubchapter(String subchapterId) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menghapus subchapter.');
      }
      await _supabase.from('sub_chapters').delete().eq('id', subchapterId);
      log('Successfully deleted subchapter $subchapterId');
    } catch (e) {
      log('Error deleting subchapter $subchapterId: $e');
      rethrow;
    }
  }

  // CRUD Video Simulasi
  Future<Map<String, dynamic>?> getVideoBySubchapterId(String subchapterId) async {
    try {
      final response = await _supabase.from('videos').select('*').eq('subchapter_id', subchapterId).single();
      return response;
    } catch (e) {
      log('Error fetching video by subchapter_id $subchapterId: $e');
      return null;
    }
  }

  Future<String?> uploadVideo(String filePath, String videoName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        log("ERROR: User belum login! Supabase menolak akses karena policy 'authenticated'.");
        return null;
      }

      final file = File(filePath);

      final fileName = '${videoName.toLowerCase().replaceAll(' ', '_')}-${DateTime.now().toIso8601String()}.mp4';

      // upload
      await _supabase.storage.from('simulations').upload(
            fileName,
            file,
          );

      // ambil public url
      final publicUrl = _supabase.storage.from('simulations').getPublicUrl(fileName);

      log("Video publicUrl: $publicUrl");

      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<bool> deleteVideoFromStorage(String videoUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        log("ERROR: User belum login! Gagal menghapus video.");
        return false;
      }

      Uri uri = Uri.parse(videoUrl);
      List<String> pathSegments = uri.pathSegments;
      String fileName = pathSegments.last;

      await _supabase.storage.from('simulations').remove([fileName]);

      log("Berhasil menghapus video dari storage: $fileName");
      return true;
    } catch (e) {
      log('Delete storage error: $e');
      return false;
    }
  }

  Future<void> updateVideoSimulation(String videoId, String newVideoTitle, String videoPath, String currentVideoUrl) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak, Hanya guru yang dapat mengubah video simulasi.');
      }

      final currentVideo = await _supabase.from('videos').select('*').eq('id', videoId).maybeSingle();
      if (currentVideo == null) {
        throw Exception('Video yang akan diubah tidak ditemukan.');
      }

      final isDeleted = await deleteVideoFromStorage(currentVideoUrl);
      if (!isDeleted) {
        throw Exception('Gagal mengganti video $currentVideoUrl dengan yang baru.');
      }

      final newVideoUrl = await uploadVideo(videoPath, newVideoTitle);
      if (newVideoUrl == null) {
        throw Exception('Gagal mengunggah video baru.');
      }

      await _supabase.from('videos').update({'video_name': newVideoTitle, 'video_url': newVideoUrl}).eq('id', videoId);
      log('[updateVideoSimulation] Successfully updated video $videoId title to $newVideoTitle');

    } catch (e) {
      log('[updateVideoSimulation] Error updating video $videoId: $e');
      rethrow;
    }
  }

  Future<void> insertVideo(String subChapterId, String title, String videoPath) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak, Hanya guru yang dapat menambahkan video simulasi.');
      }

      final existingVideo = await _supabase.from('videos').select('id').eq('subchapter_id', subChapterId).maybeSingle();

      if (existingVideo != null) {
        throw Exception('Video dengan subchapter $subChapterId sudah ada pada subchapter ini.');
      }

      final videoUrl = await uploadVideo(videoPath, title);
      if (videoUrl == null) {
        throw Exception('Gagal mengunggah video baru.');
      }

      await _supabase.from('videos').insert({'video_name': title, 'subchapter_id': subChapterId, 'video_url': videoUrl});
      log('[insertVideo] Successfully inserted new video with title: $title');
    } catch (e) {
      log('[insertVideo] Error inserting chapter: $e');
      rethrow;
    }
  }

  Future<void> deleteVideofromTable(String videoId, String videoUrl) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak, Hanya guru yang dapat mengubah video simulasi.');
      }

      final currentVideo = await _supabase.from('videos').select('*').eq('id', videoId).maybeSingle();
      if (currentVideo == null) {
        throw Exception('Video yang akan diubah tidak ditemukan.');
      }

      final isDeleted = await deleteVideoFromStorage(videoUrl);
      if (!isDeleted) {
        throw Exception('Gagal menghapus video $videoUrl.');
      }

      await _supabase.from('videos').update({'video_url': null}).eq('id', videoId);
      log('[deleteVideofromTable] Successfully delete video $videoId from $videoUrl');

    } catch (e) {
      log('[deleteVideofromTable] Error deleting video $videoId: $e');
      rethrow;
    }
  }

  Future<void> upsertEssentialQuestion(String subChapterId, String essentialQuestion) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menambahkan atau mengubah essential question.');
      }

      await _supabase.from('essential_feedbacks').upsert({
        'subchapter_id': subChapterId,
        'essential_question': essentialQuestion,
      }, onConflict: 'subchapter_id');
      log('[upsertEssentialQuestion] Successfully upserted essential question for subchapter: $subChapterId');
    } catch (e) {
      log('[upsertEssentialQuestion] Error upserting essential question: $e');
      rethrow;
    }
  }

  Future<void> upsertChatbotFlow(String subChapterId, List<dynamic> flowData) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah eksplorasi materi.');
      }

      final existing = await _supabase
          .from('learning_materials')
          .select('id')
          .eq('subchapter_id', subChapterId)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('learning_materials').update({
          'flow_data': flowData,
        }).eq('subchapter_id', subChapterId);
      } else {
        await _supabase.from('learning_materials').insert({
          'subchapter_id': subChapterId,
          'flow_data': flowData,
        });
      }
      log('[upsertChatbotFlow] Successfully upserted flow data for subchapter: $subChapterId');
    } catch (e) {
      log('[upsertChatbotFlow] Error upserting flow data: $e');
      rethrow;
    }
  }

  Future<void> upsertMindmap(String subChapterId, List<dynamic> subjects) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah mindmap.');
      }

      final existing = await _supabase
          .from('mind_maps')
          .select('id')
          .eq('subchapter_id', subChapterId)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('mind_maps').update({
          'subjects': subjects,
        }).eq('subchapter_id', subChapterId);
      } else {
        await _supabase.from('mind_maps').insert({
          'subchapter_id': subChapterId,
          'subjects': subjects,
        });
      }
      log('[upsertMindmap] Successfully upserted mindmap for subchapter: $subChapterId');
    } catch (e) {
      log('[upsertMindmap] Error upserting mindmap: $e');
      rethrow;
    }
  }

  Future<void> upsertQuizData(String subChapterId, String type, String title, List<dynamic> questions) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah kuis.');
      }

      final existing = await _supabase
          .from('quizzes')
          .select('id')
          .eq('subchapter_id', subChapterId)
          .eq('type', type)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('quizzes').update({
          'title': title,
          'question_jsonb': questions,
        }).eq('subchapter_id', subChapterId).eq('type', type);
      } else {
        await _supabase.from('quizzes').insert({
          'subchapter_id': subChapterId,
          'type': type,
          'title': title,
          'question_jsonb': questions,
          'created_by': getCurrentUserId(),
        });
      }
      log('[upsertQuizData] Successfully upserted quiz for subchapter: $subChapterId');
    } catch (e) {
      log('[upsertQuizData] Error upserting quiz: $e');
      rethrow;
    }
  }

  Future<void> upsertPrompt(String type, String promptText) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat mengubah prompt.');
      }

      final existing = await _supabase
          .from('prompts')
          .select('id')
          .eq('type', type)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('prompts').update({
          'prompt_text': promptText,
        }).eq('type', type);
      } else {
        await _supabase.from('prompts').insert({
          'type': type,
          'prompt_text': promptText,
        });
      }
      log('[upsertPrompt] Successfully upserted prompt for type: $type');
    } catch (e) {
      log('[upsertPrompt] Error upserting prompt: $e');
      rethrow;
    }
  }

  Future<void> deleteQuizById(String quizId, String typeQuiz) async {
    try {
      final role = await getUserRole();
      if (role != 'teacher') {
        throw Exception('Akses ditolak: Hanya guru yang dapat menghapus kuis.');
      }

      await _supabase.from('quizzes').delete().eq('id', quizId).eq('type', typeQuiz);
      log('[deleteQuizById] Successfully deleted quiz $quizId of type $typeQuiz');
    } catch (e) {
      log('[deleteQuizById] Error deleting quiz: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> getAllStudents() async {
    try {
      final students = await _supabase.from('profiles').select('*, classes(class_name)').eq('role', 'student');
      log('[getAllStudents] response: $students');
      return students;
    } catch (e) {
      log('[getAllStudents] Error fetching profiles: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final students = await _supabase.from('profiles').select('*, classes(class_name)').eq('id', userId).single();
      log('[getProfileById] response: $students');
      return students;
    } catch (e) {
      log('[getProfileById] Error fetching profile: $e');
      rethrow;
    }
  }
}
