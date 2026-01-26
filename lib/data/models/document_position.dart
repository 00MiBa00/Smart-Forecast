import 'dart:convert';

abstract class DocumentPosition {
  const DocumentPosition();

  Map<String, dynamic> toJson();
  
  factory DocumentPosition.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'pdf':
        return PDFPosition.fromJson(json);
      case 'markdown':
        return MarkdownPosition.fromJson(json);
      default:
        throw ArgumentError('Unknown position type: $type');
    }
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory DocumentPosition.fromJsonString(String jsonString) {
    return DocumentPosition.fromJson(jsonDecode(jsonString));
  }
}

class PDFPosition extends DocumentPosition {
  final int page;
  final double? offset;

  const PDFPosition({
    required this.page,
    this.offset,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'pdf',
      'page': page,
      'offset': offset,
    };
  }

  factory PDFPosition.fromJson(Map<String, dynamic> json) {
    return PDFPosition(
      page: json['page'] as int,
      offset: json['offset'] as double?,
    );
  }
}

class MarkdownPosition extends DocumentPosition {
  final String? headingId;
  final double? scrollOffset;

  const MarkdownPosition({
    this.headingId,
    this.scrollOffset,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'markdown',
      'headingId': headingId,
      'scrollOffset': scrollOffset,
    };
  }

  factory MarkdownPosition.fromJson(Map<String, dynamic> json) {
    return MarkdownPosition(
      headingId: json['headingId'] as String?,
      scrollOffset: json['scrollOffset'] as double?,
    );
  }
}
