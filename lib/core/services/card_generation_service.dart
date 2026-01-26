import '../../data/database/database.dart';
import '../../data/models/card_type.dart';
import '../../data/models/card_status.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

/// Represents a generated card before it's persisted to the database
class GeneratedCard {
  final String id;
  final String documentId;
  final String sectionId;
  final CardType type;
  final String front;
  final String back;
  final List<String> tags;
  final CardStatus status;
  final String sourceSnippet;
  final String sourceAnchor;

  GeneratedCard({
    required this.id,
    required this.documentId,
    required this.sectionId,
    required this.type,
    required this.front,
    required this.back,
    this.tags = const [],
    this.status = CardStatus.draft,
    required this.sourceSnippet,
    required this.sourceAnchor,
  });

  /// Convert to CardsCompanion for database insertion
  CardsCompanion toCompanion() {
    final now = DateTime.now();
    return CardsCompanion.insert(
      id: id,
      documentId: documentId,
      sectionId: drift.Value(sectionId),
      type: type,
      front: front,
      back: back,
      tags: '[]', // JSON array
      status: status,
      sourceSnippet: drift.Value(sourceSnippet),
      sourceAnchor: drift.Value(sourceAnchor),
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Service for generating cards from section text using predefined templates
class CardGenerationService {
  final _uuid = const Uuid();

  /// Generate cards from a section
  /// Returns 3-7 draft cards based on content analysis
  List<GeneratedCard> generateCardsFromSection({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String extractedText,
    required String anchorStart,
  }) {
    final trimmedText = extractedText.trim();

    // Validate minimum content length
    if (trimmedText.length < 20) {
      return [];
    }

    final cards = <GeneratedCard>[];
    final sourceSnippet = _truncate(trimmedText, 500);

    // Preprocess text
    final sentences = _splitIntoSentences(trimmedText);
    final lines = trimmedText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final bulletPoints = _extractBulletPoints(lines);

    // Apply templates in priority order
    
    // 1. Definition Card (highest priority)
    final definitionCard = _generateDefinitionCard(
      documentId: documentId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      sentences: sentences,
      sourceSnippet: sourceSnippet,
      sourceAnchor: anchorStart,
    );
    if (definitionCard != null) cards.add(definitionCard);

    // 2. Use Case Card
    final useCaseCard = _generateUseCaseCard(
      documentId: documentId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      sentences: sentences,
      sourceSnippet: sourceSnippet,
      sourceAnchor: anchorStart,
    );
    if (useCaseCard != null) cards.add(useCaseCard);

    // 3. List Card (if bullet points exist)
    if (bulletPoints.isNotEmpty) {
      final listCard = _generateListCard(
        documentId: documentId,
        sectionId: sectionId,
        sectionTitle: sectionTitle,
        bulletPoints: bulletPoints,
        sourceSnippet: sourceSnippet,
        sourceAnchor: anchorStart,
      );
      if (listCard != null) cards.add(listCard);
    }

    // 4. Cloze Cards (up to 2)
    final clozeCards = _generateClozeCards(
      documentId: documentId,
      sectionId: sectionId,
      sentences: sentences,
      sourceSnippet: sourceSnippet,
      sourceAnchor: anchorStart,
      maxCards: 2,
    );
    cards.addAll(clozeCards);

    // 5. True/False Cards (fill up to 7 total)
    final trueFalseCards = _generateTrueFalseCards(
      documentId: documentId,
      sectionId: sectionId,
      sentences: sentences,
      sourceSnippet: sourceSnippet,
      sourceAnchor: anchorStart,
      maxCards: 7 - cards.length,
    );
    cards.addAll(trueFalseCards);

    // Ensure minimum 3 cards, maximum 7 cards
    if (cards.length < 3) {
      // Generate more True/False cards to reach minimum
      final additionalTF = _generateTrueFalseCards(
        documentId: documentId,
        sectionId: sectionId,
        sentences: sentences,
        sourceSnippet: sourceSnippet,
        sourceAnchor: anchorStart,
        maxCards: 3 - cards.length,
      );
      cards.addAll(additionalTF);
    }

    return cards.take(7).toList();
  }

  /// Generate a definition card (QA type)
  GeneratedCard? _generateDefinitionCard({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required List<String> sentences,
    required String sourceSnippet,
    required String sourceAnchor,
  }) {
    // Keywords that indicate a definition
    final definitionKeywords = [
      'is',
      'are',
      'means',
      'defined as',
      'refers to',
      'represents',
      'describes',
    ];

    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      
      // Check if sentence contains definition keywords
      final hasDefinitionKeyword = definitionKeywords.any((kw) => lowerSentence.contains(kw));
      
      if (hasDefinitionKeyword && sentence.length > 15) {
        // Extract the term (usually before the keyword)
        String term = sectionTitle;
        
        // Try to find the term before "is" or "means"
        for (final keyword in ['is', 'means', 'defined as']) {
          if (lowerSentence.contains(keyword)) {
            final parts = sentence.split(RegExp(keyword, caseSensitive: false));
            if (parts.isNotEmpty) {
              term = parts[0].trim();
              // Clean up articles
              term = term.replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
              break;
            }
          }
        }

        return GeneratedCard(
          id: _uuid.v4(),
          documentId: documentId,
          sectionId: sectionId,
          type: CardType.qa,
          front: 'What is $term?',
          back: sentence,
          sourceSnippet: sourceSnippet,
          sourceAnchor: sourceAnchor,
        );
      }
    }

    return null;
  }

  /// Generate a use case card (QA type)
  GeneratedCard? _generateUseCaseCard({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required List<String> sentences,
    required String sourceSnippet,
    required String sourceAnchor,
  }) {
    final useCaseKeywords = [
      'use',
      'used when',
      'should be used',
      'recommended',
      'best for',
      'ideal for',
      'useful when',
    ];

    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      
      if (useCaseKeywords.any((kw) => lowerSentence.contains(kw)) && sentence.length > 15) {
        return GeneratedCard(
          id: _uuid.v4(),
          documentId: documentId,
          sectionId: sectionId,
          type: CardType.qa,
          front: 'When should $sectionTitle be used?',
          back: sentence,
          sourceSnippet: sourceSnippet,
          sourceAnchor: sourceAnchor,
        );
      }
    }

    return null;
  }

  /// Generate a list card (QA type)
  GeneratedCard? _generateListCard({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required List<String> bulletPoints,
    required String sourceSnippet,
    required String sourceAnchor,
  }) {
    if (bulletPoints.isEmpty) return null;

    // Join bullet points into a numbered list
    final back = bulletPoints
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return GeneratedCard(
      id: _uuid.v4(),
      documentId: documentId,
      sectionId: sectionId,
      type: CardType.qa,
      front: 'List the main points about $sectionTitle',
      back: back,
      sourceSnippet: sourceSnippet,
      sourceAnchor: sourceAnchor,
    );
  }

  /// Generate cloze cards
  List<GeneratedCard> _generateClozeCards({
    required String documentId,
    required String sectionId,
    required List<String> sentences,
    required String sourceSnippet,
    required String sourceAnchor,
    required int maxCards,
  }) {
    final cards = <GeneratedCard>[];

    for (final sentence in sentences) {
      if (cards.length >= maxCards) break;
      if (sentence.length < 20) continue;

      // Extract key nouns/terms (words with capital letters or technical terms)
      final words = sentence.split(' ');
      String? keyTerm;

      for (final word in words) {
        // Look for capitalized words (but not first word) or longer technical terms
        if (word.length > 5 && 
            (word[0] == word[0].toUpperCase() && words.indexOf(word) > 0) ||
            word.contains('_') ||
            word.contains('-')) {
          keyTerm = word.replaceAll(RegExp(r'[.,;:!?]$'), '');
          break;
        }
      }

      // If no key term found, use a significant word (not articles, prepositions, etc.)
      if (keyTerm == null) {
        final stopWords = ['the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'to', 'for'];
        for (final word in words) {
          if (word.length > 5 && !stopWords.contains(word.toLowerCase())) {
            keyTerm = word.replaceAll(RegExp(r'[.,;:!?]$'), '');
            break;
          }
        }
      }

      if (keyTerm != null && keyTerm.isNotEmpty) {
        final front = sentence.replaceFirst(keyTerm, '{{...}}');
        
        cards.add(GeneratedCard(
          id: _uuid.v4(),
          documentId: documentId,
          sectionId: sectionId,
          type: CardType.cloze,
          front: front,
          back: keyTerm,
          sourceSnippet: sourceSnippet,
          sourceAnchor: sourceAnchor,
        ));
      }
    }

    return cards;
  }

  /// Generate true/false cards
  List<GeneratedCard> _generateTrueFalseCards({
    required String documentId,
    required String sectionId,
    required List<String> sentences,
    required String sourceSnippet,
    required String sourceAnchor,
    required int maxCards,
  }) {
    final cards = <GeneratedCard>[];

    for (final sentence in sentences) {
      if (cards.length >= maxCards) break;
      if (sentence.length < 15) continue;

      // Create a true/false card from factual sentences
      cards.add(GeneratedCard(
        id: _uuid.v4(),
        documentId: documentId,
        sectionId: sectionId,
        type: CardType.trueFalse,
        front: sentence,
        back: 'true',
        sourceSnippet: sourceSnippet,
        sourceAnchor: sourceAnchor,
      ));
    }

    return cards;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting (could be improved)
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();
  }

  /// Extract bullet points from lines
  List<String> _extractBulletPoints(List<String> lines) {
    final bullets = <String>[];
    
    for (final line in lines) {
      // Check for bullet point markers
      if (line.startsWith('- ') || 
          line.startsWith('* ') || 
          line.startsWith('• ') ||
          RegExp(r'^\d+\.\s').hasMatch(line)) {
        // Remove bullet marker
        final cleaned = line.replaceFirst(RegExp(r'^[-*•]\s+|\d+\.\s+'), '').trim();
        if (cleaned.isNotEmpty) {
          bullets.add(cleaned);
        }
      }
    }

    return bullets;
  }

  /// Truncate text to max length
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
