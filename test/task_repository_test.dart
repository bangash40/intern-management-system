import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';

Task newTask({
  String title = 'Build login',
  String assignedTo = 'u1',
  TaskStatus status = TaskStatus.todo,
  DateTime? dueDate,
}) => Task(
  id: '',
  title: title,
  description: 'Do it',
  assignedTo: assignedTo,
  assignedToName: 'Ali',
  assignedBy: 'admin1',
  priority: TaskPriority.high,
  status: status,
  dueDate: dueDate ?? DateTime(2030, 1, 10),
);

void main() {
  group('Task model', () {
    test('toMap and fromMap round-trip', () {
      final task = newTask();
      final copy = Task.fromMap('t1', task.toMap());

      expect(copy.id, 't1');
      expect(copy.title, 'Build login');
      expect(copy.priority, TaskPriority.high);
      expect(copy.status, TaskStatus.todo);
      expect(copy.dueDate, DateTime(2030, 1, 10));
    });

    test('overdue is computed, never stored', () {
      final now = DateTime(2026, 6, 1);
      final late = newTask(dueDate: DateTime(2026, 5, 1));
      final onTime = newTask(dueDate: DateTime(2026, 7, 1));
      final doneLate = newTask(
        dueDate: DateTime(2026, 5, 1),
        status: TaskStatus.completed,
      );

      expect(late.isOverdue(now), isTrue);
      expect(onTime.isOverdue(now), isFalse);
      expect(doneLate.isOverdue(now), isFalse);
      expect(late.toMap().containsKey('overdue'), isFalse);
    });
  });

  group('TaskRepository', () {
    late FakeFirebaseFirestore firestore;
    late TaskRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = TaskRepository(firestore: firestore);
    });

    test('createTask stores the task with timestamps', () async {
      final id = await repo.createTask(newTask());
      final saved = await repo.getTask(id);

      expect(saved, isNotNull);
      expect(saved!.title, 'Build login');
      expect(saved.createdAt, isNotNull);
      expect(saved.updatedAt, isNotNull);
    });

    test(
      'watchInternTasks returns only that intern, sorted by due date',
      () async {
        await repo.createTask(
          newTask(title: 'B', dueDate: DateTime(2030, 3, 1)),
        );
        await repo.createTask(
          newTask(title: 'A', dueDate: DateTime(2030, 2, 1)),
        );
        await repo.createTask(newTask(title: 'Other', assignedTo: 'u2'));

        final tasks = await repo.watchInternTasks('u1').first;

        expect(tasks.map((t) => t.title), ['A', 'B']);
      },
    );

    test('watchInternTasks can filter by status', () async {
      await repo.createTask(newTask(title: 'Todo'));
      await repo.createTask(
        newTask(title: 'Working', status: TaskStatus.inProgress),
      );

      final tasks = await repo
          .watchInternTasks('u1', status: TaskStatus.inProgress)
          .first;

      expect(tasks.map((t) => t.title), ['Working']);
    });

    test('watchAllTasks returns every task', () async {
      await repo.createTask(newTask(assignedTo: 'u1'));
      await repo.createTask(newTask(assignedTo: 'u2'));

      expect((await repo.watchAllTasks().first).length, 2);
    });

    test('streams update when data changes', () async {
      final id = await repo.createTask(newTask());
      final stream = repo.watchTask(id);

      final expectation = expectLater(
        stream.map((t) => t?.status),
        emitsInOrder([TaskStatus.todo, TaskStatus.inProgress]),
      );
      await repo.updateStatus(id, TaskStatus.inProgress);
      await expectation;
    });

    test('updateTask edits admin fields only', () async {
      final id = await repo.createTask(newTask());
      final saved = (await repo.getTask(id))!;

      await repo.updateTask(
        Task.fromMap(id, {
          ...saved.toMap(),
          'title': 'New title',
          'priority': 'low',
        }),
      );

      final updated = (await repo.getTask(id))!;
      expect(updated.title, 'New title');
      expect(updated.priority, TaskPriority.low);
      expect(updated.status, TaskStatus.todo);
    });

    test('deleteTask removes the task', () async {
      final id = await repo.createTask(newTask());
      await repo.deleteTask(id);
      expect(await repo.getTask(id), isNull);
    });

    test('intern can submit with a note, but not complete a task', () async {
      final id = await repo.createTask(newTask());

      await repo.updateStatus(
        id,
        TaskStatus.submitted,
        submissionNote: ' done, see link ',
      );
      final submitted = (await repo.getTask(id))!;
      expect(submitted.status, TaskStatus.submitted);
      expect(submitted.submissionNote, 'done, see link');

      expect(
        () => repo.updateStatus(id, TaskStatus.completed),
        throwsArgumentError,
      );
    });

    test('review queue lists only submitted tasks', () async {
      await repo.createTask(newTask(title: 'Todo'));
      await repo.createTask(
        newTask(title: 'Waiting', status: TaskStatus.submitted),
      );

      final queue = await repo.watchReviewQueue().first;

      expect(queue.map((t) => t.title), ['Waiting']);
    });

    test('approveTask completes the task and sets completedAt', () async {
      final id = await repo.createTask(newTask(status: TaskStatus.submitted));

      await repo.approveTask(id, remarks: 'Great work');

      final task = (await repo.getTask(id))!;
      expect(task.status, TaskStatus.completed);
      expect(task.adminRemarks, 'Great work');
      expect(task.completedAt, isNotNull);
    });

    test('returnTask sends it back to in progress with remarks', () async {
      final id = await repo.createTask(newTask(status: TaskStatus.submitted));

      await repo.returnTask(id, remarks: 'Fix the layout');

      final task = (await repo.getTask(id))!;
      expect(task.status, TaskStatus.inProgress);
      expect(task.adminRemarks, 'Fix the layout');
      expect(task.completedAt, isNull);
    });

    test('missing task returns null', () async {
      expect(await repo.getTask('nope'), isNull);
      expect(await repo.watchTask('nope').first, isNull);
    });
  });

  test('Timestamp values convert to DateTime', () {
    final task = Task.fromMap('t', {
      'dueDate': Timestamp.fromDate(DateTime(2031)),
    });
    expect(task.dueDate, DateTime(2031));
  });
}
