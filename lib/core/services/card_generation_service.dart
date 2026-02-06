import '../../data/models/card_type.dart';

/// Simple data class to hold generated card information
class GeneratedCard {
  final String id;
  final String documentId;
  final String? sectionId;
  final String front;
  final String back;
  final CardType type;
  final String? sourceSnippet;
  final String? sourceAnchor;

  GeneratedCard({
    required this.id,
    required this.documentId,
    this.sectionId,
    required this.front,
    required this.back,
    required this.type,
    this.sourceSnippet,
    this.sourceAnchor,
  });
}

/// Service for generating flashcards from text sections
class CardGenerationService {
  /// Generate cards from a text section
  /// This is a simple implementation - in production, you might use AI/ML
  List<GeneratedCard> generateCardsFromSection({
    required String documentId,
    required String sectionId,
    required String sectionTitle,
    required String extractedText,
    dynamic anchorStart,
  }) {
    final cards = <GeneratedCard>[];
    int cardCounter = 0;
    
    // Simple heuristic: split by sentences and create Q&A pairs
    final sentences = extractedText.split(RegExp(r'[.!?]+'));
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      
      if (sentence.isEmpty || sentence.length < 20) continue;
      
      // Simple card generation: first part as question, rest as answer
      final words = sentence.split(' ');
      if (words.length > 5) {
        final front = 'What is ${words.sublist(0, 3).join(' ')}?';
        final back = sentence;
        
        cardCounter++;
        cards.add(GeneratedCard(
          id: '${sectionId}_gen_$cardCounter',
          documentId: documentId,
          sectionId: sectionId,
          front: front,
          back: back,
          type: CardType.qa,
          sourceSnippet: sentence,
          sourceAnchor: anchorStart?.toJsonString(),
        ));
      }
      
      // Limit to reasonable number of cards
      if (cards.length >= 10) break;
    }
    
    return cards;
  }

  /// Generate cards from multiple sections
  List<GeneratedCard> generateCardsFromSections(List<String> sections) {
    // This method would need to be updated if used
    return [];
  }
}
