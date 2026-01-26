import 'dart:convert';
import 'dart:ui';

abstract class Anchor {
  const Anchor();

  Map<String, dynamic> toJson();
  
  factory Anchor.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'pdf':
        return PDFAnchor.fromJson(json);
      case 'markdown':
        return MarkdownAnchor.fromJson(json);
      default:
        throw ArgumentError('Unknown anchor type: $type');
    }
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory Anchor.fromJsonString(String jsonString) {
    return Anchor.fromJson(jsonDecode(jsonString));
  }
}

class PDFAnchor extends Anchor {
  final int page;
  final List<Rect>? selectionRects;
  final String fallbackHash;

  const PDFAnchor({
    required this.page,
    this.selectionRects,
    required this.fallbackHash,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'pdf',
      'page': page,
      'selectionRects': selectionRects
          ?.map((r) => {
                'left': r.left,
                'top': r.top,
                'right': r.right,
                'bottom': r.bottom,
              })
          .toList(),
      'fallbackHash': fallbackHash,
    };
  }

  factory PDFAnchor.fromJson(Map<String, dynamic> json) {
    return PDFAnchor(
      page: json['page'] as int,
      selectionRects: (json['selectionRects'] as List<dynamic>?)?.map((r) {
        final rectMap = r as Map<String, dynamic>;
        return Rect.fromLTRB(
          rectMap['left'] as double,
          rectMap['top'] as double,
          rectMap['right'] as double,
          rectMap['bottom'] as double,
        );
      }).toList(),
      fallbackHash: json['fallbackHash'] as String,
    );
  }
}

class MarkdownAnchor extends Anchor {
  final String? headingId;
  final int? startOffset;
  final int? endOffset;

  const MarkdownAnchor({
    this.headingId,
    this.startOffset,
    this.endOffset,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'markdown',
      'headingId': headingId,
      'startOffset': startOffset,
      'endOffset': endOffset,
    };
  }

  factory MarkdownAnchor.fromJson(Map<String, dynamic> json) {
    return MarkdownAnchor(
      headingId: json['headingId'] as String?,
      startOffset: json['startOffset'] as int?,
      endOffset: json['endOffset'] as int?,
    );
  }
}
