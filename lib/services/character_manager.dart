import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/services/firebase_manager.dart';

class CharacterManager {
  static CharacterManager? _instance;
  static CharacterManager get instance => _instance ??= CharacterManager._();
  CharacterManager._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // QR에서 캐릭터 처리 (사용자-캐릭터 관계만 생성)
  Future<String> handleCharacterFromQR(String personaId) async {
    try {
      final user = await FirebaseManager.instance.getCurrentUser();
      if (user == null) throw Exception('사용자 인증 실패');
      await _createUserInteraction(personaId, user.uid);
      return personaId;
    } catch (e) {
      print("❌ 캐릭터 처리 실패: $e");
      rethrow;
    }
  }

  // QR Profile 저장
  Future<void> _saveQRProfile(String personaId, Map<String, dynamic> data, String userId) async {
    await _firestore.collection('qr_profiles').doc(personaId).set({
      'personaId': personaId,
      'name': data['name'],
      'tags': data['tags'],
      'greeting': data['greeting'] ?? '안녕하세요!',
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'totalInteractions': 0,
      'uniqueUsers': 0,
    }, SetOptions(merge: true));
  }

  // QR 프로필 저장 (Cloud Function 호출)
  Future<String> saveCharacterForQR(Map<String, dynamic> data) async {
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
    final body = jsonEncode(data);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/createQR'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['uuid'] as String;
      } else {
        throw Exception('Failed to create QR profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ saveCharacterForQR 실패: $e');
      rethrow;
    }
  }

  // 사용자-캐릭터 관계 생성
  Future<void> _createUserInteraction(String personaId, String userId) async {
    final interactionId = "${userId}_$personaId";
    await _firestore.collection('user_interactions').doc(interactionId).set({
      'userId': userId,
      'personaId': personaId,
      'firstMetAt': FieldValue.serverTimestamp(),
      'lastInteractionAt': FieldValue.serverTimestamp(),
      'totalSessions': 0,
      'totalMessages': 0,
      'isFavorite': false,
    }, SetOptions(merge: true));
  }

  // Firebase에서 캐릭터 로드
  Future<Map<String, dynamic>?> loadCharacter(String personaId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('qr_profiles').doc(personaId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("❌ 캐릭터 로드 실패: $e");
      return null;
    }
  }
}