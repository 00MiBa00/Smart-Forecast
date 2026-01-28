import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../data/database/database.dart';
import '../../data/models/document_type.dart';
import '../../data/models/card_type.dart';
import '../../data/models/card_status.dart';
import '../../data/models/srs_grade.dart';

/// Service for seeding demo content into the database
/// This ensures the app has immediate value on first launch
class DemoSeeder {
  static const String _demoDocId = 'demo-document-001';
  static const String _demoAssetPath = 'assets/demo/RecallDoc_Demo.pdf';
  
  final AppDatabase _database;
  final _uuid = const Uuid();

  DemoSeeder(this._database);

  /// Check if demo content already exists
  Future<bool> demoExists() async {
    final doc = await (_database.select(_database.documents)
          ..where((d) => d.id.equals(_demoDocId)))
        .getSingleOrNull();
    return doc != null;
  }

  /// Get the demo document if it exists
  Future<Document?> getDemoDocument() async {
    return await (_database.select(_database.documents)
          ..where((d) => d.id.equals(_demoDocId)))
        .getSingleOrNull();
  }

  /// Ensure demo exists and return the document ID
  /// If demo already exists, returns the existing doc ID
  /// If not, creates it and returns the new doc ID
  Future<String> ensureDemoExists() async {
    if (await demoExists()) {
      return _demoDocId;
    }
    
    await _seedDemoContent();
    return _demoDocId;
  }

  /// Seed all demo content: document, sections, cards, and SRS records
  Future<void> _seedDemoContent() async {
    await _database.transaction(() async {
      // 1. Copy demo PDF to app documents directory (if asset exists)
      final localPath = await _copyDemoAsset();
      
      // 2. Create demo document
      await _createDemoDocument(localPath);
      
      // 3. Create sections
      final sectionIds = await _createDemoSections();
      
      // 4. Create cards
      final cardIds = await _createDemoCards(sectionIds);
      
      // 5. Create SRS records with due dates
      await _createDemoSRSRecords(cardIds);
      
      // 6. Update document counts
      await _updateDocumentCounts();
    });
  }

  /// Copy demo PDF from assets to app documents directory
  Future<String> _copyDemoAsset() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final demoDir = Directory(p.join(docDir.path, 'demo'));
      
      if (!await demoDir.exists()) {
        await demoDir.create(recursive: true);
      }
      
      final targetPath = p.join(demoDir.path, 'RecallDoc_Demo.pdf');
      final targetFile = File(targetPath);
      
