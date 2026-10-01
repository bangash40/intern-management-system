import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';

/// A document in the `tasks` collection.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedBy,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.submissionNote = '',
    this.adminRemarks = '',
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final String assignedBy;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String submissionNote;
  final String adminRemarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == TaskStatus.completed;

  /// Overdue is not stored. It is past the due date and not completed.
  bool isOverdue([DateTime? now]) =>
      !isCompleted && dueDate.isBefore(now ?? DateTime.now());

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      assignedTo: map['assignedTo'] as String? ?? '',
      assignedToName: map['assignedToName'] as String? ?? '',
      assignedBy: map['assignedBy'] as String? ?? '',
      priority: TaskPriority.fromValue(map['priority'] as String?),
      status: TaskStatus.fromValue(map['status'] as String?),
      dueDate:
          _toDate(map['dueDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      submissionNote: map['submissionNote'] as String? ?? '',
      adminRemarks: map['adminRemarks'] as String? ?? '',
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      completedAt: _toDate(map['completedAt']),
    );
  }

  /// Fields an admin writes when creating or editing a task. Timestamps
  /// (`createdAt`, `updatedAt`, `completedAt`) are set by the repository.
  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedBy': assignedBy,
      'priority': priority.value,
      'status': status.value,
      'dueDate': Timestamp.fromDate(dueDate),
      'submissionNote': submissionNote,
      'adminRemarks': adminRemarks,
    };
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
