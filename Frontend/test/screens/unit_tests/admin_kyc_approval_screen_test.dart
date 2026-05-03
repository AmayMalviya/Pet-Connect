// ignore_for_file: undefined_named_parameter, argument_type_not_assignable, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// Mocks
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockPostgrestQueryBuilder extends Mock
    implements supabase.PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements supabase.PostgrestFilterBuilder<T> {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  group('AdminKycApprovalScreen', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder<List<Map<String, dynamic>>>
    mockFilterBuilder;
    late MockGoTrueClient mockGoTrueClient;

    setUp(() async {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockGoTrueClient = MockGoTrueClient();

      // Initialize a dummy Supabase instance with our mock client
      await supabase.Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test.anon.key',
        client: mockSupabaseClient,
      );

      // Stub the auth client
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

      // Stub the chain of calls from `from` -> `select` -> `filter`
      when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.or(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
      when(
        mockFilterBuilder.order(any, ascending: anyNamed('ascending')),
      ).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.limit(any)).thenReturn(mockFilterBuilder);
    });

    testWidgets('should display a list of KYC profiles', (
      WidgetTester tester,
    ) async {
      // Arrange
      final profiles = [
        {
          'user_id': '1',
          'first_name': 'Test Shelter',
          'email': 'shelter@test.com',
          'phone': '1234567890',
          'city': 'Test City',
          'state': 'Test State',
          'country': 'Test Country',
          'kyc_verified': false,
          'role': 'Shelter',
        },
      ];
      final kycDocs = [
        {'user_id': '1', 'aadhaar_number': '1234-5678-9012'},
      ];
      final kycPersonal = [
        {'user_id': '1', 'full_name': 'Test Person'},
      ];

      // Stub the specific responses for the calls in _fetchPendingKyc
      when(
        mockFilterBuilder.eq('kyc_verified', false),
      ).thenAnswer((_) async => profiles);
      when(
        mockFilterBuilder.eq('user_id', '1'),
      ).thenAnswer((_) async => kycDocs);
      when(
        mockSupabaseClient
            .from('kyc_personal')
            .select('*')
            .eq('user_id', '1')
            .order('created_at', ascending: false)
            .limit(1),
      ).thenAnswer((_) async => kycPersonal);

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: AdminKycApprovalScreen()),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Shelter'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });
  });
}
