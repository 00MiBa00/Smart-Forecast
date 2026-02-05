import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/models/srs_grade.dart';

/// Implementation of the SM-2 (SuperMemo 2) spaced repetition algorithm
/// 
/// This algorithm calculates the optimal time intervals for reviewing flashcards
/// based on the user's performance in previous reviews.
class SM2Algorithm {
  // Minimum ease factor (prevents cards from becoming too difficult)
  static const double _minEaseFactor = 1.3;
  
  // Initial ease factor for new cards
  static const double _initialEaseFactor = 2.5;
  
  // Initial interval for cards reviewed correctly for the first time (1 day)
  static const double _firstInterval = 1.0;
  
  // Second interval for cards reviewed correctly twice (6 days)
  static const double _secondInterval = 6.0;

  /// Calculates the next SRS record based on current record and user's grade
  /// 
  /// [currentRecord] - The current SRS state of the card
  /// [grade] - The user's self-assessed performance grade
  /// 
  /// Returns a new SRSRecord with updated scheduling parameters
  static SRSRecord calculateNext(SRSRecord currentRecord, SRSGrade grade) {
    final now = DateTime.now();
    
    // Convert grade to numeric quality (0-5 scale used in SM-2)
    final quality = _gradeToQuality(grade);
    
    // Calculate new ease factor
    double newEaseFactor = currentRecord.easeFactor;
    if (quality >= 3) {
      // Update ease factor based on performance
      newEaseFactor = currentRecord.easeFactor + 
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      
      // Ensure ease factor doesn't go below minimum
      if (newEaseFactor < _minEaseFactor) {
        newEaseFactor = _minEaseFactor;
      }
    }
    
    // Calculate new interval
    double newInterval;
    int newLapses = currentRecord.lapses;
    
    if (quality < 3) {
      // Failed review (Again, Hard): restart from beginning
      newInterval = _firstInterval;
      newLapses = currentRecord.lapses + 1;
      // Reset ease factor slightly on failure
      newEaseFactor = currentRecord.easeFactor - 0.2;
      if (newEaseFactor < _minEaseFactor) {
        newEaseFactor = _minEaseFactor;
      }
    } else {
      // Successful review (Good, Easy)
      if (currentRecord.intervalDays < 1) {
        // First successful review
        newInterval = _firstInterval;
      } else if (currentRecord.intervalDays < 2) {
        // Second successful review
        newInterval = _secondInterval;
      } else {
        // Subsequent reviews: multiply by ease factor
        newInterval = currentRecord.intervalDays * newEaseFactor;
        
        // Apply modifier for Easy grade
        if (grade == SRSGrade.easy) {
          newInterval = newInterval * 1.3; // 30% bonus for easy cards
        }
      }
    }
    
    // Calculate due date
    final dueAt = now.add(Duration(days: newInterval.round()));
    
    // Return new record with updated values
    return currentRecord.copyWith(
      dueAt: dueAt,
      intervalDays: newInterval,
      easeFactor: newEaseFactor,
      lapses: newLapses,
      lastGrade: drift.Value(grade),
      updatedAt: now,
    );
  }
  
  /// Converts SRSGrade enum to numeric quality (0-5 scale)
  static int _gradeToQuality(SRSGrade grade) {
    switch (grade) {
      case SRSGrade.again:
        return 0; // Complete blackout
      case SRSGrade.hard:
        return 2; // Incorrect response; correct answer seemed familiar
      case SRSGrade.good:
        return 4; // Correct response with some difficulty
      case SRSGrade.easy:
        return 5; // Perfect response
    }
  }
  
  /// Creates an initial SRS record for a new card
  static SRSRecord createInitialRecord(String cardId) {
    final now = DateTime.now();
    return SRSRecord(
      cardId: cardId,
      dueAt: now, // Due immediately for first review
      intervalDays: 0,
      easeFactor: _initialEaseFactor,
      lapses: 0,
      lastGrade: null,
      updatedAt: now,
    );
  }
}
