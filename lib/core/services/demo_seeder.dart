import 'package:uuid/uuid.dart';
import '../../data/database/database.dart';
import '../../data/models/document_type.dart';
import '../../data/models/card_type.dart';
import '../../data/models/card_status.dart';
import '../../data/models/anchor.dart';
import 'package:drift/drift.dart' as drift;

/// Service for creating and managing demo/sample content
/// 
/// This service provides example documents and cards for new users
/// to help them understand the app's functionality.
class DemoSeeder {
  final AppDatabase _database;
  final _uuid = const Uuid();
  
  static const String demoDocumentId = 'demo-doc-001';
  static const String demoSectionId = 'demo-section-001';

  DemoSeeder(this._database);

  /// Ensures demo content exists in the database
  /// 
  /// Creates a demo document with sample cards if it doesn't already exist.
  Future<void> ensureDemoExists() async {
    // Check if demo document already exists
    final existing = await (_database.select(_database.documents)
          ..where((doc) => doc.id.equals(demoDocumentId)))
        .getSingleOrNull();

    if (existing == null) {
      await _createDemoContent();
    }
  }

  /// Gets the demo document
  Future<Document?> getDemoDocument() async {
    return await (_database.select(_database.documents)
          ..where((doc) => doc.id.equals(demoDocumentId)))
        .getSingleOrNull();
  }

  /// Deletes all demo content from the database
  Future<void> deleteDemoContent() async {
    await (_database.delete(_database.documents)
          ..where((doc) => doc.isDemo.equals(true)))
        .go();
  }

  /// Creates demo document with sample sections and cards
  Future<void> _createDemoContent() async {
    final now = DateTime.now();

    // Create demo document
    await _database.into(_database.documents).insert(
          DocumentsCompanion.insert(
            id: demoDocumentId,
            title: 'Welcome to Smart Forecast',
            type: DocumentType.pdf,
            localFilePath: 'demo',
            importedAt: now,
            updatedAt: now,
            lastOpenedAt: drift.Value(now),
            pagesCount: drift.Value(1),
            isDemo: drift.Value(true),
          ),
        );

    // Create demo section
    await _database.into(_database.sections).insert(
          SectionsCompanion.insert(
            id: demoSectionId,
            documentId: demoDocumentId,
            title: 'Introduction to Smart Forecast',
            tags: '[]',
            extractedText: _getDemoSectionText(),
            anchorStart: PDFAnchor(
              page: 0,
              fallbackHash: 'demo',
            ).toJsonString(),
            anchorEnd: drift.Value(PDFAnchor(
              page: 0,
              fallbackHash: 'demo',
            ).toJsonString()),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Create demo cards
    await _createDemoCards(now);
  }

  /// Creates sample flashcards for the demo document
  Future<void> _createDemoCards(DateTime now) async {
    final demoCards = [
      // Q&A Card
      CardsCompanion.insert(
        id: _uuid.v4(),
        documentId: demoDocumentId,
        sectionId: drift.Value(demoSectionId),
        type: CardType.qa,
        front: 'What is Smart Forecast?',
        back: 'Smart Forecast is a spaced repetition learning app that helps you remember what you read by creating flashcards from your documents.',
        tags: '["demo", "intro"]',
        status: CardStatus.active,
        sourceSnippet: drift.Value('Smart Forecast is designed to help you retain knowledge from documents using proven spaced repetition techniques.'),
        sourceAnchor: drift.Value(PDFAnchor(page: 0, fallbackHash: 'demo').toJsonString()),
        createdAt: now,
        updatedAt: now,
      ),
      
      // Definition Card
      CardsCompanion.insert(
        id: _uuid.v4(),
        documentId: demoDocumentId,
        sectionId: drift.Value(demoSectionId),
        type: CardType.qa,
        front: 'What is spaced repetition?',
        back: 'Spaced repetition is a learning technique that involves reviewing information at increasing intervals over time to improve long-term retention.',
        tags: '["demo", "concept"]',
        status: CardStatus.active,
        sourceSnippet: drift.Value('Spaced repetition is the key technique used in this app.'),
        sourceAnchor: drift.Value(PDFAnchor(page: 0, fallbackHash: 'demo').toJsonString()),
        createdAt: now,
        updatedAt: now,
      ),
      
      // Cloze Deletion Card
      CardsCompanion.insert(
        id: _uuid.v4(),
        documentId: demoDocumentId,
        sectionId: drift.Value(demoSectionId),
        type: CardType.cloze,
        front: 'The app uses the [...] algorithm to schedule card reviews.',
        back: 'SM-2',
        tags: '["demo", "technical"]',
        status: CardStatus.active,
        sourceSnippet: drift.Value('The app uses the SM-2 algorithm to schedule card reviews.'),
        sourceAnchor: drift.Value(PDFAnchor(page: 0, fallbackHash: 'demo').toJsonString()),
        createdAt: now,
        updatedAt: now,
      ),

      // How-to Card
      CardsCompanion.insert(
        id: _uuid.v4(),
        documentId: demoDocumentId,
        sectionId: drift.Value(demoSectionId),
        type: CardType.qa,
        front: 'How do you create cards from a document?',
        back: '1. Import a PDF or text document\n2. Navigate to the Create tab\n3. Select a section\n4. Review and activate generated cards',
        tags: '["demo", "tutorial"]',
        status: CardStatus.active,
        sourceSnippet: drift.Value('To create cards, import a document, select sections, and review the generated cards.'),
        sourceAnchor: drift.Value(PDFAnchor(page: 0, fallbackHash: 'demo').toJsonString()),
        createdAt: now,
        updatedAt: now,
      ),

      // Feature Card
      CardsCompanion.insert(
        id: _uuid.v4(),
        documentId: demoDocumentId,
        sectionId: drift.Value(demoSectionId),
        type: CardType.qa,
        front: 'What are the main features of Smart Forecast?',
        back: '• PDF import and reading\n• Automatic card generation\n• Spaced repetition reviews\n• Progress tracking\n• Custom card editing',
        tags: '["demo", "features"]',
        status: CardStatus.active,
        sourceSnippet: drift.Value('Key features include PDF import, card generation, and spaced repetition.'),
        sourceAnchor: drift.Value(PDFAnchor(page: 0, fallbackHash: 'demo').toJsonString()),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final card in demoCards) {
      await _database.into(_database.cards).insert(card);
    }
  }

  /// Returns the demo section text content
  String _getDemoSectionText() {
    return '''
Smart Forecast: Your Personal Learning Assistant

Smart Forecast is designed to help you retain knowledge from documents using proven spaced repetition techniques. Whether you're studying textbooks, research papers, or professional documentation, this app transforms your reading into lasting knowledge.

Spaced repetition is the key technique used in this app. It's a learning method where you review information at increasing intervals, which has been scientifically proven to improve long-term memory retention significantly better than traditional study methods.

The app uses the SM-2 algorithm to schedule card reviews. This algorithm, developed in the 1980s for the SuperMemo software, calculates optimal review intervals based on how well you remember each card. The better you perform, the longer the intervals become.

Getting Started

To create cards, import a document using the Library tab, select sections you want to learn from in the Create tab, and review the automatically generated cards. You can edit any card before activating it for study.

Key Features

The app includes PDF import and reading capabilities, automatic flashcard generation from text, spaced repetition review sessions, comprehensive progress tracking, and full card editing functionality. You can organize cards by document and section, making it easy to focus on specific topics.

Start Learning

Try reviewing the demo cards in the Review tab to see how spaced repetition works. As you rate each card, the algorithm will automatically schedule your next review at the optimal time for retention.
''';
  }
}
