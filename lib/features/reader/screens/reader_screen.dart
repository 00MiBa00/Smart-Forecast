import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/section_repository.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/models/document_position.dart';
import '../../../data/models/anchor.dart';
import '../../../data/models/card_type.dart';
import '../../../data/models/card_status.dart';
import '../widgets/create_section_sheet.dart';
import '../widgets/card_editor_sheet.dart';

class ReaderScreen extends StatefulWidget {
  final String documentId;

  const ReaderScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final DocumentRepository _documentRepository = DocumentRepository(AppDatabase());
  final SectionRepository _sectionRepository = SectionRepository(AppDatabase());
  final CardRepository _cardRepository = CardRepository(AppDatabase());
  
  Document? _document;
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // Selection state
  String? _selectedText;
  bool _hasTextSelectionSupport = true;
  bool _showNoSelectionBanner = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      // Load document from database
      final document = await _documentRepository.getDocumentById(widget.documentId);
      
      if (document == null) {
        setState(() {
          _errorMessage = 'Document not found';
          _isLoading = false;
        });
        return;
      }

      // Check if file exists or if this is a demo document (no file path)
      final file = File(document.localFilePath);
      final isDemoDocument = document.localFilePath.isEmpty;
      
      if (!isDemoDocument && !await file.exists()) {
        setState(() {
          _document = document;
          _errorMessage = 'File not found';
          _isLoading = false;
        });
        return;
      }

      // For demo documents, skip PDF loading
      if (isDemoDocument) {
        setState(() {
          _document = document;
          _pdfController = null;
          _totalPages = document.pagesCount ?? 1;
          _currentPage = 1;
          _isLoading = false;
          _hasTextSelectionSupport = false;
        });
        await _documentRepository.updateLastOpened(widget.documentId);
        return;
      }

      // Parse last position
      int initialPage = 1;
      if (document.lastPosition != null && document.lastPosition!.isNotEmpty) {
        try {
          final position = DocumentPosition.fromJsonString(document.lastPosition!);
          if (position is PDFPosition) {
            initialPage = position.page;
          }
        } catch (e) {
          // Invalid position, use default page 1
          initialPage = 1;
        }
      }

      // Open PDF
      final pdfDocument = await PdfDocument.openFile(document.localFilePath);
      final controller = PdfController(
        document: Future.value(pdfDocument),
        initialPage: initialPage,
      );

      // Check if PDF has text selection support
      await _checkTextSelectionSupport(pdfDocument, initialPage);

      setState(() {
        _document = document;
        _pdfController = controller;
        _totalPages = pdfDocument.pagesCount;
        _currentPage = initialPage;
        _isLoading = false;
      });

