import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nompangs/services/conversation_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/services/openai_chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ConversationService _conversationService = ConversationService();
  final OpenAiChatService _chatService = OpenAiChatService();
  final OpenAiTtsService _ttsService = OpenAiTtsService();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // 로그인된 사용자의 UID
  final String uid;

  late final String uuid;
  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;

  ChatProvider({required Map<String, dynamic> characterProfile})
      : uid = FirebaseAuth.instance.currentUser!.uid, // 생성 시점에서 uid 확보
        greeting = characterProfile['greeting'] as String? {
    uuid = characterProfile['uuid'] ??
        'temp_uuid_${DateTime.now().millisecondsSinceEpoch}';
    characterName =
        characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음';
    characterHandle =
        '@${(characterProfile['aiPersonalityProfile']?['name'] ?? 'unknown').toLowerCase().replaceAll(' ', '')}';
    personalityTags = (characterProfile['personalityTags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        [];
    
    _initializeChat();
  }
  
  void _initializeChat() {
    _sendInitialGreetingIfNeeded();
  }

  Future<void> _sendInitialGreetingIfNeeded() async {
    final messagesStream = getMessagesStream();
    final snapshot = await messagesStream.first;
    if (snapshot.docs.isEmpty && greeting != null && greeting!.isNotEmpty) {
      // 초기 인사말은 LLM을 호출하지 않고, bot 메시지로 직접 저장합니다.
      await _conversationService.sendMessage(uid, uuid, greeting!, 'bot');
    }
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return _conversationService.getMessagesStream(uid, uuid);
  }

  Future<void> stopTts() async {
    await _ttsService.stop();
  }

  Future<void> sendMessage(String text, {bool isInitialGreeting = false}) async {
    if (text.trim().isEmpty || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      if (!isInitialGreeting) {
        await _conversationService.sendMessage(uid, uuid, text, 'user');
      }

      final context = await _conversationService.getConversationContext(uid, uuid);

      final botResponse = await _chatService.getResponseFromGpt(
          context['summary'], (context['recentMessages'] as List).cast<Map<String, dynamic>>(), text);

      await _conversationService.sendMessage(uid, uuid, botResponse, 'bot');

      // 요약 트리거 로직 추가
      _triggerSummaryIfNeeded();

      await _ttsService.speak(botResponse);

    } catch (e) {
      debugPrint("메시지 전송/처리 중 에러 발생: $e");
      try {
        await _conversationService.sendMessage(uid, uuid, "오류가 발생했어요: $e", 'bot');
      } catch (e2) {
        debugPrint("오류 메시지 저장 실패: $e2");
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // 요약 실행을 확인하고 트리거하는 메서드
  Future<void> _triggerSummaryIfNeeded() async {
    try {
      final conversationDoc = await _conversationService.getConversationDocument(uid, uuid);
      if (!conversationDoc.exists) return;

      final data = conversationDoc.data() as Map<String, dynamic>;
      final messageCount = data['messageCount'] ?? 0;

      if (messageCount > 0 && messageCount % 10 == 0) {
        debugPrint("🚀 요약 조건 충족 (메시지: $messageCount). 요약을 시작합니다.");

        // 요약에 필요한 데이터 가져오기
        final summaryContext = await _conversationService.getConversationContext(uid, uuid);
        final currentSummary = summaryContext['summary'] as String?;
        final messagesToSummarize =
            (summaryContext['recentMessages'] as List).cast<Map<String, dynamic>>();

        // 요약 실행
        final newSummary = await _chatService.summarizeConversation(
            currentSummary, messagesToSummarize);

        // Firestore에 새로운 요약 업데이트
        await _conversationService.updateSummary(uid, uuid, newSummary);
        debugPrint("✅ 새로운 요약이 Firestore에 저장되었습니다.");
      }
    } catch (e) {
      debugPrint("🚨 요약 실행 중 오류 발생: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
