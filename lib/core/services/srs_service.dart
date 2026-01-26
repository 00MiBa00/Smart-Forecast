import '../../data/models/srs_grade.dart';
import '../utils/constants.dart';

class SRSService {
  /// Calculate new SRS values based on grade
  static SRSUpdate calculateNextReview({
    required SRSGrade grade,
    required double currentEaseFactor,
    required double currentIntervalDays,
    required int currentLapses,
  }) {
    double newEaseFactor = currentEaseFactor;
    double newIntervalDays = currentIntervalDays;
    int newLapses = currentLapses;
    Duration nextReview = Duration.zero;

    switch (grade) {
      case SRSGrade.again:
        newIntervalDays = 0;
        nextReview = AppConstants.againInterval;
        newEaseFactor = (currentEaseFactor - 0.2).clamp(AppConstants.minEaseFactor, double.infinity);
        newLapses++;
        break;

      case SRSGrade.hard:
        newIntervalDays = (currentIntervalDays * 1.2).clamp(1.0, double.infinity);
        nextReview = Duration(days: newIntervalDays.round());
        newEaseFactor = (currentEaseFactor - 0.15).clamp(AppConstants.minEaseFactor, double.infinity);
        break;

      case SRSGrade.good:
        if (currentIntervalDays == 0) {
          newIntervalDays = 1;
        } else {
          newIntervalDays = currentIntervalDays * currentEaseFactor;
        }
        nextReview = Duration(days: newIntervalDays.round());
        break;

      case SRSGrade.easy:
        if (currentIntervalDays == 0) {
          newIntervalDays = 2;
        } else {
          newIntervalDays = currentIntervalDays * currentEaseFactor * 1.3;
        }
        nextReview = Duration(days: newIntervalDays.round());
        newEaseFactor = currentEaseFactor + 0.05;
        break;
    }

    return SRSUpdate(
      intervalDays: newIntervalDays,
      easeFactor: newEaseFactor,
      lapses: newLapses,
      dueAt: DateTime.now().add(nextReview),
    );
  }

  /// Get initial SRS values for a new card
  static SRSUpdate getInitialValues() {
    return SRSUpdate(
      intervalDays: 0,
      easeFactor: AppConstants.defaultEaseFactor,
      lapses: 0,
      dueAt: DateTime.now(),
    );
  }
}

class SRSUpdate {
  final double intervalDays;
  final double easeFactor;
  final int lapses;
  final DateTime dueAt;

  SRSUpdate({
    required this.intervalDays,
    required this.easeFactor,
    required this.lapses,
    required this.dueAt,
  });
}