      // Update last opened time
      await _documentRepository.updateLastOpened(widget.documentId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkTextSelectionSupport(PdfDocument document, int page) async {
    // For MVP, we assume text selection is available via copy-paste
    // We'll show the banner only if user reports issues
    // This can be enhanced in future versions with actual text extraction
    setState(() {
      _hasTextSelectionSupport = true;
      _showNoSelectionBanner = false;
    });
  }

  Future<void> _savePosition() async {
    if (_document != null && _pdfController != null) {
      final position = PDFPosition(
        page: _currentPage,
        offset: 0.0,
      );
      await _documentRepository.updateLastPosition(
        widget.documentId,
        position.toJson(),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _handleTextSelection() {
    // For MVP, we'll use a manual text selection flow
    // Show a dialog to paste selected text from clipboard
    _showTextSelectionDialog();
  }

  Future<void> _showTextSelectionDialog() async {
    final controller = TextEditingController();
    
    // Try to get text from clipboard
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        controller.text = clipboardData.text!;
      }
    } catch (e) {
      // Ignore clipboard errors
    }

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Select Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Long-press and copy text from the PDF, then paste it here:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Paste selected text here',
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final text = controller.text.trim();
              controller.dispose();
              Navigator.of(context).pop();
              
              if (text.isNotEmpty) {
                setState(() {
                  _selectedText = text;
                });
              }
            },
            child: const Text('Use Text'),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedText = null;
    });
  }

  void _handleCreateSection() {
    if (_selectedText == null || _selectedText!.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CreateSectionSheet(
        selectedText: _selectedText!,
        onCancel: () {
          Navigator.of(context).pop();
        },
        onSave: ({
          required String title,
          required List<String> tags,
          required int difficulty,
        }) async {
          await _createSection(
            title: title,
            tags: tags,
            difficulty: difficulty,
          );
        },
      ),
    );
  }

  Future<void> _createSection({
    required String title,
    required List<String> tags,
    required int difficulty,
  }) async {
    if (_selectedText == null || _document == null) return;

    try {
      // Truncate text if needed
      String extractedText = _selectedText!.trim();
      if (extractedText.length > 2000) {
        extractedText = extractedText.substring(0, 2000);
      }

      // Generate fallback hash
      final hash = sha1.convert(utf8.encode(extractedText)).toString();

      // Create PDF anchor
      final anchor = PDFAnchor(
        page: _currentPage,
        selectionRects: null, // Not available in MVP
        fallbackHash: hash,
      );

      // Create section
      await _sectionRepository.createSection(
        documentId: _document!.id,
        title: title,
        tags: tags,
        difficulty: difficulty,
        anchorStart: anchor.toJsonString(),
        extractedText: extractedText,
      );

      // Success feedback
      HapticFeedback.mediumImpact();

      // Clear selection
      _clearSelection();

      // Close bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Section created successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Error already handled in the sheet
      rethrow;
    }
  }

  void _handleCreateCard() {
    if (_selectedText == null || _selectedText!.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CardEditorSheet(
        selectedText: _selectedText!,
        onCancel: () {
          Navigator.of(context).pop();
        },
        onSave: ({
          required CardType type,
          required String front,
          required String back,
          required List<String> tags,
          required CardStatus status,
        }) async {
          await _createCard(
            type: type,
            front: front,
            back: back,
            tags: tags,
            status: status,
          );
        },
      ),
    );
  }

  Future<void> _createCard({
    required CardType type,
    required String front,
    required String back,
    required List<String> tags,
    required CardStatus status,
  }) async {
    if (_selectedText == null || _document == null) return;

    try {
      // Truncate source snippet if needed
      String sourceSnippet = _selectedText!.trim();
      if (sourceSnippet.length > 500) {
        sourceSnippet = sourceSnippet.substring(0, 500);
      }

      // Generate fallback hash from FULL text
      final fullText = _selectedText!.trim();
      final hash = sha1.convert(utf8.encode(fullText)).toString();

      // Create PDF anchor
      final anchor = PDFAnchor(
        page: _currentPage,
        selectionRects: null, // Not available in MVP
        fallbackHash: hash,
      );

      // Create card
      await _cardRepository.createCard(
        documentId: _document!.id,
        sectionId: null, // No section linking in MVP
        type: type,
        front: front,
        back: back,
        tags: tags,
        status: status,
        sourceSnippet: sourceSnippet,
        sourceAnchor: anchor.toJsonString(),
      );

      // Success feedback
      HapticFeedback.mediumImpact();

      // Clear selection
      _clearSelection();

      // Close bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Card created successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Error already handled in the sheet
      rethrow;
    }
  }

  @override
  void dispose() {
    _savePosition();
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceColor,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            CupertinoIcons.back,
            color: AppTheme.accentBlue,
          ),
        ),
        middle: Text(
          _document?.title ?? 'Loading...',
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showSearchComingSoon,
              child: const Icon(
                CupertinoIcons.search,
                color: AppTheme.accentBlue,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showDocumentOptions,
              child: const Icon(
                CupertinoIcons.ellipsis,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    // For demo documents, show text content
    if (_pdfController == null && _document != null) {
      return _buildDemoDocumentView();
    }

    if (_pdfController == null) {
      return const Center(
        child: Text(
          'Failed to load PDF',
          style: TextStyle(color: AppTheme.primaryText),
        ),
      );
    }

    return Column(
      children: [
        // Warning banner for PDFs without text selection
        if (_showNoSelectionBanner) _buildNoSelectionBanner(),
        
        Expanded(
          child: PdfView(
            controller: _pdfController!,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
          ),
        ),
        
        // Bottom toolbar
        _buildBottomToolbar(),
      ],
    );
  }

  Widget _buildNoSelectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.accentOrange.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            size: 16,
            color: AppTheme.accentOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Text selection is not available for this PDF.',
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 13,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              setState(() {
                _showNoSelectionBanner = false;
              });
            },
            child: Icon(
              CupertinoIcons.xmark,
              size: 16,
              color: AppTheme.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: AppTheme.accentRed,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage == 'File not found'
                  ? 'File not found'
                  : 'Error',
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage == 'File not found'
                  ? 'The original PDF file is missing.'
                  : _errorMessage ?? 'An unknown error occurred',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_errorMessage == 'File not found')
              CupertinoButton.filled(
                onPressed: _showReplaceFileDialog,
                child: const Text('Replace file'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    // Don't show toolbar for demo documents
    if (_pdfController == null) {
      return const SizedBox.shrink();
    }
    
    final hasSelection = _selectedText != null && _selectedText!.isNotEmpty;
    final canCreateSection = hasSelection && _hasTextSelectionSupport;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.separator,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection status
            if (hasSelection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedText!.length} characters',
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: _clearSelection,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Page indicator
                  Expanded(
                    child: Text(
                      'Page $_currentPage / $_totalPages',
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  // Select Text button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _hasTextSelectionSupport ? _handleTextSelection : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.text_cursor,
                          size: 18,
                          color: _hasTextSelectionSupport 
                              ? AppTheme.primaryText 
                              : AppTheme.tertiaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Select',
                          style: TextStyle(
                            color: _hasTextSelectionSupport 
                                ? AppTheme.primaryText 
                                : AppTheme.tertiaryText,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Create Section button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: canCreateSection ? AppTheme.accentBlue : AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: canCreateSection ? _handleCreateSection : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.rectangle_stack,
                          size: 16,
                          color: canCreateSection ? CupertinoColors.white : AppTheme.tertiaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Section',
                          style: TextStyle(
                            color: canCreateSection ? CupertinoColors.white : AppTheme.tertiaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Create Card button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: canCreateSection ? AppTheme.accentGreen : AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: canCreateSection ? _handleCreateCard : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.square_on_square,
                          size: 16,
                          color: canCreateSection ? CupertinoColors.white : AppTheme.tertiaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Card',
                          style: TextStyle(
                            color: canCreateSection ? CupertinoColors.white : AppTheme.tertiaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchComingSoon() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Search'),
        content: const Text('In-document search will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(_document?.title ?? 'Document Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showDocumentInfo();
            },
            child: const Text('Document info'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showExportOptions();
            },
            child: const Text('Export'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDocumentInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Document Info'),
        content: Text(
          'Title: ${_document?.title ?? 'Unknown'}\\n'
          'Pages: $_totalPages\\n'
          'Current page: $_currentPage',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export'),
        content: const Text('Export functionality will be available in a future update.\\n\\nYou will be able to export your cards and sections.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showReplaceFileDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Replace File'),
        content: const Text('File replacement will be available in a future update.\\n\\nYou will be able to update the PDF file path if it has been moved.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDocumentView() {
    return FutureBuilder<List<Section>>(
      future: _sectionRepository.getSectionsByDocumentId(widget.documentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final sections = snapshot.data!;

        if (sections.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.doc_text,
                    size: 64,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _document?.title ?? 'Demo Document',
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This is a demo document. Import your own PDFs from the Library tab!',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (section.difficulty > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Level ${section.difficulty}',
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    section.extractedText,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
