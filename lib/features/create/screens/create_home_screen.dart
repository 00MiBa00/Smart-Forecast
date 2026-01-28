import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/models/card_type.dart';
import '../../../data/models/card_status.dart';
import '../../../data/repositories/section_repository.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../core/services/card_generation_service.dart';
import '../../../core/services/demo_seeder.dart';
import 'generated_cards_review_screen.dart';

class CreateHomeScreen extends StatefulWidget {
  const CreateHomeScreen({super.key});

  @override
  State<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends State<CreateHomeScreen> {
  int _selectedSegment = 0;
  final SectionRepository _sectionRepository = SectionRepository(AppDatabase());
  final CardRepository _cardRepository = CardRepository(AppDatabase());
  final DocumentRepository _documentRepository = DocumentRepository(AppDatabase());
  final CardGenerationService _generationService = CardGenerationService();
  
  // Filter state
  String? _selectedDocumentId;
  String? _selectedDocumentTitle;
  CardStatus? _selectedStatus;
  String _searchQuery = '';

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
        middle: Text('Create', style: AppTheme.title2.copyWith(color: textColor)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showSearchDialog,
              child: const Icon(
                CupertinoIcons.search,
                color: AppTheme.accentBlue,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showCreateCardDialog,
              child: const Icon(
                CupertinoIcons.add_circled,
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Segmented control
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: surfaceColor,
                thumbColor: AppTheme.accentBlue,
                groupValue: _selectedSegment,
                onValueChanged: (value) {
                  setState(() {
                    _selectedSegment = value ?? 0;
                  });
                },
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Text('Cards'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Text('Sections'),
                  ),
                },
              ),
            ),
            
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showDocumentPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDocumentTitle ?? 'All documents',
                                style: AppTheme.callout,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: AppTheme.iconSmall,
                              color: AppTheme.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showStatusFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        CupertinoIcons.line_horizontal_3_decrease,
                        size: AppTheme.iconMedium,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // List
            Expanded(
              child: _selectedSegment == 0
                  ? _buildCardsList()
                  : _buildSectionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList() {
    return StreamBuilder<List<Card>>(
      stream: _cardRepository.watchAllCards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        var cards = snapshot.data!;
        
        // Apply filters
        if (_selectedDocumentId != null) {
          cards = cards.where((card) => card.documentId == _selectedDocumentId).toList();
        }
        
        if (_selectedStatus != null) {
          cards = cards.where((card) => card.status == _selectedStatus).toList();
        }
        
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          cards = cards.where((card) {
            final front = card.front.toLowerCase();
            final back = card.back.toLowerCase();
            return front.contains(query) || back.contains(query);
          }).toList();
        }

        if (cards.isEmpty) {
          // Different empty states based on filters
          if (_searchQuery.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing32),
                child: Text(
                  'No cards found for "$_searchQuery"',
                  style: AppTheme.subheadline,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          // No cards at all - show strong CTAs
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.square_stack_3d_up,
                    size: 64,
                    color: AppTheme.tertiaryText,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  const Text(
                    'No cards yet',
                    style: AppTheme.title2,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Create flashcards from your reading to start learning',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onPressed: _tryDemo,
                      child: const Text(
                        'Try Demo',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onPressed: _showCreateCardDialog,
                      child: Text(
                        'Create Card',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryText
                              : CupertinoColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: cards.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing12),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildCardItem(card);
          },
        );
      },
    );
  }

  Widget _buildCardItem(Card card) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  _getCardTypeLabel(card.type),
                  style: AppTheme.caption1.copyWith(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: card.status == CardStatus.active
                      ? AppTheme.accentGreen.withValues(alpha: 0.2)
                      : AppTheme.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  card.status == CardStatus.active ? 'Active' : 'Draft',
                  style: AppTheme.caption1.copyWith(
                    color: card.status == CardStatus.active
                        ? AppTheme.accentGreen
                        : AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // Front text
          Text(
            card.front,
            style: AppTheme.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getCardTypeLabel(CardType type) {
    switch (type) {
      case CardType.qa:
        return 'Q&A';
      case CardType.cloze:
        return 'Cloze';
      case CardType.trueFalse:
        return 'True/False';
    }
  }

  Widget _buildSectionsList() {
    return StreamBuilder<List<Section>>(
      stream: _getSectionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        var sections = snapshot.data!;
        
        // Apply filters
        if (_selectedDocumentId != null) {
          sections = sections.where((section) => section.documentId == _selectedDocumentId).toList();
        }
        
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          sections = sections.where((section) {
            final title = section.title.toLowerCase();
            final content = section.extractedText.toLowerCase();
            return title.contains(query) || content.contains(query);
          }).toList();
        }

        if (sections.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty 
                  ? 'No sections found for "$_searchQuery"'
                  : 'No sections yet',
              style: AppTheme.subheadline,
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: sections.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing12),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionItem(section);
          },
        );
      },
    );
  }

  Stream<List<Section>> _getSectionsStream() {
    // For now, get all sections from all documents
    // TODO: Filter by selected document when filter is implemented
    return _sectionRepository.watchAllSections();
  }

  Widget _buildSectionItem(Section section) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and difficulty
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: AppTheme.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (section.difficulty > 0) ...[
                const SizedBox(width: AppTheme.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                  color: _getDifficultyColor(section.difficulty).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    _getDifficultyLabel(section.difficulty),
                    style: AppTheme.caption1.copyWith(
                      color: _getDifficultyColor(section.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          // Preview text
          Text(
            section.extractedText,
            style: AppTheme.callout.copyWith(color: AppTheme.secondaryText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Tags
          if (section.tags.isNotEmpty) ...[
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: _parseTags(section.tags).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    tag,
                    style: AppTheme.caption2.copyWith(color: AppTheme.secondaryText),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          
          // Generate Cards button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              onPressed: () => _handleGenerateCards(section),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(CupertinoIcons.sparkles, size: 20),
                  SizedBox(width: AppTheme.spacing8),
                  Text('Generate Cards'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final List<dynamic> tagsList = jsonDecode(tagsJson);
      return tagsList.map((t) => t.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppTheme.accentGreen;
      case 2:
        return AppTheme.accentOrange;
      case 3:
        return AppTheme.accentRed;
      default:
        return AppTheme.secondaryText;
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return '';
    }
  }

  Future<void> _handleGenerateCards(Section section) async {
    // Show loading overlay
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );

    try {
      // Generate cards
      final generatedCards = _generationService.generateCardsFromSection(
        documentId: section.documentId,
        sectionId: section.id,
        sectionTitle: section.title,
        extractedText: section.extractedText,
        anchorStart: section.anchorStart,
      );

      // Close loading overlay
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Check if cards were generated
      if (generatedCards.isEmpty) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('No Cards Generated'),
              content: Text(
                section.extractedText.length < 20
                    ? 'Section is too short to generate cards.'
                    : 'Could not generate cards for this section.',
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
        return;
      }

      // Navigate to review screen
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          CupertinoPageRoute(
            builder: (context) => GeneratedCardsReviewScreen(
              generatedCards: generatedCards,
            ),
          ),
        );

        // Show success message if cards were saved
        if (result == true && mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Success'),
              content: const Text('Generated cards have been saved.'),
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
      // Close loading overlay if still showing
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to generate cards. Please try again.'),
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

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Search'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Search cards or sections...',
            autofocus: true,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
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
            child: const Text('Search'),
            onPressed: () {
              setState(() {
                _searchQuery = controller.text.trim();
              });
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateCardDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create Card'),
        content: const Text('To create cards:\n1. Go to Library\n2. Open a document\n3. Create a section\n4. Generate cards from the section'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _tryDemo() async {
    try {
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

      // Create/get demo
      final demoSeeder = DemoSeeder(AppDatabase());
      await demoSeeder.ensureDemoExists();

      if (mounted) {
        // Close loading
        Navigator.of(context).pop();

        // Show success message - user can then switch to Library tab manually
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Demo Ready'),
            content: const Text('Demo document has been created! Switch to the Library tab to view it.'),
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
      if (mounted) {
        // Close loading if showing
        Navigator.of(context).popUntil((route) => route.isFirst);

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load demo: ${e.toString()}'),
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

  Future<void> _showDocumentPicker() async {
    final documents = await _documentRepository.getAllDocuments();
    
    if (!mounted) return;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter by Document'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedDocumentId = null;
                _selectedDocumentTitle = null;
              });
              Navigator.pop(context);
            },
            child: const Text('All documents'),
          ),
          ...documents.map((doc) => CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedDocumentId = doc.id;
                _selectedDocumentTitle = doc.title;
              });
              Navigator.pop(context);
            },
            child: Text(doc.title),
          )),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter by Status'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
              });
              Navigator.pop(context);
            },
            child: const Text('All Cards'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedStatus = CardStatus.active;
              });
              Navigator.pop(context);
            },
            child: const Text('Active Only'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedStatus = CardStatus.draft;
              });
              Navigator.pop(context);
            },
            child: const Text('Draft Only'),
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
