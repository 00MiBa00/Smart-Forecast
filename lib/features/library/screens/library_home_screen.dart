import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/models/document_type.dart';
import '../../../data/repositories/document_repository.dart';
import '../../reader/screens/reader_screen.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class LibraryHomeScreen extends StatefulWidget {
  const LibraryHomeScreen({super.key});

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  String _filterType = 'All';
  String _sortOrder = 'Recently opened';
  final DocumentRepository _documentRepository = DocumentRepository(AppDatabase());
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundColor : CupertinoColors.systemGroupedBackground;
    final surfaceColor = isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground;
    final textColor = isDark ? AppTheme.primaryText : CupertinoColors.black;
    
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: surfaceColor,
        border: null,
        leading: Text(
          'Library',
          style: AppTheme.largeTitle.copyWith(color: textColor),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showImportOptions,
          child: const Icon(
            CupertinoIcons.add_circled,
            color: AppTheme.accentBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: CupertinoSearchTextField(
                placeholder: 'Search documents',
                backgroundColor: surfaceColor,
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
            ),
            
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip('PDF'),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip('Markdown'),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Sort dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sort by:', style: AppTheme.subheadline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showSortOptions,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_sortOrder, style: AppTheme.callout),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: AppTheme.iconSmall,
                          color: AppTheme.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            // Documents list
            Expanded(
              child: _buildDocumentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground;
    final textColor = isDark ? AppTheme.primaryText : CupertinoColors.black;
    final isSelected = _filterType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: AppTheme.callout.copyWith(
            color: isSelected ? CupertinoColors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return StreamBuilder<List<Document>>(
      stream: _getDocumentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final documents = snapshot.data!;

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.book,
                  size: 64,
                  color: AppTheme.tertiaryText,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'No documents yet',
                  style: AppTheme.subheadline.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Tap + to import your first document',
                  style: AppTheme.callout.copyWith(
                    color: AppTheme.tertiaryText,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: documents.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing12),
          itemBuilder: (context, index) {
            return _buildDocumentCard(documents[index]);
          },
        );
      },
    );
  }

  Stream<List<Document>> _getDocumentsStream() {
    return AppDatabase().select(AppDatabase().documents).watch();
  }

  Widget _buildDocumentCard(Document doc) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground;
    final secondarySurface = isDark ? AppTheme.secondarySurface : CupertinoColors.secondarySystemBackground;
    
    return GestureDetector(
      onTap: () => _openDocument(doc),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    doc.type == DocumentType.pdf ? CupertinoIcons.doc_fill : CupertinoIcons.doc_text_fill,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: AppTheme.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        doc.type == DocumentType.pdf ? 'PDF' : 'MARKDOWN',
                        style: AppTheme.caption2.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  'Sections ${doc.sectionsCount}',
                  style: AppTheme.subheadline.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Icon(
                  CupertinoIcons.square_stack_3d_up,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  'Cards ${doc.cardsCount}',
                  style: AppTheme.subheadline.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDocument(Document doc) async {
    await _documentRepository.updateLastOpened(doc.id);
    
    if (mounted) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ReaderScreen(
            documentId: doc.id,
          ),
        ),
      );
    }
  }

  void _showImportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Import Document'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _importPDF();
            },
            child: const Text('Import PDF'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog('Markdown');
            },
            child: const Text('Import Markdown'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _importPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // Show loading
        if (mounted) {
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
          );
        }

        // Create document record
        final now = DateTime.now();
        final docId = _uuid.v4();
        
        await AppDatabase().into(AppDatabase().documents).insert(
          DocumentsCompanion(
            id: drift.Value(docId),
            title: drift.Value(fileName.replaceAll('.pdf', '')),
            type: const drift.Value(DocumentType.pdf),
            localFilePath: drift.Value(file.path),
            sectionsCount: const drift.Value(0),
            cardsCount: const drift.Value(0),
            lastPosition: const drift.Value('{}'),
            lastOpenedAt: drift.Value(now),
            importedAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        if (mounted) {
          // Close loading
          Navigator.of(context).pop();
          
          // Show success
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Success'),
              content: const Text('Document imported successfully'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading if showing
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to import document: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature import will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sort by'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _sortOrder = 'Recently opened';
              });
              Navigator.pop(context);
            },
            child: const Text('Recently opened'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _sortOrder = 'Most due';
              });
              Navigator.pop(context);
            },
            child: const Text('Most due'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _sortOrder = 'A-Z';
              });
              Navigator.pop(context);
            },
            child: const Text('A-Z'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
