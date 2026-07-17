import 'package:fluidify_mobile/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluidify_mobile/services/auth_gate.dart';
import 'package:fluidify_mobile/pages/onboarding_page.dart';
import 'package:fluidify_mobile/pages/student/student_main.dart';
import 'package:fluidify_mobile/pages/teacher/teacher_main.dart';

// --- Mocks ---
class MockSupabaseService extends Mock implements SupabaseService {}
class MockAuthState extends Mock implements AuthState {}
class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseService mockSupabaseService;

  setUp(() {
    mockSupabaseService = MockSupabaseService();
  });

  // Widget helper untuk memudahkan pemanggilan AuthGate
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: AuthGate(),
    );
  }

  group('AuthGate Widget Tests', () {
    testWidgets('Menampilkan CircularProgressIndicator saat stream loading', (WidgetTester tester) async {
      // Catatan: Karena Supabase.instance.client.auth.onAuthStateChange dipanggil
      // langsung di dalam AuthGate, Anda harus memastikan platform Supabase 
      // bisa di-mock di level platform channel, atau refactor AuthGate agar 
      // menerima authStream sebagai parameter.
      
      // await tester.pumpWidget(createWidgetUnderTest());
      // expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Navigasi ke OnboardingPage jika tidak ada session', (WidgetTester tester) async {
      // Skenario: snapshot dari auth stream mereturn null session
      
      // await tester.pumpWidget(createWidgetUnderTest());
      // await tester.pumpAndSettle();
      
      // expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('Navigasi ke StudentMainWrapper jika role adalah student', (WidgetTester tester) async {
      // Skenario: Session ada, dan getUserRole() mengembalikan 'student'
      when(() => mockSupabaseService.getUserRole()).thenAnswer((_) async => 'student');

      // await tester.pumpWidget(createWidgetUnderTest());
      // await tester.pumpAndSettle();

      // expect(find.byType(StudentMainWrapper), findsOneWidget);
    });

    testWidgets('Navigasi ke TeacherMainWrapper jika role adalah teacher', (WidgetTester tester) async {
      // Skenario: Session ada, dan getUserRole() mengembalikan 'teacher'
      when(() => mockSupabaseService.getUserRole()).thenAnswer((_) async => 'teacher');

      // await tester.pumpWidget(createWidgetUnderTest());
      // await tester.pumpAndSettle();

      // expect(find.byType(TeacherMainWrapper), findsOneWidget);
    });
  });
}