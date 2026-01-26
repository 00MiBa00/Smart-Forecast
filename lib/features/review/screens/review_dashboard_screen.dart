import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/models/study_scope.dart';
import '../../../data/repositories/srs_repository.dart';
import 'study_session_screen.dart';

class ReviewDashboardScreen extends StatefulWidget {
  const ReviewDashboardScreen({super.key});

  @override
  State<ReviewDashboardScreen> createState() => _ReviewDashboardScreenState();
}

class _ReviewDashboardScreenState extends State<ReviewDashboardScreen> {
  final SRSRepository _srsRepository = SRSRepository(AppDatabase());

  int _dueCount = 0;
  bool _isLoading = true;
  
  // Settings
  int _dailyMaxReviews = 200;
  int _newCardsPerDay = 20;

  @override
  void initState() {
    super.initState();
    _loadDueCount();
  }

  Future<void> _loadDueCount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _srsRepository.getDueCardsCount();
      setState(() {
        _dueCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dueCount = 0;
        _isLoading = false;
      });
    }
  }

  void _startReview() {
    if (_dueCount == 0) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const StudySessionScreen(
          scope: StudyScope.all,
        ),
      ),
    ).then((_) {
      // Reload due count after returning from session
      _loadDueCount();
    });
  }

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
        middle: Text('Review', style: AppTheme.title2.copyWith(color: textColor)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showReviewSettings,
          child: const Icon(
            CupertinoIcons.ellipsis_circle,
            color: AppTheme.accentBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // Due cards count
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  const Text(
                    'Cards due today',
                    style: AppTheme.subheadline,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  _isLoading
                      ? const CupertinoActivityIndicator()
                      : Text(
                          _dueCount.toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                  const SizedBox(height: AppTheme.spacing16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: _dueCount > 0 ? AppTheme.accentBlue : AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onPressed: _dueCount > 0 ? _startReview : null,
                      child: Text(
                        _dueCount > 0 ? 'Start Review' : 'All done for today!',
                        style: TextStyle(
                          color: _dueCount > 0 ? CupertinoColors.white : AppTheme.tertiaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Settings
            const Text('Study Settings', style: AppTheme.headline),
            const SizedBox(height: AppTheme.spacing12),
            
            _buildSettingRow(
              'Daily max reviews',
              _dailyMaxReviews.toString(),
              _showDailyMaxReviewsPicker,
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            _buildSettingRow(
              'New cards per day',
              _newCardsPerDay.toString(),
              _showNewCardsPerDayPicker,
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Breakdown by document
            const Text('By Document', style: AppTheme.headline),
            const SizedBox(height: AppTheme.spacing12),
            
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Text(
                  'No documents yet',
                  style: AppTheme.subheadline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.body.copyWith(color: AppTheme.secondaryText),
                ),
                const SizedBox(width: AppTheme.spacing8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: AppTheme.iconSmall,
                  color: AppTheme.secondaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Review Settings'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showDailyMaxReviewsPicker();
            },
            child: const Text('Daily max reviews'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showNewCardsPerDayPicker();
            },
            child: const Text('New cards per day'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showNotificationSettings();
            },
            child: const Text('Notification settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDailyMaxReviewsPicker() {
    int selectedValue = _dailyMaxReviews;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppTheme.surfaceColor,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text('Daily Max Reviews', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _dailyMaxReviews = selectedValue;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: [50, 100, 150, 200, 250, 300, 500, 1000]
                      .indexOf(_dailyMaxReviews)
                      .clamp(0, 7),
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  selectedValue = [50, 100, 150, 200, 250, 300, 500, 1000][index];
                },
                children: [50, 100, 150, 200, 250, 300, 500, 1000]
                    .map((value) => Center(child: Text('$value cards')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCardsPerDayPicker() {
    int selectedValue = _newCardsPerDay;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppTheme.surfaceColor,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text('New Cards Per Day', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _newCardsPerDay = selectedValue;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: [5, 10, 15, 20, 25, 30, 40, 50]
                      .indexOf(_newCardsPerDay)
                      .clamp(0, 7),
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  selectedValue = [5, 10, 15, 20, 25, 30, 40, 50][index];
                },
                children: [5, 10, 15, 20, 25, 30, 40, 50]
                    .map((value) => Center(child: Text('$value cards')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Daily reminder notifications will be available in a future update.'),
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
