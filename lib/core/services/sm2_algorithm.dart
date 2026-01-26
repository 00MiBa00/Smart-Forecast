import 'dart:math';
import '../../data/database/database.dart';
import '../../data/models/srs_grade.dart';

/// SM-2 Algorithm implementation for spaced repetition
class SM2Algorithm {
  /// Calculate next SRS record based on grade
  static SRSRecord calculateNext(SRSRecord current, SRSGrade grade) {
    final now = DateTime.now();
    double newIntervalDays = current.intervalDays;
    double newEaseFactor = current.easeFactor;
    int newLapses = current.lapses;
    DateTime newDueAt;

    switch (grade) {
      case SRSGrade.again:
        // Reset interval, due in 10 minutes
        newIntervalDays = 0.0;
        newDueAt = now.add(const Duration(minutes: 10));
        newEaseFactor = max(1.3, current.easeFactor - 0.2);
        newLapses = current.lapses + 1;
        break;

      case SRSGrade.hard:
        // Increase interval slightly
        newIntervalDays = max(1.0, current.intervalDays * 1.2);
        newDueAt = now.add(Duration(days: newIntervalDays.ceil()));
        newEaseFactor = max(1.3, current.easeFactor - 0.15);
        break;

      case SRSGrade.good:
        // Standard interval increase
        if (current.intervalDays == 0) {
          newIntervalDays = 1.0;
        } else {
          newIntervalDays = current.intervalDays * current.easeFactor;
        }
        newDueAt = now.add(Duration(days: newIntervalDays.ceil()));
        break;

      case SRSGrade.easy:
        // Larger interval increase
        if (current.intervalDays == 0) {
          newIntervalDays = 2.0;
        } else {
          newIntervalDays = current.intervalDays * current.easeFactor * 1.3;
        }
        newDueAt = now.add(Duration(days: newIntervalDays.ceil()));
        newEaseFactor = current.easeFactor + 0.05;
        break;
    }

    return SRSRecord(
      cardId: current.cardId,
      dueAt: newDueAt,
      intervalDays: newIntervalDays,
      easeFactor: newEaseFactor,
      lapses: newLapses,
      lastGrade: grade,
      updatedAt: now,
    );
  }
}
