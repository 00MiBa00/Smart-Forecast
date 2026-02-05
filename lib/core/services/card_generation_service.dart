import 'package:uuid/uuid.dart';
import '../../data/models/card_type.dart';
import '../../data/models/anchor.dart';

/// Represents a card generated from document text
class GeneratedCard {
  final String id;
  final String documentId;
  final String? sectionId;
  final CardType type;
  final String front;
  final String back;
  final String? sourceSnippet;
  final Anchor? sourceAnchor;

  GeneratedCard({
    required this.id,
    required this.documentId,
    this.sectionId,
    required this.type,
    required this.front,
    required this.back,
    this.sourceSnippet,
    this.sourceAnchor,
  });

  GeneratedCard copyWith({
    String? id,
    String? documentId,
    String? sectionId,
    CardType? type,
    String? front,
    String? back,
    String? sourceSnippet,
    Anchor? sourceAnchor,
  }) {
    return GeneratedCard(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sectionId: sectionId ?? this.sectionId,
      type: type ?? this.type,
      front: front ?? this.front,
      back: back ?? this.back,
      sourceSnippet: sourceSnippet ?? this.sourceSnippet,
      sourceAnchor: sourceAnchor ?? this.sourceAnchor,
    );
  }
}

/// Service for generating flashcards from document sections
class CardGenerationService {
  final _uuid = const Uuid();

  /// Generates flashcards from a document section
  /// 
  /// Uses pattern matching and heuristics to identify potential Q&A pairs
  /// from the extracted text.
  List<GeneratedCard> generateCardsFromSection({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String extractedText,
    required Anchor anchorStart,
  }) {
    final cards = <GeneratedCard>[];
    
    // Clean up the text
    final text = extractedText.trim();
    if (text.isEmpty) {
      return cards;
    }

    // Try different generation strategies
    cards.addAll(_generateFromDefinitions(
      documentId: documentId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      text: text,
      anchorStart: anchorStart,
    ));

    cards.addAll(_generateFromKeyPoints(
      documentId: documentId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      text: text,
      anchorStart: anchorStart,
    ));

    cards.addAll(_generateFromQuestions(
      documentId: documentId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      text: text,
      anchorStart: anchorStart,
    ));

    return cards;
  }

  /// Generates cards from definition-like patterns
  /// Pattern: "X is Y" or "X: Y"
  List<GeneratedCard> _generateFromDefinitions({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String text,
    required Anchor anchorStart,
  }) {
    final cards = <GeneratedCard>[];
    
    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    
    for (final sentence in sentences) {
      // Look for "is/are" definitions
      final isMatch = RegExp(r'^(.+?)\s+(?:is|are)\s+(.+)$', caseSensitive: false).firstMatch(sentence.trim());
      if (isMatch != null) {
        final term = isMatch.group(1)?.trim();
        final definition = isMatch.group(2)?.trim();
        
        if (term != null && definition != null && term.split(' ').length <= 6 && definition.split(' ').length >= 3) {
          cards.add(GeneratedCard(
            id: _uuid.v4(),
            documentId: documentId,
            sectionId: sectionId,
            type: CardType.qa,
            front: 'What is $term?',
            back: definition,
            sourceSnippet: sentence.trim(),
            sourceAnchor: anchorStart,
          ));
        }
      }
      
      // Look for colon definitions
      final colonMatch = RegExp(r'^(.+?):\s+(.+)$').firstMatch(sentence.trim());
      if (colonMatch != null) {
        final term = colonMatch.group(1)?.trim();
        final definition = colonMatch.group(2)?.trim();
        
        if (term != null && definition != null && term.split(' ').length <= 6 && definition.split(' ').length >= 3) {
          cards.add(GeneratedCard(
            id: _uuid.v4(),
            documentId: documentId,
            sectionId: sectionId,
            type: CardType.qa,
            front: 'Define: $term',
            back: definition,
            sourceSnippet: sentence.trim(),
            sourceAnchor: anchorStart,
          ));
        }
      }
    }
    
    return cards;
  }

  /// Generates cards from key points or bullet points
  List<GeneratedCard> _generateFromKeyPoints({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String text,
    required Anchor anchorStart,
  }) {
    final cards = <GeneratedCard>[];
    
    // Look for numbered or bulleted lists
    final lines = text.split('\n');
    final keyPoints = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      // Match bullet points or numbered lists
      if (RegExp(r'^[\-\*•]\s+|^\d+[\.\)]\s+').hasMatch(trimmed)) {
        final point = trimmed.replaceFirst(RegExp(r'^[\-\*•]\s+|^\d+[\.\)]\s+'), '');
        if (point.split(' ').length >= 5) {
          keyPoints.add(point);
        }
      }
    }
    
    // Generate cloze deletion cards for key points
    for (final point in keyPoints) {
      final words = point.split(' ');
      if (words.length >= 5) {
        // Find important words (typically nouns, longer words)
        for (int i = 0; i < words.length; i++) {
          final word = words[i];
          if (word.length >= 4 && !_isCommonWord(word.toLowerCase())) {
            final clozeText = words.asMap().entries.map((e) {
              return e.key == i ? '[...]' : e.value;
            }).join(' ');
            
            cards.add(GeneratedCard(
              id: _uuid.v4(),
              documentId: documentId,
              sectionId: sectionId,
              type: CardType.cloze,
              front: clozeText,
              back: word,
              sourceSnippet: point,
              sourceAnchor: anchorStart,
            ));
            break; // Only one cloze per point
          }
        }
      }
    }
    
    return cards;
  }

  /// Generates cards from questions found in text
  List<GeneratedCard> _generateFromQuestions({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String text,
    required Anchor anchorStart,
  }) {
    final cards = <GeneratedCard>[];
    
    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    
    for (int i = 0; i < sentences.length - 1; i++) {
      final sentence = sentences[i].trim();
      final nextSentence = sentences[i + 1].trim();
      
      // If sentence ends with '?' it's a question
      if (sentence.endsWith('?')) {
        cards.add(GeneratedCard(
          id: _uuid.v4(),
          documentId: documentId,
          sectionId: sectionId,
          type: CardType.qa,
          front: sentence,
          back: nextSentence,
          sourceSnippet: '$sentence $nextSentence',
          sourceAnchor: anchorStart,
        ));
      }
    }
    
    return cards;
  }

  /// Checks if a word is too common to be useful for cloze deletion
  bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
      'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
      'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
      'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
      'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me',
      'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take',
      'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than',
      'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back',
      'after', 'use', 'two', 'how', 'our', 'work', 'first', 'well', 'way', 'even',
      'new', 'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us', 'is',
      'was', 'are', 'been', 'has', 'had', 'were', 'said', 'did', 'having', 'may'
    };
    return commonWords.contains(word);
  }
}
