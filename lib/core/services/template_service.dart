import '../../data/models/card_type.dart';
import '../utils/constants.dart';

class CardTemplate {
  final String front;
  final String back;
  final CardType type;

  CardTemplate({
    required this.front,
    required this.back,
    required this.type,
  });
}

class TemplateService {
  /// Generate draft cards from extracted text
  static List<CardTemplate> generateDraftCards({
    required String extractedText,
    int? maxCards,
  }) {
    final cards = <CardTemplate>[];
    final limit = (maxCards ?? AppConstants.maxDraftCards).clamp(
      AppConstants.minDraftCards,
      AppConstants.maxDraftCards,
    );

    // Normalize text
    final text = extractedText.trim();
    if (text.isEmpty) return cards;

    // Check for definition patterns
    if (_hasDefinitionPattern(text)) {
      cards.addAll(_generateDefinitionCards(text));
    }

    // Check for use-case patterns
    if (_hasUseCasePattern(text)) {
      cards.addAll(_generateUseCaseCards(text));
    }

    // Check for list/bullet patterns
    if (_hasListPattern(text)) {
      cards.addAll(_generateListCards(text));
    }

    // Check for code blocks
    if (_hasCodeBlock(text)) {
      cards.addAll(_generateCodeCards(text));
    }

    // If no specific patterns found, generate generic Q&A
    if (cards.isEmpty) {
      cards.addAll(_generateGenericCards(text));
    }

    // Limit the number of cards
    return cards.take(limit).toList();
  }

  static bool _hasDefinitionPattern(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains(RegExp(r'\b(is|are|means?|defined as|refers? to)\b'));
  }

  static bool _hasUseCasePattern(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains(RegExp(r'\b(use|uses|when|should|can|allows?|enables?)\b'));
  }

  static bool _hasListPattern(String text) {
    return text.contains(RegExp(r'^\s*[-*•]\s+', multiLine: true)) ||
           text.contains(RegExp(r'^\s*\d+\.\s+', multiLine: true));
  }

  static bool _hasCodeBlock(String text) {
    return text.contains('```') || 
           text.contains(RegExp(r'^\s{4,}', multiLine: true));
  }

  static List<CardTemplate> _generateDefinitionCards(String text) {
    final cards = <CardTemplate>[];
    
    // Extract key terms
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;
      
      final match = RegExp(
        r'(\w+(?:\s+\w+)?)\s+(is|are|means?|defined as)',
        caseSensitive: false,
      ).firstMatch(sentence);
      
      if (match != null) {
        final term = match.group(1)!;
        cards.add(CardTemplate(
          front: 'What is $term?',
          back: sentence.trim(),
          type: CardType.qa,
        ));
      }
    }
    
    return cards;
  }

  static List<CardTemplate> _generateUseCaseCards(String text) {
    final cards = <CardTemplate>[];
    
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty || sentence.length < 20) continue;
      
      if (RegExp(r'\b(use|when|should)\b', caseSensitive: false).hasMatch(sentence)) {
        cards.add(CardTemplate(
          front: 'When would you use this?',
          back: sentence.trim(),
          type: CardType.qa,
        ));
      }
    }
    
    return cards;
  }

  static List<CardTemplate> _generateListCards(String text) {
    final cards = <CardTemplate>[];
    
    // Extract lists
    final lines = text.split('\n');
    final listItems = <String>[];
    String? listContext;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (listItems.length >= 2) {
          // Found a complete list
          cards.add(CardTemplate(
            front: 'List the ${listContext ?? "items"}:',
            back: listItems.join('\n'),
            type: CardType.qa,
          ));
          listItems.clear();
          listContext = null;
        }
        continue;
      }
      
      if (RegExp(r'^[-*•]\s+|^\d+\.\s+').hasMatch(line)) {
        if (listItems.isEmpty && i > 0) {
          // Previous line might be context
          listContext = lines[i - 1].trim();
        }
        listItems.add(line);
      }
    }
    
    // Add remaining list
    if (listItems.length >= 2) {
      cards.add(CardTemplate(
        front: 'List the ${listContext ?? "items"}:',
        back: listItems.join('\n'),
        type: CardType.qa,
      ));
    }
    
    return cards;
  }

  static List<CardTemplate> _generateCodeCards(String text) {
    final cards = <CardTemplate>[];
    
    // Extract code blocks
    final codeBlockPattern = RegExp(r'```[\w]*\n(.*?)```', dotAll: true);
    final matches = codeBlockPattern.allMatches(text);
    
    for (final match in matches) {
      final code = match.group(1)?.trim();
      if (code != null && code.isNotEmpty) {
        cards.add(CardTemplate(
          front: 'What does this code do?\n\n```\n$code\n```',
          back: 'Explain the purpose and functionality of this code.',
          type: CardType.qa,
        ));
      }
    }
    
    return cards;
  }

  static List<CardTemplate> _generateGenericCards(String text) {
    final cards = <CardTemplate>[];
    
    // Create a basic Q&A from the text
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    if (sentences.isNotEmpty) {
      final firstSentence = sentences.first.trim();
      if (firstSentence.isNotEmpty) {
        cards.add(CardTemplate(
          front: 'What is important about this concept?',
          back: text.trim(),
          type: CardType.qa,
        ));
      }
    }
    
    // Create a cloze deletion if text is suitable
    if (text.length > 30 && text.length < 500) {
      final words = text.split(RegExp(r'\s+'));
      if (words.length > 5) {
        // Replace a key word with [...]
        final middleIndex = words.length ~/ 2;
        final clozeText = words
            .asMap()
            .entries
            .map((e) => e.key == middleIndex ? '[...]' : e.value)
            .join(' ');
        
        cards.add(CardTemplate(
          front: clozeText,
          back: words[middleIndex],
          type: CardType.cloze,
        ));
      }
    }
    
    return cards;
  }
}
