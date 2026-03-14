import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pet_connect_app/models/ai_message.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AIService {
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'openai/gpt-oss-120b';
  static const Duration _requestTimeout = Duration(seconds: 30);

  final Dio _dio;

  late SharedPreferences _prefs;
  final Map<String, List<AIMessage>> _conversationCache = {};

  AIService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _groqBaseUrl,
              connectTimeout: _requestTimeout,
              receiveTimeout: _requestTimeout,
            ),
          );

  /// Initialize the AIService with SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedConversations();
  }

  /// Send a message to Groq AI with different modes
  ///
  /// [mode] can be: 'global', 'pet_care', 'shopping'
  /// [pet] is the pet profile context
  /// [message] is the user's question
  /// [topic] is for pet_care mode: 'grooming', 'diet', 'exercise', 'training'
  Future<AIResponse> sendMessage({
    required String message,
    required String mode,
    Pet? pet,
    String? topic,
    String? query,
  }) async {
    try {
      final apiKey = _getApiKey(mode);
      final systemPrompt = _buildSystemPrompt(mode, pet, topic);
      final userMessage = _buildUserMessage(mode, pet, message, topic, query);

      print('--- Sending request to Groq API ---');
      print('System Prompt: $systemPrompt');
      print('User Message: $userMessage');
      print('------------------------------------');

      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': mode == 'shopping' ? 500 : 1000,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final content =
            response.data['choices'][0]['message']['content'] as String;
        final tokensUsed =
            (response.data['usage']['total_tokens'] as int?) ?? 0;

        // Parse structured data if it's a product suggestion response
        Map<String, dynamic>? structuredData;
        if (mode == 'shopping') {
          structuredData = _parseProductSuggestions(content);
        }

        return AIResponse(
          content: content,
          structuredData: structuredData,
          model: _model,
          tokensUsed: tokensUsed,
        );
      } else {
        throw Exception(
          'Failed to get response from Groq: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }

  /// Build system prompt based on mode
  String _buildSystemPrompt(String mode, Pet? pet, String? topic) {
    switch (mode) {
      case 'global':
        return '''You are Pet Connect AI Assistant, a knowledgeable and friendly pet care expert. 
You help pet owners with general pet-related questions including:
- Pet care and health tips
- Behavioral guidance
- Training advice
- General pet wellness

Be concise, practical, and empathetic. Always prioritize pet safety and health. 
Recommend consulting a veterinarian for medical concerns.
Respond in a warm, encouraging tone suitable for pet lovers.''';

      case 'pet_care':
        final topicGuidance = _getTopicGuidance(topic);
        return '''You are a specialized Pet Care AI Assistant helping pet owners with specific pet care topics.
Your expertise is in: $topicGuidance

Current pet context:
- Name: ${pet?.name ?? 'Unknown'}
- Type: ${pet?.animal ?? 'Unknown'}
- Breed: ${pet?.breed ?? 'Not specified'}
- Age: ${pet?.age ?? 'Unknown'} years
- Weight: ${pet?.weightKg ?? 'Unknown'} kg
- Activity Level: ${pet?.activityLevel ?? 'Moderate'}
- Health Status: ${pet?.healthStatus ?? 'Good'}
- Special Needs: ${pet?.specialNeeds ?? 'None'}

Provide detailed, actionable advice specific to this pet's profile. Be practical and considerate of the pet's specific needs.''';

      case 'shopping':
        return '''You are a Pet Shopping AI Assistant that helps find the perfect pet products.
Your role is to:
1. Understand what the pet owner needs
2. Consider their specific pet type and characteristics
3. Suggest relevant products with practical details

When suggesting products, provide structured information about:
- Product name
- Category
- Why it's good for this pet
- Estimated price range
- Where to find it

Be helpful and consider both budget and pet wellbeing.''';

      default:
        return 'You are a helpful Pet Connect AI Assistant.';
    }
  }

  /// Get guidance text for specific pet care topics
  String _getTopicGuidance(String? topic) {
    switch (topic?.toLowerCase()) {
      case 'grooming':
        return 'Pet grooming, bathing, coat care, nail trimming, and hygiene maintenance';
      case 'diet':
        return 'Pet nutrition, diet plans, food recommendations, and feeding schedules';
      case 'exercise':
        return 'Physical activity, exercise routines, play time, and fitness levels';
      case 'training':
        return 'Obedience training, behavioral correction, command teaching, and positive reinforcement';
      default:
        return 'General pet care';
    }
  }

  /// Build detailed user message based on mode
  String _buildUserMessage(
    String mode,
    Pet? pet,
    String message,
    String? topic,
    String? query,
  ) {
    switch (mode) {
      case 'global':
        return message;

      case 'pet_care':
        return '''I need help with $topic for my ${pet?.animal ?? 'pet'} named ${pet?.name ?? 'Buddy'}.

Pet Details:
- Breed: ${pet?.breed ?? 'Mixed'}
- Age: ${pet?.age ?? 'Unknown'} years old
- Weight: ${pet?.weightKg ?? 'Unknown'} kg
- Current situation: $message

Please provide specific advice.''';

      case 'shopping':
        return '''I'm looking for pet products for my ${pet?.animal ?? 'pet'}.

Pet Profile:
- Type: ${pet?.animal ?? 'Unknown'}
- Breed: ${pet?.breed ?? 'Unknown'}
- Age: ${pet?.age ?? 'Unknown'} years
- Special needs: ${pet?.specialNeeds ?? 'None'}

My query: $message
Category preference: ${query ?? 'No specific category'}

Please recommend suitable products and where to find them.''';

      default:
        return message;
    }
  }

  /// Get the Groq API key from environment variables.
  ///
  /// Supports three modes:
  /// - `GROQ_API_KEY_GLOBAL` (fallback for all modes)
  /// - `GROQ_API_KEY_PET_CARE`
  /// - `GROQ_API_KEY_SHOPPING`
  ///
  /// These should be set in a `.env` file or as environment variables in the
  /// runtime environment.
  String _getApiKey(String mode) {
    final keyName = 'GROQ_API_KEY_${mode.toUpperCase()}';
    final apiKey = dotenv.env[keyName] ?? dotenv.env['GROQ_API_KEY_GLOBAL'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Missing Groq API key. Set $keyName or GROQ_API_KEY_GLOBAL in your .env.',
      );
    }
    return apiKey;
  }

  /// Parse product suggestions from AI response
  Map<String, dynamic>? _parseProductSuggestions(String content) {
    try {
      // Extract product information from the response
      // This is a simple parser - can be enhanced based on actual response format
      final suggestions = {
        'recommendations': content,
        'parsed':
            false, // Flag for whether we successfully parsed structured data
      };
      return suggestions;
    } catch (e) {
      return null;
    }
  }

  /// Load cached conversations from preferences
  void _loadCachedConversations() {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('conversation_')) {
        final conversationId = key.replaceFirst('conversation_', '');
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final messagesJson = jsonDecode(jsonString) as List;
            _conversationCache[conversationId] = messagesJson
                .map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
                .toList();
          } catch (e) {
            // Handle parsing error
          }
        }
      }
    }
  }

  /// Get conversation history
  List<AIMessage> getConversationHistory(String conversationId) {
    return _conversationCache[conversationId] ?? [];
  }

  /// Clear conversation
  Future<void> clearConversation(String conversationId) async {
    _conversationCache.remove(conversationId);
    await _prefs.remove('conversation_$conversationId');
  }

  /// Clear all conversations
  Future<void> clearAllConversations() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('conversation_')) {
        await _prefs.remove(key);
      }
    }
    _conversationCache.clear();
  }

  /// Check if API is healthy
  Future<bool> healthCheck() async {
    try {
      // Try a simple request to verify API connectivity
      final response = await _sendHealthCheck();
      return response;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _sendHealthCheck() async {
    try {
      final apiKey = _apiKeys['global']!;
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 10,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

/// Response from AI
class AIResponse {
  final String content;
  final Map<String, dynamic>? structuredData;
  final String model;
  final int tokensUsed;

  AIResponse({
    required this.content,
    this.structuredData,
    required this.model,
    required this.tokensUsed,
  });
}
