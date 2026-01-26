enum CardType {
  qa,
  cloze,
  trueFalse;

  String get displayName {
    switch (this) {
      case CardType.qa:
        return 'Q&A';
      case CardType.cloze:
        return 'Cloze';
      case CardType.trueFalse:
        return 'True/False';
    }
  }
}
