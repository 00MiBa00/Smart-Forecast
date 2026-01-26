class AppConstants {
  // SRS defaults
  static const double defaultEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const int defaultDailyNewCards = 20;
  static const int defaultDailyReviewLimit = 200;
  
  // Study session
  static const Duration againInterval = Duration(minutes: 10);
  
  // Notifications
  static const int notificationId = 1;
  static const String notificationChannelId = 'doc_trainer_reviews';
  static const String notificationChannelName = 'Review Reminders';
  
  // File limits
  static const int maxFileSizeMB = 100;
  
  // Search
  static const int searchResultsLimit = 50;
  
  // Template generation
  static const int minDraftCards = 3;
  static const int maxDraftCards = 7;
  
  // Storage keys
  static const String keyDailyNewCards = 'daily_new_cards';
  static const String keyDailyReviewLimit = 'daily_review_limit';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyNotificationTime = 'notification_time';
}
