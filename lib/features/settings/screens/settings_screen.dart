import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Brightness brightness;

  const SettingsScreen({
    super.key,
    required this.onThemeToggle,
    required this.brightness,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  int _dailyReviewsLimit = 200;
  int _newCardsPerDay = 20;
  int _reminderHour = 9;
  int _reminderMinute = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundColor : CupertinoColors.systemGroupedBackground;
    final surfaceColor = isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground;
    final textColor = isDark ? AppTheme.primaryText : CupertinoColors.black;
    final secondaryTextColor = isDark ? AppTheme.secondaryText : CupertinoColors.secondaryLabel;
    
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: surfaceColor,
        border: null,
        middle: Text('Settings', style: AppTheme.title2.copyWith(color: textColor)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // Appearance
            Text('Appearance', style: AppTheme.headline.copyWith(color: textColor)),
            const SizedBox(height: AppTheme.spacing12),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark mode', style: AppTheme.body.copyWith(color: textColor)),
                  CupertinoSwitch(
                    value: widget.brightness == Brightness.dark,
                    onChanged: (value) {
                      widget.onThemeToggle();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Study settings
            Text('Study Settings', style: AppTheme.headline.copyWith(color: textColor)),
            const SizedBox(height: AppTheme.spacing12),
            
            _buildSettingRow(
              'Daily reviews limit',
              _dailyReviewsLimit.toString(),
              _showDailyReviewsLimitPicker,
              surfaceColor,
              textColor,
              secondaryTextColor,
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            _buildSettingRow(
              'New cards per day',
              _newCardsPerDay.toString(),
              _showNewCardsPerDayPicker,
              surfaceColor,
              textColor,
              secondaryTextColor,
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Notifications
            Text('Notifications', style: AppTheme.headline.copyWith(color: textColor)),
            const SizedBox(height: AppTheme.spacing12),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable reminders', style: AppTheme.body.copyWith(color: textColor)),
                  CupertinoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            if (_notificationsEnabled) ...[
              const SizedBox(height: AppTheme.spacing8),
              _buildSettingRow(
                'Reminder time',
                '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                _showReminderTimePicker,
                surfaceColor,
                textColor,
                secondaryTextColor,
              ),
            ],
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Data
            Text('Data', style: AppTheme.headline.copyWith(color: textColor)),
            const SizedBox(height: AppTheme.spacing12),
            
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Clear cache
                _showClearCacheDialog();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Text(
                  'Clear cache',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.accentRed,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // About
            Text('About', style: AppTheme.headline.copyWith(color: textColor)),
            const SizedBox(height: AppTheme.spacing12),
            
            _buildSettingRow(
              'Privacy Policy',
              '',
              _showPrivacyPolicy,
              surfaceColor,
              textColor,
              secondaryTextColor,
              showChevron: true,
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Version', style: AppTheme.body.copyWith(color: textColor)),
                  Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 17,
                      color: secondaryTextColor,
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

  Widget _buildSettingRow(
    String label,
    String value, 
    VoidCallback onTap,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor, {
    bool showChevron = true,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body.copyWith(color: textColor)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: AppTheme.body.copyWith(color: secondaryTextColor),
                  ),
                if (showChevron) ...[
                  const SizedBox(width: AppTheme.spacing8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: AppTheme.iconSmall,
                    color: secondaryTextColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _performClearCache();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDailyReviewsLimitPicker() {
    int selectedValue = _dailyReviewsLimit;
    
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
                  const Text('Daily Reviews Limit', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _dailyReviewsLimit = selectedValue;
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
                      .indexOf(_dailyReviewsLimit)
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

  void _showReminderTimePicker() {
    int selectedHour = _reminderHour;
    int selectedMinute = _reminderMinute;
    
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
                  const Text('Reminder Time', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _reminderHour = selectedHour;
                        _reminderMinute = selectedMinute;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2024, 1, 1, _reminderHour, _reminderMinute),
                onDateTimeChanged: (DateTime newDateTime) {
                  selectedHour = newDateTime.hour;
                  selectedMinute = newDateTime.minute;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            backgroundColor: AppTheme.surfaceColor,
            middle: Text('Privacy Policy', style: AppTheme.title2),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: const [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Effective Date: January 2026',
                  style: AppTheme.subheadline,
                ),
                SizedBox(height: 24),
                Text(
                  'Data Collection',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'DocTrainer stores all data locally on your device. We do not collect, transmit, or store any personal information on external servers. Your PDF documents, study cards, and learning progress remain entirely on your device.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Data Storage',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'All application data is stored in a local SQLite database on your device. PDF files are stored in your device\'s local file system. No data synchronization or cloud backup is performed by default.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Permissions',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'DocTrainer requests the following permissions:\n\n• File System Access: To import and read PDF documents\n• Notifications (optional): To send study reminders\n\nAll permissions are used solely for the stated purposes and no data is transmitted externally.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Third-Party Services',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'DocTrainer does not integrate with any third-party analytics, advertising, or tracking services. The app functions entirely offline.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Data Security',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'Since all data is stored locally, it is protected by your device\'s security features (passcode, biometric authentication, encryption). We recommend keeping your device secure with a strong passcode.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Changes to This Policy',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'We may update this Privacy Policy from time to time. Any changes will be reflected in the app and on our website at doctrainer.app/privacy.',
                  style: AppTheme.body,
                ),
                SizedBox(height: 24),
                Text(
                  'Contact',
                  style: AppTheme.headline,
                ),
                SizedBox(height: 12),
                Text(
                  'For questions about this Privacy Policy, please contact us at privacy@doctrainer.app',
                  style: AppTheme.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performClearCache() async {
    // Show activity indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );
    
    // Simulate cache clearing
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Close loading
    Navigator.pop(context);
    
    // Show success
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cache Cleared'),
        content: const Text('All cached data has been cleared successfully.'),
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
