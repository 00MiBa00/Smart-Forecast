import '../database/database.dart';
import '../models/card_status.dart';
import 'package:drift/drift.dart' as drift;

class SRSRepository {
  final AppDatabase _database;

  SRSRepository(this._database);

  /// Get SRS record by card ID
  Future<SRSRecord?> getSrsRecordByCardId(String cardId) async {
    return await (_database.select(_database.sRSRecords)
          ..where((record) => record.cardId.equals(cardId)))
        .getSingleOrNull();
  }

  /// Create a new SRS record
  Future<void> createSrsRecord(SRSRecord record) async {
    await _database.into(_database.sRSRecords).insert(record.toCompanion(false));
  }

  /// Update an existing SRS record
  Future<void> updateSrsRecord(SRSRecord record) async {
    await (_database.update(_database.sRSRecords)
          ..where((r) => r.cardId.equals(record.cardId)))
        .write(record.toCompanion(false));
  }

  /// Watch all SRS records (stream)
  Stream<List<SRSRecord>> watchAllSrsRecords() {
    return _database.select(_database.sRSRecords).watch();
  }

  /// Get all SRS records
  Future<List<SRSRecord>> getAllSrsRecords() async {
    return await _database.select(_database.sRSRecords).get();
  }

  /// Delete SRS record by card ID
  Future<void> deleteSrsRecord(String cardId) async {
    await (_database.delete(_database.sRSRecords)
          ..where((record) => record.cardId.equals(cardId)))
        .go();
  }

  /// Get or create SRS record for a card
  Future<SRSRecord> getOrCreateSrsRecord(String cardId) async {
    final existing = await getSrsRecordByCardId(cardId);
    
    if (existing != null) {
      return existing;
    }

    // Create default record for new card
    final now = DateTime.now();
    final newRecord = SRSRecord(
      cardId: cardId,
      dueAt: now,
      intervalDays: 0.0,
      easeFactor: 2.5,
      lapses: 0,
      lastGrade: null,
      updatedAt: now,
    );

    await createSrsRecord(newRecord);
    return newRecord;
  }

  /// Get due cards count (cards where dueAt <= now)
  Future<int> getDueCardsCount() async {
    final now = DateTime.now();
    
    // Count due cards
    final dueCount = await (_database.select(_database.sRSRecords)
          ..where((record) => record.dueAt.isSmallerOrEqualValue(now)))
        .get()
        .then((records) => records.length);

    // Count new cards (cards without SRS record)
    final allActiveCards = await (_database.select(_database.cards)
          ..where((card) => card.status.equals(CardStatus.active.index)))
        .get();

    final allSrsRecords = await getAllSrsRecords();
    final srsCardIds = allSrsRecords.map((r) => r.cardId).toSet();
    final newCardsCount = allActiveCards.where((card) => !srsCardIds.contains(card.id)).length;

    return dueCount + newCardsCount;
  }

  /// Watch due cards count (stream)
  Stream<int> watchDueCardsCount() async* {
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await getDueCardsCount();
    }
  }
}
