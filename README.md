# DocTrainer - Documentation Reading Trainer

An iOS app built with Flutter that helps developers learn from PDF and Markdown documentation using flashcards and spaced repetition (SRS).

## Features

### Core Features (MVP)
- ✅ **Import Documents**: Import PDF and Markdown files from the iOS Files app
- ✅ **Document Reader**: 
  - PDF view with page navigation
  - Markdown view with headings outline
  - Text selection for creating sections and cards
- ✅ **Sections Management**: Create and organize document sections
- ✅ **Flashcards**:
  - Manual card creation (Q&A, Cloze, True/False)
  - Template-assisted generation (non-AI)
  - Source anchors to jump back to document context
- ✅ **Spaced Repetition**: SM-2 algorithm for optimal review scheduling
- ✅ **Study Sessions**: Review cards with grading (Again/Hard/Good/Easy)
- ✅ **Search**: Full-text search across documents, sections, and cards
- ✅ **Settings**: Configure daily limits and notification preferences
- ✅ **Offline-first**: All data stored locally

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **Drift**: SQLite database with type-safe queries
- **Provider**: State management
- **flutter_markdown**: Markdown rendering
- **file_picker**: Import documents from Files app
- **flutter_local_notifications**: Review reminders
- **iOS PDFKit**: PDF viewing and text selection (platform channel)

## Project Structure

```
lib/
├── app/                    # App entry point and navigation
├── core/
│   ├── services/          # SRS algorithm, template generation
│   ├── theme/             # App theme and colors
│   └── utils/             # Constants and utilities
├── data/
│   ├── database/          # Drift database and tables
│   ├── models/            # Data models and enums
│   └── repositories/      # Data access layer
├── features/
│   ├── library/           # Document library screens
│   ├── reader/            # PDF/Markdown reader
│   ├── review/            # Study session screens
│   ├── create/            # Card/section creation
│   └── settings/          # Settings screen
└── shared/
    └── widgets/           # Reusable widgets
```

## Database Schema

### Tables
1. **Documents**: Stores imported PDF/Markdown files
2. **Sections**: Document sections with anchors
3. **Cards**: Flashcards with Q&A, cloze, or true/false format
4. **SRSRecords**: Spaced repetition scheduling data
5. **StudySessions**: Study session history and statistics

## Getting Started

### Prerequisites
- Flutter SDK (3.10.7+)
- Xcode (for iOS development)
- iOS 16+ device or simulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd doc_trainer
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate database code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## Development

### Generating Database Code

After modifying Drift tables, regenerate the database code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running Tests

```bash
flutter test
```

## SRS Algorithm

The app uses a simplified SM-2 algorithm:

- **Again**: Reset interval, decrease ease factor, increment lapses
- **Hard**: Increase interval by 1.2x, slightly decrease ease factor
- **Good**: Multiply interval by ease factor (or set to 1 day if new)
- **Easy**: Multiply interval by ease factor × 1.3, increase ease factor

Initial values:
- Ease Factor: 2.5
- Interval: 0 days
- Due: Now

## Template-Assisted Card Generation

The app analyzes selected text and generates 3-7 draft cards based on patterns:

- **Definition cards**: Detects "is", "are", "means", "defined as"
- **Use-case cards**: Detects "use", "when", "should"
- **List cards**: Detects bullet points or numbered lists
- **Code cards**: Detects code blocks

## Privacy

- No account required
- All data stored locally on device
- No cloud sync or data collection
- Optional local notifications for review reminders

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## Roadmap

Future features (post-MVP):
- Cloud sync via iCloud
- OCR for scanned PDFs
- Export/import study data
- Advanced statistics and charts
- Multiple themes
- iPad split-view support
