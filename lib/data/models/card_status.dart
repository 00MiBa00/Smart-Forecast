enum CardStatus {
  draft,
  active,
  suspended;

  String get displayName {
    switch (this) {
      case CardStatus.draft:
        return 'Draft';
      case CardStatus.active:
        return 'Active';
      case CardStatus.suspended:
        return 'Suspended';
    }
  }
}
