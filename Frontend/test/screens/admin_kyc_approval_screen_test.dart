import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_connect_app/models/user.dart';
import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockFunctionsClient extends Mock implements supabase.FunctionsClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}
class MockRealtimeClient extends Mock implements supabase.RealtimeClient {}
class MockPostgrestClient extends Mock implements supabase.PostgrestClient {}

void main() {
  group('AdminKycApprovalScreen', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockFunctionsClient mockFunctionsClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockRealtimeClient mockRealtimeClient;
    late MockPostgrestClient mockPostgrestClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockFunctionsClient = MockFunctionsClient();
      mockGoTrueClient = MockGoTrueClient();
      mockRealtimeClient = MockRealtimeClient();
      mockPostgrestClient = MockPostgrestClient();

      when(mockSupabaseClient.functions).thenReturn(mockFunctionsClient);
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(mockSupabaseClient.realtime).thenReturn(mockRealtimeClient);
      when(mockSupabaseClient.from(any)).thenReturn(mockPostgrestClient);
    });

    testWidgets('should display a list of KYC profiles', (WidgetTester tester) async {
      // Stub the Supabase.instance.client to return our mock
      final client = mockSupabaseClient;
      supabase.Supabase.initialize(url: 'https://test.com', anonKey: 'test-key', authCallback: (_) {},);

      // Arrange
      final profiles = [
        User(uid: '1', email: 'test1@test.com', displayName: 'Test User 1'),
        User(uid: '2', email: 'test2@test.com', displayName: 'Test User 2'),
      ];
      when(mockPostgrestClient.select()).thenAnswer((_) async => profiles.map((e) => e.toJson()).toList());

      // Act
      await tester.pumpWidget(MaterialApp(home: AdminKycApprovalScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test User 1'), findsOneWidget);
      expect(find.text('Test User 2'), findsOneWidget);
    });
  });
}
