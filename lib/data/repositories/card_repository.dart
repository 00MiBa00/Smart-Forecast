import 'dart:convert';
import '../database/database.dart';
import '../models/card_type.dart';
import '../models/card_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class CardRepository {
  final AppDatabase _database;
  final _uuid = const Uuid();

  CardRepository(this._database);

  /// Create a new card
  Future<String> createCard({
    required String documentId,
    String? sectionId,
    required CardType type,
    required String front,
    required String back,
    required List<String> tags,
    required CardStatus status,
    String? sourceSnippet,
    String? sourceAnchor,
  }) async {
    final now = DateTime.now();
    final cardId = _uuid.v4();
    
    await _database.into(_database.cards).insert(
      CardsCompanion(
        id: drift.Value(cardId),
        documentId: drift.Value(documentId),
        sectionId: sectionId != null ? drift.Value(sectionId) : const drift.Value.absent(),
        type: drift.Value(type),
        front: drift.Value(front),
        back: drift.Value(back),
        tags: drift.Value(jsonEncode(tags)),
        status: drift.Value(status),
        sourceSnippet: sourceSnippet != null ? drift.Value(sourceSnippet) : const drift.Value.absent(),
        sourceAnchor: sourceAnchor != null ? drift.Value(sourceAnchor) : const drift.Value.absent(),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // Update document's card count
    await _incrementDocumentCardCount(documentId);

    return cardId;
  }

  /// Get cards by document ID
  Future<List<Card>> getCardsByDocumentId(String documentId) async {
    return await (_database.select(_database.cards)
          ..where((card) => card.documentId.equals(documentId))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .get();
  }

  /// Watch cards by document ID (stream)
  Stream<List<Card>> watchCardsByDocumentId(String documentId) {
    return (_database.select(_database.cards)
          ..where((card) => card.documentId.equals(documentId))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .watch();
  }

  /// Watch card count by document ID
  Stream<int> watchCardCountByDocumentId(String documentId) {
    return watchCardsByDocumentId(documentId).map((cards) => cards.length);
  }

  /// Get a card by ID
  Future<Card?> getCardById(String id) async {
    return await (_database.select(_database.cards)
          ..where((card) => card.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update a card
  Future<void> updateCard(Card card) async {
    await (_database.update(_database.cards)
          ..where((c) => c.id.equals(card.id)))
        .write(
      card.toCompanion(false).copyWith(
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Delete a card
  Future<void> deleteCard(String id) async {
    // Get card to know document ID
    final card = await getCardById(id);
    
    await (_database.delete(_database.cards)
          ..where((card) => card.id.equals(id)))
        .go();

    // Update document's card count
    if (card != null) {
      await _decrementDocumentCardCount(card.documentId);
    }
  }

  /// Get all cards (for Create tab)
  Future<List<Card>> getAllCards() async {
    return await (_database.select(_database.cards)
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .get();
  }

  /// Watch all cards (for Create tab with live updates)
  Stream<List<Card>> watchAllCards() {
    return (_database.select(_database.cards)
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .watch();
  }

  /// Get all active cards
  Future<List<Card>> getActiveCards() async {
    return await (_database.select(_database.cards)
          ..where((card) => card.status.equals(CardStatus.active.index))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .get();
  }

  /// Watch all active cards (stream)
  Stream<List<Card>> watchActiveCards() {
    return (_database.select(_database.cards)
          ..where((card) => card.status.equals(CardStatus.active.index))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .watch();
  }

  /// Get active cards by document ID
  Future<List<Card>> getActiveCardsByDocumentId(String documentId) async {
    return await (_database.select(_database.cards)
          ..where((card) => 
              card.documentId.equals(documentId) & 
              card.status.equals(CardStatus.active.index))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .get();
  }

  /// Get count of all active cards
  Future<int> getActiveCardsCount() async {
    return await (_database.selectOnly(_database.cards)
          ..addColumns([_database.cards.id.count()])
          ..where(_database.cards.status.equals(CardStatus.active.index)))
        .getSingle()
        .then((row) => row.read(_database.cards.id.count()) ?? 0);
  }

  /// Watch active cards by document ID (stream)
  Stream<List<Card>> watchActiveCardsByDocumentId(String documentId) {
    return (_database.select(_database.cards)
          ..where((card) => 
              card.documentId.equals(documentId) & 
              card.status.equals(CardStatus.active.index))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .watch();
  }

  /// Get cards by section ID
  Future<List<Card>> getCardsBySectionId(String sectionId) async {
    return await (_database.select(_database.cards)
          ..where((card) => card.sectionId.equals(sectionId))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .get();
  }

  /// Watch cards by section ID (stream)
  Stream<List<Card>> watchCardsBySectionId(String sectionId) {
    return (_database.select(_database.cards)
          ..where((card) => card.sectionId.equals(sectionId))
          ..orderBy([(card) => drift.OrderingTerm.desc(card.createdAt)]))
        .watch();
  }

  /// Create multiple cards at once (batch insert)
  Future<void> createCards(List<CardsCompanion> cards) async {
    if (cards.isEmpty) return;

    // Insert all cards
    await _database.batch((batch) {
      batch.insertAll(_database.cards, cards);
    });

    // Update document card count
    // Get the first card's document ID (all should have the same document)
    final documentId = cards.first.documentId.value;
    await _incrementDocumentCardCountBy(documentId, cards.length);
  }

  /// Increment document's card count
  Future<void> _incrementDocumentCardCount(String documentId) async {
    final doc = await (_database.select(_database.documents)
          ..where((d) => d.id.equals(documentId)))
        .getSingleOrNull();
    
    if (doc != null) {
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(documentId)))
          .write(
        DocumentsCompanion(
          cardsCount: drift.Value(doc.cardsCount + 1),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  /// Decrement document's card count
  Future<void> _decrementDocumentCardCount(String documentId) async {
    final doc = await (_database.select(_database.documents)
          ..where((d) => d.id.equals(documentId)))
        .getSingleOrNull();
    
    if (doc != null) {
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(documentId)))
          .write(
        DocumentsCompanion(
          cardsCount: drift.Value((doc.cardsCount - 1).clamp(0, double.infinity).toInt()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  /// Increment document's card count by a specific amount
  Future<void> _incrementDocumentCardCountBy(String documentId, int count) async {
    final doc = await (_database.select(_database.documents)
          ..where((d) => d.id.equals(documentId)))
        .getSingleOrNull();
    
    if (doc != null) {
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(documentId)))
          .write(
        DocumentsCompanion(
          cardsCount: drift.Value(doc.cardsCount + count),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }
}
