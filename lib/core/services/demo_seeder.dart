import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/models/card_status.dart';
import '../../data/models/card_type.dart';

class DemoSeeder {
  final AppDatabase _database;
  static const String _demoDocumentId = 'demo_document_001';

  DemoSeeder(this._database);

  /// Ensure demo document and cards exist
  Future<void> ensureDemoExists() async {
    final existingDoc = await _getDocumentById(_demoDocumentId);
    
    if (existingDoc == null) {
      await _createDemoDocument();
      await _createDemoCards();
    }
  }

  /// Get demo document
  Future<Document?> getDemoDocument() async {
    return await _getDocumentById(_demoDocumentId);
  }

  Future<Document?> _getDocumentById(String id) async {
    return await (_database.select(_database.documents)
          ..where((doc) => doc.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _createDemoDocument() async {
    final now = DateTime.now();
    await _database.into(_database.documents).insert(
          DocumentsCompanion(
            id: const drift.Value(_demoDocumentId),
            title: const drift.Value('Demo Document'),
            updatedAt: drift.Value(now),
          ),
        );
  }

  Future<void> _createDemoCards() async {
    final now = DateTime.now();
    final demoCards = [
      {
        'id': 'demo_card_001',
        'front': 'What is Flutter?',
        'back': 'Flutter is an open-source UI toolkit created by Google for building natively compiled applications.',
        'type': CardType.qa,
      },
      {
        'id': 'demo_card_002',
        'front': 'What is Dart?',
        'back': 'Dart is a programming language optimized for building mobile, desktop, server, and web applications.',
        'type': CardType.qa,
      },
      {
        'id': 'demo_card_003',
        'front': 'What is a Widget?',
        'back': 'In Flutter, a Widget is a basic building block of the user interface.',
        'type': CardType.qa,
      },
    ];

    for (final cardData in demoCards) {
      await _database.into(_database.cards).insert(
            CardsCompanion(
              id: drift.Value(cardData['id'] as String),
              documentId: const drift.Value(_demoDocumentId),
              type: drift.Value(cardData['type'] as CardType),
              status: drift.Value(CardStatus.active),
              front: drift.Value(cardData['front'] as String),
              back: drift.Value(cardData['back'] as String),
              tags: const drift.Value('[]'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );
    }
  }
}
