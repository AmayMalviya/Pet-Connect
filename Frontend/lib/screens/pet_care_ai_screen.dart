import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/ai_message.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/services/ai_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart' show AppColors;
import 'package:uuid/uuid.dart';

class PetCareAIScreen extends StatefulWidget {
  final Pet pet;
  final String topic; // 'grooming', 'diet', 'exercise', 'training'
  final String topicTitle;

  const PetCareAIScreen({
    super.key,
    required this.pet,
    required this.topic,
    required this.topicTitle,
  });

  @override
  State<PetCareAIScreen> createState() => _PetCareAIScreenState();
}

class _PetCareAIScreenState extends State<PetCareAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  late String _conversationId;
  List<AIMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Quick question suggestions based on topic
  late List<String> _quickQuestions;

  @override
  void initState() {
    super.initState();
    _conversationId = const Uuid().v4();
    _quickQuestions = _getQuickQuestions();
    _initialize();
  }

  List<String> _getQuickQuestions() {
    switch (widget.topic.toLowerCase()) {
      case 'grooming':
        return [
          'How often should I bathe my ${widget.pet.animal}?',
          'Tips for brushing ${widget.pet.name}\'s coat',
          'How to trim nails safely',
          'Best grooming tools for ${widget.pet.breed}',
        ];
      case 'diet':
        return [
          'What\'s the best food for ${widget.pet.name}?',
          'How much should I feed daily?',
          'What foods are toxic for ${widget.pet.animal}s?',
          'Diet recommendations for ${widget.pet.age} year old',
        ];
      case 'exercise':
        return [
          'How much exercise does ${widget.pet.name} need?',
          'Best activities for a ${widget.pet.animal}',
          'Indoor exercise ideas',
          'How to keep ${widget.pet.name} active and healthy',
        ];
      case 'training':
        return [
          'How to train ${widget.pet.name} basic commands',
          'Tips for addressing behavioral issues',
          'Positive reinforcement techniques',
          'Housetraining advice for ${widget.pet.animal}s',
        ];
      default:
        return [
          'Tell me more about this topic',
          'What are the best practices?',
          'Any specific recommendations?',
        ];
    }
  }

  Future<void> _initialize() async {
    try {
      await _aiService.initialize();

      // Load cached messages if available
      _messages = _aiService.getConversationHistory(_conversationId);

      setState(() => _isInitialized = true);

      // Send initial greeting if no messages
      if (_messages.isEmpty) {
        _sendInitialGreeting();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize chat: $e';
        _isInitialized = true;
      });
    }
  }

  Future<void> _sendInitialGreeting() async {
    final greeting =
        'Hello! I\'m here to help with ${widget.topicTitle.toLowerCase()} tips for ${widget.pet.name}. What would you like to know?';

    final aiMessage = AIMessage(
      id: const Uuid().v4(),
      content: greeting,
      isUserMessage: false,
      timestamp: DateTime.now(),
      mode: 'pet_care',
      metadata: {'topic': widget.topic},
    );

    setState(() {
      _messages.add(aiMessage);
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI immediately
    final userMessage = AIMessage(
      id: const Uuid().v4(),
      content: message,
      isUserMessage: true,
      timestamp: DateTime.now(),
      mode: 'pet_care',
      metadata: {'topic': widget.topic},
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
      _error = null;
    });

    _scrollToBottom();

    try {
      // Send to AI with pet context
      final response = await _aiService.sendMessage(
        message: message,
        mode: 'pet_care',
        pet: widget.pet,
        topic: widget.topic,
      );

      final aiMessage = AIMessage(
        id: const Uuid().v4(),
        content: response.content,
        isUserMessage: false,
        timestamp: DateTime.now(),
        mode: 'pet_care',
        metadata: {'topic': widget.topic},
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to get response: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicTitle), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.topicTitle),
            Text(
              'Ask AI about ${widget.pet.name}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getTopicIcon(),
                        const SizedBox(height: 16),
                        Text(
                          widget.topicTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get expert advice for ${widget.pet.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Quick questions
          if (_messages.length <= 1 && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick questions:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions.map((question) {
                      return GestureDetector(
                        onTap: () => _sendMessage(question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            question,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText:
                          'Ask about ${widget.topicTitle.toLowerCase()}...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    enabled: !_isLoading,
                    onSubmitted: _isLoading ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'pet_care_ai_fab',
                  mini: true,
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                  backgroundColor: AppColors.primary,
                  disabledElevation: 0,
                  child: Icon(
                    Icons.send,
                    color: _isLoading ? Colors.grey[400] : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: message.isUserMessage
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isUserMessage ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: message.isUserMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: message.isUserMessage ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: message.isUserMessage
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTopicIcon() {
    IconData icon;
    Color color;

    switch (widget.topic.toLowerCase()) {
      case 'grooming':
        icon = Icons.spa;
        color = Colors.purple;
        break;
      case 'diet':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'exercise':
        icon = Icons.directions_run;
        color = Colors.green;
        break;
      case 'training':
        icon = Icons.school;
        color = Colors.blue;
        break;
      default:
        icon = Icons.pets;
        color = AppColors.primary;
    }

    return Icon(icon, size: 64, color: color.withOpacity(0.3));
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
