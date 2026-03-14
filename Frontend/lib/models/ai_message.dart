class AIMessage {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? mode; // 'global', 'pet_care', 'shopping'
  final Map<String, dynamic>? metadata; // additional context

  AIMessage({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
    this.mode,
    this.metadata,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mode: json['mode'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode,
      'metadata': metadata,
    };
  }
}

class AIConversation {
  final String id;
  final String userId;
  final String mode; // 'global', 'pet_care', 'shopping'
  final String? petId;
  final String?
  topic; // for pet_care: 'grooming', 'diet', 'exercise', 'training'
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime lastUpdated;

  AIConversation({
    required this.id,
    required this.userId,
    required this.mode,
    this.petId,
    this.topic,
    required this.messages,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mode: json['mode'] as String,
      petId: json['petId'] as String?,
      topic: json['topic'] as String?,
      messages:
          (json['messages'] as List?)
              ?.map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mode': mode,
      'petId': petId,
      'topic': topic,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class AIResponse {
  final String content;
  final Map<String, dynamic>? structuredData; // for product suggestions, etc.
  final String model;
  final int tokensUsed;

  AIResponse({
    required this.content,
    this.structuredData,
    required this.model,
    required this.tokensUsed,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      content: json['content'] as String,
      structuredData: json['structuredData'] as Map<String, dynamic>?,
      model: json['model'] as String,
      tokensUsed: json['tokensUsed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'structuredData': structuredData,
      'model': model,
      'tokensUsed': tokensUsed,
    };
  }
}
