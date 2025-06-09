import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/services/character_manager.dart';

class DeepLinkHelper {
  static Future<Map<String, dynamic>?> processCharacterData(
    String uuid,
  ) async {
    final String platform = defaultTargetPlatform.name;
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
    try {
      final response = await http.get(Uri.parse('$baseUrl/loadQR/$uuid'));
      if (response.statusCode != 200) {
        print('[DeepLinkHelper][$platform] loadQR 실패: ${response.statusCode}');
        return null;
      }
      final characterData = jsonDecode(response.body) as Map<String, dynamic>;

      if (!_isValidCharacterData(characterData)) {
        print('[DeepLinkHelper][$platform] 유효하지 않은 캐릭터 데이터 형식.');
        return null;
      }

      final personaId = characterData['personaId'] as String?;
      if (personaId == null) {
        print('[DeepLinkHelper][$platform] personaId 누락');
        return null;
      }

      await CharacterManager.instance.handleCharacterFromQR(personaId);
      print('[DeepLinkHelper][$platform] 사용자-캐릭터 관계 생성 완료');

      return {
        'characterName': characterData['name'] as String,
        'personalityTags': List<String>.from(characterData['tags'] as List),
        'greeting': characterData['greeting'] as String?,
        'personaId': personaId,
      };
    } catch (e, s) {
      print('[DeepLinkHelper][$platform] 데이터 처리 중 오류: $e');
      print('[DeepLinkHelper][$platform] Stacktrace: $s');
      return null;
    }
  }

  static bool _isValidCharacterData(Map<String, dynamic> data) {
    final isValid =
        data.containsKey('name') &&
        data.containsKey('tags') &&
        data.containsKey('personaId') &&
        data['name'] is String &&
        data['tags'] is List &&
        data['personaId'] is String;

    return isValid;
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    print(
      '[DeepLinkHelper][${defaultTargetPlatform.name}] showError: 오류 메시지: $message',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
