import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRegister {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    String? institutionCode,
    required String password,
    required String accountType,
  }) async {
    String? institutionId;

    // If the account type requires an institution (caregiver), validate it
    if (accountType == 'caregiver') {
      if (institutionCode == null || institutionCode.trim().isEmpty) {
        throw Exception('Código da instituição inválido');
      }

      // Parte que procura a instituição pelo código
      final institutionQuery = await _firestore
          .collection('institutions')
          .where('code', isEqualTo: institutionCode.trim())
          .limit(1)
          .get();

      // Se não tiver instituição, o cadastro não é feito
      if (institutionQuery.docs.isEmpty) {
        throw Exception('Código da instituição inválido');
      }

      // Pega o documento da instituição encontrada
      final institutionDoc = institutionQuery.docs.first;

      // Id gerado pelo Firebase para a instituição encontrada
      institutionId = institutionDoc.id;
    }

    // Cria o usuário no Firebase Authentication
     final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
     );

     final user = userCredential.user;

     if (user == null) {
      throw Exception('Falha ao criar usuário');
     }

     final userData = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'type': accountType,
      'createdAt': FieldValue.serverTimestamp(),
     };

     if (institutionId != null) {
       userData['institutionId'] = institutionId;
     }

     await _firestore.collection('users').doc(user.uid).set(userData);
     
  }
}