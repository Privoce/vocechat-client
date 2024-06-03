enum CreateUserConflictReason {
  name,
  email;

  String get value {
    switch (this) {
      case CreateUserConflictReason.name:
        return 'name_conflict';
      case CreateUserConflictReason.email:
        return 'email_conflict';
    }
  }
}
