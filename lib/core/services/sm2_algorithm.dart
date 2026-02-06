import '../../data/database/database.dart';
import '../../data/models/srs_grade.dart';

/// SM-2 Algorithm implementation for Spaced Repetition System
class SM2Algorithm {
  /// Calculate next SRS record based on current record and user's grade
  static SRSRecord calculateNext(SRSRecord current, SRSGrade grade) {
    final now = DateTime.now();
    double newEaseFactor = current.easeFactor;
    double newIntervalDays = current.intervalDays;
    int newLapses = current.lapses;
    DateTime dueAt;

    switch (grade) {
      case SRSGrade.again:
        // Reset to beginning
        newIntervalDays = 1;
        newLapses = current.lapses + 1;
        dueAt = now.add(const Duration(days: 1));
        break;

      case SRSGrade.hard:
        // Slightly increase interval, decrease ease factor
        newEaseFactor = (current.easeFactor - 0.15).clamp(1.3, 2.5);
        newIntervalDays = (current.intervalDays * 1.2).clamp(1.0, double.infinity);
        dueAt = now.add(Duration(days: newIntervalDays.round()));
        break;

      case SRSGrade.good:
        // Normal progression
        if (newIntervalDays < 1) {
          newIntervalDays = 1;
        } else if (newIntervalDays < 6) {
          newIntervalDays = 6;
        } else {
          newIntervalDays = current.intervalDays * current.easeFactor;
        }
        
        dueAt = now.add(Duration(days: newIntervalDays.round()));
        break;

      case SRSGrade.easy:
        // Accelerated progression, increase ease factor
        newEaseFactor = (current.easeFactor + 0.15).clamp(1.3, 2.5);
        
        if (newIntervalDays < 4) {
          newIntervalDays = 4;
        } else if (newIntervalDays < 10) {
          newIntervalDays = 10;
        } else {
          newIntervalDays = current.intervalDays * current.easeFactor * 1.3;
        }
        
        dueAt = now.add(Duration(days: newIntervalDays.round()));
        break;
    }

    return SRSRecord(
      cardId: current.cardId,
      easeFactor: newEaseFactor,
      intervalDays: newIntervalDays,
      dueAt: dueAt,
      lapses: newLapses,
      lastGrade: grade,
      updatedAt: now,
    );
  }
}
