enum DocumentType {
  pdf,
  markdown;

  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.markdown:
        return 'Markdown';
    }
  }
}