      // Try to copy from assets
      try {
        final byteData = await rootBundle.load(_demoAssetPath);
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());
        return targetPath;
      } catch (e) {
        // If asset doesn't exist, return a placeholder path
        // The app will still work with the demo data in DB
        return targetPath;
      }
    } catch (e) {
      // Fallback path if something goes wrong
      final docDir = await getApplicationDocumentsDirectory();
      return p.join(docDir.path, 'demo', 'RecallDoc_Demo.pdf');
    }
  }

  Future<void> _createDemoDocument(String localPath) async {
    final now = DateTime.now();
    
    await _database.into(_database.documents).insert(
      DocumentsCompanion(
        id: drift.Value(_demoDocId),
        title: const drift.Value('Introduction to Spaced Repetition'),
        type: const drift.Value(DocumentType.pdf),
        localFilePath: drift.Value(localPath),
        importedAt: drift.Value(now),
        updatedAt: drift.Value(now),
        lastOpenedAt: drift.Value(now),
        pagesCount: const drift.Value(3),
        sectionsCount: const drift.Value(3),
        cardsCount: const drift.Value(20),
        language: const drift.Value('en'),
        isDemo: const drift.Value(true),
      ),
    );
  }

  Future<List<String>> _createDemoSections() async {
    final now = DateTime.now();
    final sectionIds = <String>[];

    // Section 1: What is Spaced Repetition?
    final section1Id = _uuid.v4();
    sectionIds.add(section1Id);
    await _database.into(_database.sections).insert(
      SectionsCompanion(
        id: drift.Value(section1Id),
        documentId: const drift.Value(_demoDocId),
        title: const drift.Value('What is Spaced Repetition?'),
        tags: const drift.Value('["fundamentals", "introduction"]'),
        difficulty: const drift.Value(0),
        anchorStart: const drift.Value('{"type":"pdf","page":0,"hash":"intro-section"}'),
        extractedText: const drift.Value(
          'Spaced repetition is a learning technique that involves reviewing information at increasing intervals over time. '
          'This method leverages the psychological spacing effect, where information is more effectively encoded into long-term memory '
          'when learning sessions are spaced out rather than massed together. The technique has been scientifically proven to improve '
          'retention and reduce study time significantly.'
        ),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // Section 2: Benefits and Applications
    final section2Id = _uuid.v4();
    sectionIds.add(section2Id);
    await _database.into(_database.sections).insert(
      SectionsCompanion(
        id: drift.Value(section2Id),
        documentId: const drift.Value(_demoDocId),
        title: const drift.Value('Benefits and Applications'),
        tags: const drift.Value('["benefits", "applications"]'),
        difficulty: const drift.Value(1),
        anchorStart: const drift.Value('{"type":"pdf","page":1,"hash":"benefits-section"}'),
        extractedText: const drift.Value(
          'Spaced repetition systems (SRS) are particularly effective for language learning, medical education, and any field '
          'requiring memorization of large amounts of information. Studies show that spaced repetition can improve retention rates '
          'by up to 200% compared to traditional study methods. The technique works by scheduling reviews just before you are likely '
          'to forget, optimizing the learning process and making efficient use of study time.'
        ),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // Section 3: Using RecallDoc
    final section3Id = _uuid.v4();
    sectionIds.add(section3Id);
    await _database.into(_database.sections).insert(
      SectionsCompanion(
        id: drift.Value(section3Id),
        documentId: const drift.Value(_demoDocId),
        title: const drift.Value('Using RecallDoc'),
        tags: const drift.Value('["tutorial", "howto"]'),
        difficulty: const drift.Value(0),
        anchorStart: const drift.Value('{"type":"pdf","page":2,"hash":"howto-section"}'),
        extractedText: const drift.Value(
          'RecallDoc helps you apply spaced repetition to your reading materials. Import PDFs or Markdown documents, '
          'create sections from important passages, and generate flashcards automatically. The built-in SRS algorithm '
          'schedules reviews at optimal intervals based on your performance. Regular review sessions help cement knowledge '
          'from your reading into long-term memory.'
        ),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    return sectionIds;
  }

  Future<List<String>> _createDemoCards(List<String> sectionIds) async {
    final now = DateTime.now();
    final cardIds = <String>[];

    // Cards for Section 1 (What is Spaced Repetition?)
    final section1Cards = [
      {
        'type': CardType.qa,
        'front': 'What is spaced repetition?',
        'back': 'A learning technique that involves reviewing information at increasing intervals over time, leveraging the psychological spacing effect.',
        'snippet': 'Spaced repetition is a learning technique...',
      },
      {
        'type': CardType.qa,
        'front': 'What is the spacing effect?',
        'back': 'A psychological phenomenon where information is more effectively encoded into long-term memory when learning sessions are spaced out rather than massed together.',
        'snippet': 'This method leverages the psychological spacing effect...',
      },
      {
        'type': CardType.trueFalse,
        'front': 'Spaced repetition requires massing study sessions together.',
        'back': 'False - Spaced repetition involves spacing out learning sessions at increasing intervals.',
        'snippet': 'learning sessions are spaced out rather than massed together',
      },
      {
        'type': CardType.cloze,
        'front': 'Spaced repetition has been {{c1::scientifically proven}} to improve retention.',
        'back': 'scientifically proven',
        'snippet': 'The technique has been scientifically proven to improve retention',
      },
      {
        'type': CardType.qa,
        'front': 'How does spaced repetition affect study time?',
        'back': 'It significantly reduces the amount of study time needed while improving retention.',
        'snippet': 'reduce study time significantly',
      },
    ];

    for (final cardData in section1Cards) {
      final cardId = _uuid.v4();
      cardIds.add(cardId);
      await _database.into(_database.cards).insert(
        CardsCompanion(
          id: drift.Value(cardId),
          documentId: const drift.Value(_demoDocId),
          sectionId: drift.Value(sectionIds[0]),
          type: drift.Value(cardData['type'] as CardType),
          front: drift.Value(cardData['front'] as String),
          back: drift.Value(cardData['back'] as String),
          tags: const drift.Value('["demo", "fundamentals"]'),
          status: const drift.Value(CardStatus.active),
          sourceSnippet: drift.Value(cardData['snippet'] as String),
          sourceAnchor: const drift.Value('{"type":"pdf","page":0,"hash":"intro-section"}'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
    }

    // Cards for Section 2 (Benefits and Applications)
    final section2Cards = [
      {
        'type': CardType.qa,
        'front': 'What fields are spaced repetition systems particularly effective for?',
        'back': 'Language learning, medical education, and any field requiring memorization of large amounts of information.',
        'snippet': 'particularly effective for language learning, medical education...',
      },
      {
        'type': CardType.qa,
        'front': 'By how much can spaced repetition improve retention rates compared to traditional methods?',
        'back': 'Up to 200%',
        'snippet': 'improve retention rates by up to 200%',
      },
      {
        'type': CardType.cloze,
        'front': 'Spaced repetition works by scheduling reviews {{c1::just before you are likely to forget}}.',
        'back': 'just before you are likely to forget',
        'snippet': 'scheduling reviews just before you are likely to forget',
      },
      {
        'type': CardType.trueFalse,
        'front': 'Spaced repetition systems are only useful for language learning.',
        'back': 'False - They are effective for language learning, medical education, and any field requiring memorization.',
        'snippet': 'particularly effective for language learning, medical education, and any field',
      },
      {
        'type': CardType.qa,
        'front': 'What does SRS stand for?',
        'back': 'Spaced Repetition System',
        'snippet': 'Spaced repetition systems (SRS)',
      },
      {
        'type': CardType.cloze,
        'front': 'The SRS technique optimizes learning by {{c1::making efficient use of study time}}.',
        'back': 'making efficient use of study time',
        'snippet': 'making efficient use of study time',
      },
      {
        'type': CardType.qa,
        'front': 'When does spaced repetition schedule reviews?',
        'back': 'Just before you are likely to forget, optimizing the learning process.',
        'snippet': 'scheduling reviews just before you are likely to forget, optimizing the learning process',
      },
    ];

    for (final cardData in section2Cards) {
      final cardId = _uuid.v4();
      cardIds.add(cardId);
      await _database.into(_database.cards).insert(
        CardsCompanion(
          id: drift.Value(cardId),
          documentId: const drift.Value(_demoDocId),
          sectionId: drift.Value(sectionIds[1]),
          type: drift.Value(cardData['type'] as CardType),
          front: drift.Value(cardData['front'] as String),
          back: drift.Value(cardData['back'] as String),
          tags: const drift.Value('["demo", "benefits"]'),
          status: const drift.Value(CardStatus.active),
          sourceSnippet: drift.Value(cardData['snippet'] as String),
          sourceAnchor: const drift.Value('{"type":"pdf","page":1,"hash":"benefits-section"}'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
    }

    // Cards for Section 3 (Using RecallDoc)
    final section3Cards = [
      {
        'type': CardType.qa,
        'front': 'What types of documents can RecallDoc import?',
        'back': 'PDFs and Markdown documents',
        'snippet': 'Import PDFs or Markdown documents',
      },
      {
        'type': CardType.qa,
        'front': 'What does RecallDoc help you create from important passages?',
        'back': 'Sections and flashcards',
        'snippet': 'create sections from important passages, and generate flashcards',
      },
      {
        'type': CardType.cloze,
        'front': 'RecallDoc\'s {{c1::SRS algorithm}} schedules reviews at optimal intervals.',
        'back': 'SRS algorithm',
        'snippet': 'The built-in SRS algorithm schedules reviews',
      },
      {
        'type': CardType.trueFalse,
        'front': 'RecallDoc can automatically generate flashcards from your documents.',
        'back': 'True',
        'snippet': 'generate flashcards automatically',
      },
      {
        'type': CardType.qa,
        'front': 'How does RecallDoc determine when to schedule reviews?',
        'back': 'Based on your performance, using the built-in SRS algorithm.',
        'snippet': 'schedules reviews at optimal intervals based on your performance',
      },
      {
        'type': CardType.qa,
        'front': 'What is the purpose of regular review sessions in RecallDoc?',
        'back': 'To cement knowledge from your reading into long-term memory.',
        'snippet': 'Regular review sessions help cement knowledge from your reading into long-term memory',
      },
      {
        'type': CardType.cloze,
        'front': 'RecallDoc helps you apply {{c1::spaced repetition}} to your reading materials.',
        'back': 'spaced repetition',
        'snippet': 'apply spaced repetition to your reading materials',
      },
      {
        'type': CardType.trueFalse,
        'front': 'RecallDoc requires manual scheduling of all review sessions.',
        'back': 'False - The built-in SRS algorithm automatically schedules reviews at optimal intervals.',
        'snippet': 'SRS algorithm schedules reviews at optimal intervals',
      },
    ];

    for (final cardData in section3Cards) {
      final cardId = _uuid.v4();
      cardIds.add(cardId);
      await _database.into(_database.cards).insert(
        CardsCompanion(
          id: drift.Value(cardId),
          documentId: const drift.Value(_demoDocId),
          sectionId: drift.Value(sectionIds[2]),
          type: drift.Value(cardData['type'] as CardType),
          front: drift.Value(cardData['front'] as String),
          back: drift.Value(cardData['back'] as String),
          tags: const drift.Value('["demo", "tutorial"]'),
          status: const drift.Value(CardStatus.active),
          sourceSnippet: drift.Value(cardData['snippet'] as String),
          sourceAnchor: const drift.Value('{"type":"pdf","page":2,"hash":"howto-section"}'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
    }

    return cardIds;
  }

  Future<void> _createDemoSRSRecords(List<String> cardIds) async {
    final now = DateTime.now();
    
    // Make first 12 cards due immediately (so reviewer sees due cards right away)
    for (var i = 0; i < 12 && i < cardIds.length; i++) {
      await _database.into(_database.sRSRecords).insert(
        SRSRecordsCompanion(
          cardId: drift.Value(cardIds[i]),
          dueAt: drift.Value(now.subtract(const Duration(minutes: 1))), // Already due
          intervalDays: const drift.Value(0.0),
          easeFactor: const drift.Value(2.5),
          lapses: const drift.Value(0),
          lastGrade: const drift.Value(SRSGrade.good),
          updatedAt: drift.Value(now),
        ),
      );
    }
    
    // Make remaining cards due in the near future (1-3 days)
    for (var i = 12; i < cardIds.length; i++) {
      final daysFuture = 1 + (i % 3); // Distribute across 1-3 days
      await _database.into(_database.sRSRecords).insert(
        SRSRecordsCompanion(
          cardId: drift.Value(cardIds[i]),
          dueAt: drift.Value(now.add(Duration(days: daysFuture))),
          intervalDays: drift.Value(daysFuture.toDouble()),
          easeFactor: const drift.Value(2.5),
          lapses: const drift.Value(0),
          lastGrade: drift.Value(null),
          updatedAt: drift.Value(now),
        ),
      );
    }
  }

  Future<void> _updateDocumentCounts() async {
    final sectionsCount = await (_database.selectOnly(_database.sections)
          ..addColumns([_database.sections.id.count()])
          ..where(_database.sections.documentId.equals(_demoDocId)))
        .getSingle()
        .then((row) => row.read(_database.sections.id.count()) ?? 0);

    final cardsCount = await (_database.selectOnly(_database.cards)
          ..addColumns([_database.cards.id.count()])
          ..where(_database.cards.documentId.equals(_demoDocId)))
        .getSingle()
        .then((row) => row.read(_database.cards.id.count()) ?? 0);

    await (_database.update(_database.documents)
          ..where((d) => d.id.equals(_demoDocId)))
        .write(
      DocumentsCompanion(
        sectionsCount: drift.Value(sectionsCount),
        cardsCount: drift.Value(cardsCount),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Delete demo content (useful for testing)
  Future<void> deleteDemoContent() async {
    await (_database.delete(_database.documents)
          ..where((d) => d.id.equals(_demoDocId)))
        .go();
  }
}
