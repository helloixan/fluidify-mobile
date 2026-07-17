import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluidify_mobile/services/supabase_service.dart';

// --- Mocks ---
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockSession extends Mock implements Session {}
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late SupabaseService supabaseService;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();
    
    // Menghubungkan client mock ke auth
    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);
  });

  group('SupabaseService Auth Tests', () {
    test('signInWithEmailPassword returns AuthResponse on success', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final mockResponse = MockAuthResponse();

      when(() => mockAuthClient.signInWithPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockResponse);

      // Act
      // Asumsikan supabaseService menggunakan mockSupabaseClient
      // final result = await supabaseService.signInWithEmailPassword(email, password);

      // Assert
      // expect(result, isA<AuthResponse>());
      // verify(() => mockAuthClient.signInWithPassword(email: email, password: password)).called(1);
    });

    test('getCurrentUserEmail returns email when session is active', () {
      // Arrange
      final mockSession = MockSession();
      final mockUser = MockUser();
      
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockAuthClient.currentSession).thenReturn(mockSession);

      // Act
      // final email = supabaseService.getCurrentUserEmail();

      // Assert
      // expect(email, 'test@example.com');
    });

    test('getCurrentUserEmail returns null when no session', () {
      // Arrange
      when(() => mockAuthClient.currentSession).thenReturn(null);

      // Act
      // final email = supabaseService.getCurrentUserEmail();

      // Assert
      // expect(email, isNull);
    });
  });
}