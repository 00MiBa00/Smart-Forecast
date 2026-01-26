enum StudyScope {
  all,
  document,
  section;

  String get displayName {
    switch (this) {
      case StudyScope.all:
        return 'All';
      case StudyScope.document:
        return 'Document';
      case StudyScope.section:
        return 'Section';
    }
  }
}
