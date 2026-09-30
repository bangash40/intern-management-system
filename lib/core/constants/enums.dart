enum UserRole {
  admin('admin', 'Admin'),
  intern('intern', 'Intern');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) => UserRole.values.firstWhere(
    (r) => r.value == value,
    orElse: () => UserRole.intern,
  );
}

enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  submitted('submitted', 'Submitted'),
  completed('completed', 'Completed');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus fromValue(String? value) => TaskStatus.values.firstWhere(
    (s) => s.value == value,
    orElse: () => TaskStatus.todo,
  );
}

enum TaskPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority fromValue(String? value) => TaskPriority.values
      .firstWhere((p) => p.value == value, orElse: () => TaskPriority.medium);
}
