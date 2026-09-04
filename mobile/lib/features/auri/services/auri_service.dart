import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AuriService {
  AuriService({FirebaseFirestore? firestore, GenerativeModel? model})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _model =
          model ??
          GenerativeModel(
            model: 'gemini-3.6-flash',
            apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
          ),
      _fallbackModel = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      );

  static const _systemInstruction =
      'Você é o Auri, um assistente virtual paciente, carinhoso e '
      'extremamente simples para idosos. Seu objetivo é ensinar como usar '
      'celulares, redes sociais (Instagram, WhatsApp, YouTube) e configurações '
      'do aparelho. Responda em até 3 frases curtas, usando lista numerada se '
      'for um passo a passo. NUNCA use termos técnicos sem explicar de forma simples.';

  final FirebaseFirestore _firestore;
  final GenerativeModel _model;
  final GenerativeModel _fallbackModel;

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String userId) {
    return _firestore
        .collection('auriChats')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> ask({required String userId, required String question}) async {
    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty) return;

    final chat = _firestore.collection('auriChats').doc(userId);
    final messages = chat.collection('messages');
    await messages.add({
      'sender': 'user',
      'text': normalizedQuestion,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chat.set({
      'userId': userId,
      'lastInteraction': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final recent = await messages
        .orderBy('createdAt', descending: true)
        .limit(12)
        .get();
    final history = recent.docs.reversed
        .map(
          (document) => Content(
            document.data()['sender'] == 'auri' ? 'model' : 'user',
            [TextPart(document.data()['text']?.toString() ?? '')],
          ),
        )
        .toList();
    // Keep the assistant guidance in the request history for compatibility
    // with API versions that do not accept a systemInstruction parameter.
    history.insert(0, Content.text(_systemInstruction));

    final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'A chave do Gemini não foi configurada. '
        'Execute com --dart-define=GEMINI_API_KEY=SUA_CHAVE.',
      );
    }

    late final GenerateContentResponse response;
    try {
      response = await _model.generateContent(history);
    } on GenerativeAIException catch (error) {
      if (!_isServerFailure(error)) rethrow;

      try {
        response = await _fallbackModel.generateContent(history);
      } on GenerativeAIException {
        throw StateError(
          'O Auri está um pouco ocupado agora. '
          'Tente novamente em alguns instantes.',
        );
      }
    }
    final answer = response.text?.trim();
    if (answer == null || answer.isEmpty) {
      throw StateError('O Auri não retornou uma resposta.');
    }

    await messages.add({
      'sender': 'auri',
      'text': answer,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chat.set({
      'userId': userId,
      'lastInteraction': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool _isServerFailure(GenerativeAIException error) {
    if (error is ServerException) return true;

    final message = error.message.toLowerCase();
    return message.contains('503') ||
        message.contains('unavailable') ||
        message.contains('server error') ||
        message.contains('temporarily');
  }
}
