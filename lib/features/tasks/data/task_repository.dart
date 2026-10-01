import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/task.dart';

/// All Firestore calls for tasks live here.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(FirestoreCollections.tasks);

  List<Task> _toTasks(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((d) => Task.fromMap(d.id, d.data())).toList();

  // ---- Streams -------------------------------------------------------

  /// Every task, soonest due date first (admin).
  Stream<List<Task>> watchAllTasks() =>
      _tasks.orderBy('dueDate').snapshots().map(_toTasks);

  /// Tasks assigned to one intern, optionally filtered by status.
  Stream<List<Task>> watchInternTasks(String uid, {TaskStatus? status}) {
    Query<Map<String, dynamic>> query = _tasks.where(
      'assignedTo',
      isEqualTo: uid,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    return query.orderBy('dueDate').snapshots().map(_toTasks);
  }

  /// Submitted tasks waiting for an admin decision.
  Stream<List<Task>> watchReviewQueue() => _tasks
      .where('status', isEqualTo: TaskStatus.submitted.value)
      .orderBy('dueDate')
      .snapshots()
      .map(_toTasks);

  Stream<Task?> watchTask(String id) => _tasks.doc(id).snapshots().map((doc) {
    final data = doc.data();
    return doc.exists && data != null ? Task.fromMap(doc.id, data) : null;
  });

  Future<Task?> getTask(String id) async {
    final doc = await _tasks.doc(id).get();
    final data = doc.data();
    return doc.exists && data != null ? Task.fromMap(doc.id, data) : null;
  }

  // ---- Admin writes --------------------------------------------------

  /// Creates a task and returns its generated id.
  Future<String> createTask(Task task) async {
    final ref = await _tasks.add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Edits the admin-controlled fields of a task.
  Future<void> updateTask(Task task) => _tasks.doc(task.id).update({
    'title': task.title.trim(),
    'description': task.description.trim(),
    'assignedTo': task.assignedTo,
    'assignedToName': task.assignedToName,
    'priority': task.priority.value,
    'dueDate': Timestamp.fromDate(task.dueDate),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteTask(String id) => _tasks.doc(id).delete();

  /// Approves a submitted task.
  Future<void> approveTask(String id, {String remarks = ''}) =>
      _tasks.doc(id).update({
        'status': TaskStatus.completed.value,
        'adminRemarks': remarks.trim(),
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Sends a submitted task back to the intern with remarks.
  Future<void> returnTask(String id, {required String remarks}) =>
      _tasks.doc(id).update({
        'status': TaskStatus.inProgress.value,
        'adminRemarks': remarks.trim(),
        'completedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ---- Intern writes -------------------------------------------------

  /// Moves a task to [status] (todo, in progress or submitted).
  ///
  /// Interns cannot mark a task completed; only an admin can approve it.
  /// Only the fields the security rules allow are written.
  Future<void> updateStatus(
    String id,
    TaskStatus status, {
    String? submissionNote,
  }) {
    if (status == TaskStatus.completed) {
      throw ArgumentError('Only an admin can mark a task as completed.');
    }
    return _tasks.doc(id).update({
      'status': status.value,
      if (submissionNote != null) 'submissionNote': submissionNote.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
