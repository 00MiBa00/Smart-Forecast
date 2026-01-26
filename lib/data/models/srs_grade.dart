enum SRSGrade {
  again,
  hard,
  good,
  easy;

  String get displayName {
    switch (this) {
      case SRSGrade.again:
        return 'Again';
      case SRSGrade.hard:
        return 'Hard';
      case SRSGrade.good:
        return 'Good';
      case SRSGrade.easy:
        return 'Easy';
    }
  }
}
