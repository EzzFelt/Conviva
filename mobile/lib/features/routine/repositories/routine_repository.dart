
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/family_link_id.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../models/routine_elder_summary.dart';
import '../models/routine_permissions.dart';
import '../models/routine_task.dart';
import '../models/routine_task_completion.dart';

class RoutineRepository {
  RoutineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final RoutineRepository instance = RoutineRepository();

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _routineDocument(
    String elderId,
  ) {
    return _firestore.collection('routines').doc(elderId);
  }

  // --------------------------------------------------
  // ROUTINE COMPLETIONS / HISTORY
  // --------------------------------------------------

  Stream<List<RoutineTaskCompletion>> watchCompletions(
    String elderId,
  ) {
    return _routineDocument(elderId)
        .collection('completions')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return List<RoutineTaskCompletion>.unmodifiable(
        snapshot.docs.map(
          RoutineTaskCompletion.fromFirestore,
        ),
      );
    });
  }

  Future<void> completeTask({
    required UserSession actor,
    required RoutineTask task,
    required DateTime occurrenceDate,
  }) async {
    if (task.id.trim().isEmpty) {
      throw StateError('Tarefa não identificada.');
    }

    final day = RoutineTask.dateOnly(occurrenceDate);

    final taskReference = _routineDocument(task.elderId)
        .collection('tasks')
        .doc(task.id);

    final completedByRole = switch (actor.accountType) {
      AccountType.elder => RoutineTaskCreatorRole.elder,
      AccountType.caregiver => RoutineTaskCreatorRole.caregiver,
      AccountType.family => RoutineTaskCreatorRole.family,
    };

    await _firestore.runTransaction((transaction) async {
      // Recupera a tarefa atual para evitar concluir
      // uma versão desatualizada.
      final taskSnapshot = await transaction.get(taskReference);

      final currentTask = taskSnapshot.exists
          ? RoutineTask.fromFirestore(taskSnapshot)
          : task;

      if (!currentTask.occursOn(day)) {
        throw StateError(
          'Esta tarefa não está programada para esta data.',
        );
      }

      final completionId = RoutineTaskCompletion.documentIdFor(
        taskId: currentTask.id,
        occurrenceDate: day,
        taskWasRecurring: currentTask.repeatWeekly,
      );

      final completionReference = _routineDocument(task.elderId)
          .collection('completions')
          .doc(completionId);

      final completionSnapshot =
          await transaction.get(completionReference);

      // Evita duplicar uma conclusão.
      if (completionSnapshot.exists) {
        return;
      }

      if (!taskSnapshot.exists) {
        throw StateError('A tarefa não foi encontrada.');
      }

      final scheduledStartAt = currentTask.startOn(day);
      final scheduledEndAt = currentTask.endOn(day);

      transaction.set(completionReference, {
        'taskId': currentTask.id,
        'elderId': currentTask.elderId,
        'institutionId': actor.institutionId,
        'taskTitle': currentTask.title,
        'taskType': currentTask.type.name,
        'occurrenceDate': Timestamp.fromDate(day),
        'scheduledStartAt': Timestamp.fromDate(
          scheduledStartAt,
        ),
        'scheduledEndAt': Timestamp.fromDate(
          scheduledEndAt,
        ),
        'completedAt': FieldValue.serverTimestamp(),
        'completedByUserId': actor.uid,
        'completedByRole': completedByRole.name,
        'taskWasRecurring': currentTask.repeatWeekly,
      });

      // Tarefas únicas saem da rotina ativa.
      // As recorrentes permanecem cadastradas.
      if (!currentTask.repeatWeekly) {
        transaction.delete(taskReference);
      }
    });
  }

  // --------------------------------------------------
  // ROUTINE TASKS
  // --------------------------------------------------

 Stream<List<RoutineTask>> watchTasks(String elderId) {
  return _routineDocument(elderId)
      .collection('tasks')
      .orderBy('startAt')
      .snapshots()
      .map((snapshot) {
    return List<RoutineTask>.unmodifiable(
      snapshot.docs.map(
        (document) => RoutineTask.fromFirestore(document),
      ),
    );
  });
}
  // --------------------------------------------------
  // ROUTINE PERMISSIONS
  // --------------------------------------------------

  Stream<RoutinePermissions> watchPermissions(String elderId) {
    return _routineDocument(elderId).snapshots().map((document) {
      return RoutinePermissions.fromFirestore(document);
    });
  }

  // --------------------------------------------------
  // ELDER
  // --------------------------------------------------

  Stream<RoutineElderSummary?> watchElder(String elderId) {
    return _firestore.collection('users').doc(elderId).snapshots().map(
      (document) {
        final data = document.data();

        if (!document.exists ||
            data == null ||
            data['type']?.toString() != 'idoso' ||
            data['status']?.toString() != 'active') {
          return null;
        }

        return RoutineElderSummary.fromFirestore(document);
      },
    );
  }

  Stream<List<RoutineElderSummary>> watchAccessibleElders(
    UserSession actor,
  ) async* {
    switch (actor.accountType) {
      case AccountType.elder:
        yield* watchElder(actor.uid).map(
          (elder) => elder == null
              ? const <RoutineElderSummary>[]
              : <RoutineElderSummary>[elder],
        );
        return;

      case AccountType.caregiver:
        yield* _watchInstitutionElders(actor.institutionId);
        return;

      case AccountType.family:
        await _migrateLegacyFamilyLinks(actor);
        yield* _watchLinkedElders(actor);
        return;
    }
  }

  Stream<List<RoutineElderSummary>> _watchInstitutionElders(
    String institutionId,
  ) {
    return _firestore
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('type', isEqualTo: 'idoso')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final elders = snapshot.docs
          .map(RoutineElderSummary.fromFirestore)
          .toList()
        ..sort(_compareElders);

      return List<RoutineElderSummary>.unmodifiable(elders);
    });
  }

  Stream<List<RoutineElderSummary>> _watchLinkedElders(
    UserSession actor,
  ) {
    return _firestore
        .collection('familyLinks')
        .where('familiarId', isEqualTo: actor.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      final elderIds = <String>{
        for (final link in snapshot.docs)
          if (link.data()['institutionId']?.toString() ==
              actor.institutionId)
            link.data()['elderId']?.toString() ?? '',
      }..remove('');

      final documents = await Future.wait(
        elderIds.map(
          (elderId) => _firestore.collection('users').doc(elderId).get(),
        ),
      );

      final elders = <RoutineElderSummary>[];

      for (final document in documents) {
        final data = document.data();

        if (document.exists &&
            data != null &&
            data['type']?.toString() == 'idoso' &&
            data['status']?.toString() == 'active' &&
            data['institutionId']?.toString() == actor.institutionId) {
          elders.add(RoutineElderSummary.fromFirestore(document));
        }
      }

      elders.sort(_compareElders);

      return List<RoutineElderSummary>.unmodifiable(elders);
    });
  }

  Future<void> _migrateLegacyFamilyLinks(UserSession actor) async {
    final snapshot = await _firestore
        .collection('familyLinks')
        .where('familiarId', isEqualTo: actor.uid)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    var hasWrites = false;

    for (final link in snapshot.docs) {
      final data = link.data();
      final elderId = data['elderId']?.toString() ?? '';

      if (elderId.isEmpty ||
          data['institutionId']?.toString() != actor.institutionId) {
        continue;
      }

      final expectedId = FamilyLinkId.forUsers(
        elderId: elderId,
        familyId: actor.uid,
      );

      if (link.id == expectedId) continue;

      batch.set(
        _firestore.collection('familyLinks').doc(expectedId),
        {
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'elderId': elderId,
          'familiarId': actor.uid,
          'institutionId': actor.institutionId,
          'receiveNotifications': data['receiveNotifications'] != false,
          'status': 'active',
        },
        SetOptions(merge: true),
      );

      hasWrites = true;
    }

    if (hasWrites) {
      await batch.commit();
    }
  }

  // --------------------------------------------------
  // CREATE TASK
  // --------------------------------------------------

  Future<RoutineTask> createTask({
    required UserSession actor,
    required RoutineTask task,
  }) async {
    _validateTask(task);

    await _ensureRoutineDocument(
      elderId: task.elderId,
      institutionId: actor.institutionId,
      actorId: actor.uid,
    );

    final reference = _routineDocument(task.elderId)
        .collection('tasks')
        .doc();

    final storedTask = task.copyWith(id: reference.id);

    await reference.set({
      ...storedTask.toFirestore(
        institutionId: actor.institutionId,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return storedTask;
  }

  // --------------------------------------------------
  // UPDATE TASK
  // --------------------------------------------------

  Future<void> updateTask({
    required UserSession actor,
    required RoutineTask task,
  }) async {
    _validateTask(task);

    if (task.id.isEmpty) {
      throw StateError('Tarefa não identificada.');
    }

    await _routineDocument(task.elderId)
        .collection('tasks')
        .doc(task.id)
        .update({
      ...task.toFirestore(
        institutionId: actor.institutionId,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --------------------------------------------------
  // DELETE TASK
  // --------------------------------------------------

  Future<void> deleteTask({
    required RoutineTask task,
  }) async {
    if (task.id.isEmpty) {
      throw StateError('Tarefa não identificada.');
    }

    await _routineDocument(task.elderId)
        .collection('tasks')
        .doc(task.id)
        .delete();
  }

  // --------------------------------------------------
  // ELDER PERMISSIONS
  // --------------------------------------------------

  Future<void> setElderPermissions({
    required UserSession actor,
    required String elderId,
    required bool canManageOwnRoutine,
  }) async {
    if (actor.accountType != AccountType.caregiver) {
      throw StateError(
        'Somente o cuidador pode alterar as permissões da rotina.',
      );
    }

    final reference = _routineDocument(elderId);
    final existing = await reference.get();

    final permissionData = {
      'elderId': elderId,
      'institutionId': actor.institutionId,
      'canElderCreateTasks': canManageOwnRoutine,
      'canElderEditOwnTasks': canManageOwnRoutine,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedByUserId': actor.uid,
    };

    if (existing.exists) {
      await reference.update(permissionData);
      return;
    }

    await reference.set({
      ...permissionData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --------------------------------------------------
  // ENSURE ROUTINE DOCUMENT
  // --------------------------------------------------

  Future<void> _ensureRoutineDocument({
    required String elderId,
    required String institutionId,
    required String actorId,
  }) async {
    final reference = _routineDocument(elderId);

    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);

      if (current.exists) return;

      transaction.set(reference, {
        'elderId': elderId,
        'institutionId': institutionId,
        'canElderCreateTasks': true,
        'canElderEditOwnTasks': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUserId': actorId,
      });
    });
  }

  // --------------------------------------------------
  // VALIDATIONS
  // --------------------------------------------------

  void _validateTask(RoutineTask task) {
    if (task.elderId.trim().isEmpty) {
      throw StateError('Idoso não identificado.');
    }

    if (task.title.trim().isEmpty) {
      throw StateError('Informe o nome da tarefa.');
    }

    if (!task.endAt.isAfter(task.startAt)) {
      throw StateError('O término deve ser posterior ao começo.');
    }

    if (task.repeatWeekly && task.repeatWeekdays.isEmpty) {
      throw StateError(
        'Escolha pelo menos um dia para repetir a tarefa.',
      );
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  static int _compareElders(
    RoutineElderSummary first,
    RoutineElderSummary second,
  ) {
    return first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        );
  }
}
