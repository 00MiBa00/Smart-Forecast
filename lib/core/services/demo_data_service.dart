import 'package:uuid/uuid.dart';
import '../../data/database/database.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/section_repository.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/models/document_type.dart';
import '../../data/models/card_type.dart';
import '../../data/models/card_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

class DemoDataService {
  final DocumentRepository _documentRepo;
  final SectionRepository _sectionRepo;
  final CardRepository _cardRepo;
  final Uuid _uuid = const Uuid();

  DemoDataService({
    required DocumentRepository documentRepo,
    required SectionRepository sectionRepo,
    required CardRepository cardRepo,
  })  : _documentRepo = documentRepo,
        _sectionRepo = sectionRepo,
        _cardRepo = cardRepo;

  static const String _demoDataKey = 'demo_data_initialized';
  static const String _demoDataVersionKey = 'demo_data_version';
  static const int _currentDemoDataVersion = 2; // Increment when adding new demo content

  Future<bool> isDemoDataInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_demoDataVersionKey) ?? 0;
    return version >= _currentDemoDataVersion;
  }

  Future<void> markDemoDataInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoDataKey, true);
    await prefs.setInt(_demoDataVersionKey, _currentDemoDataVersion);
  }

  Future<void> initializeDemoData() async {
    // Check if already initialized
    if (await isDemoDataInitialized()) {
      return;
    }

    // Clear any existing demo documents (in case of upgrade from old version)
    await _clearOldDemoDocuments();

    final now = DateTime.now();

    // Create 4 demo documents
    await _createWelcomeDocument(now);
    await _createiOSDevelopmentDocument(now);
    await _createLearningTechniquesDocument(now);
    await _createMemoryRetentionDocument(now);

    // Mark as initialized
    await markDemoDataInitialized();
  }

  Future<void> _clearOldDemoDocuments() async {
    // Get all documents with empty localFilePath (demo documents)
    final allDocs = await _documentRepo.getAllDocuments();
    for (final doc in allDocs) {
      if (doc.localFilePath.isEmpty) {
        await _documentRepo.deleteDocument(doc.id);
      }
    }
  }

  Future<void> _createWelcomeDocument(DateTime now) async {
    final docId = _uuid.v4();

    await _documentRepo.createDocument(
      DocumentsCompanion.insert(
        id: docId,
        title: 'Welcome to DocTrainer',
        type: DocumentType.pdf,
        localFilePath: '', // No actual file - virtual demo document
        importedAt: now,
        updatedAt: now,
        lastOpenedAt: const Value(null),
        lastPosition: const Value(null),
        pagesCount: const Value(5),
        language: const Value('en'),
      ),
    );

    // Create demo sections and cards
    await _createIntroductionSection(docId, now);
    await _createSpacedRepetitionSection(docId, now);
    await _createTipsSection(docId, now);
  }

  Future<void> _createiOSDevelopmentDocument(DateTime now) async {
    final docId = _uuid.v4();

    await _documentRepo.createDocument(
      DocumentsCompanion.insert(
        id: docId,
        title: 'iOS Development Basics',
        type: DocumentType.pdf,
        localFilePath: '',
        importedAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        lastOpenedAt: const Value(null),
        lastPosition: const Value(null),
        pagesCount: const Value(8),
        language: const Value('en'),
      ),
    );

    await _createSwiftSection(docId, now);
    await _createUIKitSection(docId, now);
  }

  Future<void> _createLearningTechniquesDocument(DateTime now) async {
    final docId = _uuid.v4();

    await _documentRepo.createDocument(
      DocumentsCompanion.insert(
        id: docId,
        title: 'Learning Techniques',
        type: DocumentType.pdf,
        localFilePath: '',
        importedAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        lastOpenedAt: const Value(null),
        lastPosition: const Value(null),
        pagesCount: const Value(6),
        language: const Value('en'),
      ),
    );

    await _createActiveLearningSection(docId, now);
    await _createPomodoroSection(docId, now);
  }

  Future<void> _createMemoryRetentionDocument(DateTime now) async {
    final docId = _uuid.v4();

    await _documentRepo.createDocument(
      DocumentsCompanion.insert(
        id: docId,
        title: 'Memory & Retention',
        type: DocumentType.pdf,
        localFilePath: '',
        importedAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        lastOpenedAt: const Value(null),
        lastPosition: const Value(null),
        pagesCount: const Value(7),
        language: const Value('en'),
      ),
    );

    await _createMemoryFormationSection(docId, now);
    await _createRetrievalPracticeSection(docId, now);
  }

  Future<void> _createIntroductionSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'What is DocTrainer?',
      tags: ['introduction', 'getting-started'],
      difficulty: 1,
      anchorStart: '{"page": 1, "offset": 0}',
      anchorEnd: '{"page": 1, "offset": 500}',
      extractedText:
          'DocTrainer is a powerful tool for mastering documentation through active learning. '
          'Import PDFs, create study cards, and use spaced repetition to remember what you learn. '
          'Perfect for technical documentation, textbooks, research papers, and more.',
    );

    // Create cards for this section
    final cardsData = [
      {
        'front': 'What is the main purpose of DocTrainer?',
        'back':
            'To help users master documentation through active learning with spaced repetition',
        'type': CardType.qa,
      },
      {
        'front': 'What types of documents can you use with DocTrainer?',
        'back':
            'Technical documentation, textbooks, research papers, and any PDF files',
        'type': CardType.qa,
      },
      {
        'front':
            'The three main steps in DocTrainer are: Import PDFs, ___ study cards, and use spaced repetition',
        'back': 'create',
        'type': CardType.cloze,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'introduction'],
        status: CardStatus.active,
        sourceSnippet: 'DocTrainer is a powerful tool for mastering documentation...',
        sourceAnchor: '{"page": 1, "offset": 0}',
      );
    }
  }

  Future<void> _createSpacedRepetitionSection(
      String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'How Spaced Repetition Works',
      tags: ['learning', 'srs', 'algorithm'],
      difficulty: 2,
      anchorStart: '{"page": 2, "offset": 0}',
      anchorEnd: '{"page": 3, "offset": 300}',
      extractedText:
          'Spaced repetition is a learning technique that involves reviewing information at increasing intervals. '
          'When you rate a card as "Easy", the next review is scheduled further in the future. '
          'Cards marked "Again" appear more frequently until you master them. '
          'This method is scientifically proven to improve long-term retention.',
    );

    final cardsData = [
      {
        'front': 'What is spaced repetition?',
        'back':
            'A learning technique that involves reviewing information at increasing intervals',
        'type': CardType.qa,
      },
      {
        'front':
            'What happens when you mark a card as "Easy" in spaced repetition?',
        'back': 'The next review is scheduled further in the future',
        'type': CardType.qa,
      },
      {
        'front':
            'Spaced repetition is ___ to improve long-term retention',
        'back': 'scientifically proven',
        'type': CardType.cloze,
      },
      {
        'front': 'Cards marked "Again" will appear:',
        'back':
            'More frequently until you master them',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'spaced-repetition'],
        status: CardStatus.active,
        sourceSnippet: 'Spaced repetition is a learning technique...',
        sourceAnchor: '{"page": 2, "offset": 0}',
      );
    }
  }

  Future<void> _createTipsSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'Tips for Effective Learning',
      tags: ['tips', 'best-practices'],
      difficulty: 1,
      anchorStart: '{"page": 4, "offset": 0}',
      anchorEnd: '{"page": 5, "offset": 200}',
      extractedText:
          'For best results with DocTrainer: '
          '1. Study daily for consistency. '
          '2. Create cards right after reading new material. '
          '3. Keep cards focused on one concept. '
          '4. Use your own words when creating cards. '
          '5. Review regularly, even when busy.',
    );

    final cardsData = [
      {
        'front': 'How often should you study for best results?',
        'back': 'Daily for consistency',
        'type': CardType.qa,
      },
      {
        'front': 'When is the best time to create study cards?',
        'back': 'Right after reading new material',
        'type': CardType.qa,
      },
      {
        'front': 'Each study card should focus on ___ concept',
        'back': 'one',
        'type': CardType.cloze,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'tips'],
        status: CardStatus.active,
        sourceSnippet: 'For best results with DocTrainer: Study daily...',
        sourceAnchor: '{"page": 4, "offset": 0}',
      );
    }
  }

  // iOS Development document sections
  Future<void> _createSwiftSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'Swift Programming Language',
      tags: ['swift', 'programming', 'ios'],
      difficulty: 2,
      anchorStart: '{"page": 1, "offset": 0}',
      anchorEnd: '{"page": 3, "offset": 200}',
      extractedText:
          'Swift is a powerful and intuitive programming language for iOS, macOS, and more. '
          'It features modern syntax, type safety, and automatic memory management. '
          'Swift combines the best of C and Objective-C while being easier to learn and use. '
          'Key features include optionals, closures, generics, and protocol-oriented programming.',
    );

    final cardsData = [
      {
        'front': 'What is Swift?',
        'back': 'A powerful and intuitive programming language for iOS, macOS, and more',
        'type': CardType.qa,
      },
      {
        'front': 'Swift features ___ syntax, type safety, and automatic memory management',
        'back': 'modern',
        'type': CardType.cloze,
      },
      {
        'front': 'Name three key features of Swift',
        'back': 'Optionals, closures, and generics (also protocol-oriented programming)',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'swift', 'ios'],
        status: CardStatus.active,
        sourceSnippet: 'Swift is a powerful and intuitive programming language...',
        sourceAnchor: '{"page": 1, "offset": 0}',
      );
    }
  }

  Future<void> _createUIKitSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'UIKit Framework',
      tags: ['uikit', 'ui', 'ios'],
      difficulty: 3,
      anchorStart: '{"page": 4, "offset": 0}',
      anchorEnd: '{"page": 6, "offset": 400}',
      extractedText:
          'UIKit provides the core objects for building user interfaces in iOS apps. '
          'It includes views, view controllers, and event handling. '
          'UIViewController manages a screen of content, UIView represents a rectangular area, '
          'and the responder chain handles touch events throughout the app.',
    );

    final cardsData = [
      {
        'front': 'What does UIKit provide?',
        'back': 'Core objects for building user interfaces in iOS apps',
        'type': CardType.qa,
      },
      {
        'front': 'UIViewController manages a ___ of content',
        'back': 'screen',
        'type': CardType.cloze,
      },
      {
        'front': 'What handles touch events throughout an iOS app?',
        'back': 'The responder chain',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'uikit', 'ios'],
        status: CardStatus.active,
        sourceSnippet: 'UIKit provides the core objects for building user interfaces...',
        sourceAnchor: '{"page": 4, "offset": 0}',
      );
    }
  }

  // Learning Techniques document sections
  Future<void> _createActiveLearningSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'Active Learning Strategies',
      tags: ['learning', 'active-learning', 'education'],
      difficulty: 1,
      anchorStart: '{"page": 1, "offset": 0}',
      anchorEnd: '{"page": 2, "offset": 500}',
      extractedText:
          'Active learning involves engaging with material through practice and application. '
          'Instead of passively reading, try explaining concepts in your own words, '
          'creating examples, or teaching others. Question-driven learning helps identify gaps. '
          'Practice retrieval strengthens memory more than repeated reading.',
    );

    final cardsData = [
      {
        'front': 'What is active learning?',
        'back': 'Engaging with material through practice and application rather than passive reading',
        'type': CardType.qa,
      },
      {
        'front': 'Practice ___ strengthens memory more than repeated reading',
        'back': 'retrieval',
        'type': CardType.cloze,
      },
      {
        'front': 'Name two active learning strategies',
        'back': 'Explaining concepts in your own words and creating examples (also teaching others)',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'learning', 'active-learning'],
        status: CardStatus.active,
        sourceSnippet: 'Active learning involves engaging with material...',
        sourceAnchor: '{"page": 1, "offset": 0}',
      );
    }
  }

  Future<void> _createPomodoroSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'Pomodoro Technique',
      tags: ['productivity', 'time-management', 'focus'],
      difficulty: 1,
      anchorStart: '{"page": 4, "offset": 0}',
      anchorEnd: '{"page": 5, "offset": 300}',
      extractedText:
          'The Pomodoro Technique uses timed intervals to maintain focus. '
          'Work for 25 minutes (one pomodoro), then take a 5-minute break. '
          'After four pomodoros, take a longer 15-30 minute break. '
          'This prevents burnout and maintains high concentration during work periods.',
    );

    final cardsData = [
      {
        'front': 'How long is one pomodoro work interval?',
        'back': '25 minutes',
        'type': CardType.qa,
      },
      {
        'front': 'After four pomodoros, take a ___ minute break',
        'back': '15-30',
        'type': CardType.cloze,
      },
      {
        'front': 'What is the purpose of the Pomodoro Technique?',
        'back': 'To maintain focus and prevent burnout using timed intervals',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'pomodoro', 'productivity'],
        status: CardStatus.active,
        sourceSnippet: 'The Pomodoro Technique uses timed intervals...',
        sourceAnchor: '{"page": 4, "offset": 0}',
      );
    }
  }

  // Memory & Retention document sections
  Future<void> _createMemoryFormationSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'How Memory Formation Works',
      tags: ['memory', 'neuroscience', 'learning'],
      difficulty: 2,
      anchorStart: '{"page": 1, "offset": 0}',
      anchorEnd: '{"page": 3, "offset": 100}',
      extractedText:
          'Memory formation involves encoding, storage, and retrieval. '
          'The hippocampus consolidates short-term memories into long-term storage. '
          'Repetition and emotional significance strengthen neural connections. '
          'Sleep plays a crucial role in memory consolidation, organizing and strengthening memories.',
    );

    final cardsData = [
      {
        'front': 'What are the three stages of memory formation?',
        'back': 'Encoding, storage, and retrieval',
        'type': CardType.qa,
      },
      {
        'front': 'The ___ consolidates short-term memories into long-term storage',
        'back': 'hippocampus',
        'type': CardType.cloze,
      },
      {
        'front': 'What role does sleep play in memory?',
        'back': 'Memory consolidation - organizing and strengthening memories',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'memory', 'neuroscience'],
        status: CardStatus.active,
        sourceSnippet: 'Memory formation involves encoding, storage, and retrieval...',
        sourceAnchor: '{"page": 1, "offset": 0}',
      );
    }
  }

  Future<void> _createRetrievalPracticeSection(String docId, DateTime now) async {
    final sectionId = await _sectionRepo.createSection(
      documentId: docId,
      title: 'The Power of Retrieval Practice',
      tags: ['retrieval', 'testing', 'learning'],
      difficulty: 2,
      anchorStart: '{"page": 5, "offset": 0}',
      anchorEnd: '{"page": 7, "offset": 200}',
      extractedText:
          'Retrieval practice, or testing yourself, is more effective than re-reading. '
          'The act of recalling information strengthens memory pathways. '
          'This is called the "testing effect" - even failed retrieval attempts improve learning. '
          'Flashcards and practice questions leverage this principle for efficient study.',
    );

    final cardsData = [
      {
        'front': 'Why is retrieval practice more effective than re-reading?',
        'back': 'The act of recalling information strengthens memory pathways',
        'type': CardType.qa,
      },
      {
        'front': 'The ___ effect shows that even failed retrieval attempts improve learning',
        'back': 'testing',
        'type': CardType.cloze,
      },
      {
        'front': 'Name two tools that use retrieval practice',
        'back': 'Flashcards and practice questions',
        'type': CardType.qa,
      },
    ];

    for (var cardData in cardsData) {
      await _cardRepo.createCard(
        documentId: docId,
        sectionId: sectionId,
        type: cardData['type'] as CardType,
        front: cardData['front'] as String,
        back: cardData['back'] as String,
        tags: ['demo', 'retrieval', 'testing'],
        status: CardStatus.active,
        sourceSnippet: 'Retrieval practice, or testing yourself, is more effective...',
        sourceAnchor: '{"page": 5, "offset": 0}',
      );
    }
  }
}
