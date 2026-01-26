## PDF Reader - Usage Guide

### Navigation to ReaderScreen

To open a document in the PDF reader, navigate using:

```dart
import 'package:flutter/cupertino.dart';
import '../reader/reader.dart';

// Example: Open from library or anywhere else
Navigator.of(context).push(
  CupertinoPageRoute(
    builder: (context) => ReaderScreen(
      documentId: document.id,
    ),
  ),
);
```

---

## Phase 1.1 - PDF Reader MVP ✅

### Features Implemented

✅ **PDF Loading**
- Loads PDF from `Document.localFilePath`
- Validates file existence before opening
- Shows error screen if file is missing

✅ **Page Display**
- Vertical scrolling PDF viewer
- Smooth page transitions
- Responsive layout

✅ **Page Tracking**
- Shows "Page X / Y" indicator in bottom toolbar
- Updates current page as user scrolls
- 1-based page numbering

✅ **Position Save/Restore**
- Saves `lastPosition` JSON on screen exit
- Format: `{"type": "pdf", "page": <int>, "offset": 0.0}`
- Restores to saved page on reopen
- Defaults to page 1 if position is null/invalid

✅ **Error Handling**
- Missing file error screen with "Replace file" button (stub)
- Document not found handling
- PDF loading error handling

---

## Phase 1.2 - Text Selection & Section Creation ✅

### Features Implemented

✅ **Text Selection**
- "Select" button in bottom toolbar
- Manual text selection via copy-paste flow
- Selection status indicator showing character count
- Clear selection button

✅ **Section Creation**
- "Section" button (enabled only when text is selected)
- Cupertino bottom sheet with form:
  - **Title**: Auto-filled from first line of selected text (max 60 chars)
  - **Tags**: Optional comma-separated tags
  - **Difficulty**: Segmented control (Easy/Medium/Hard/Very Hard)
  - **Preview**: First 200 characters of selected text
- Save/Cancel actions

✅ **Section Storage**
- Saves section to database with:
  - `documentId`
  - `title`
  - `tags` (JSON array)
  - `difficulty` (0-3)
  - `extractedText` (trimmed, max 2000 chars)
  - `anchorStart` (PDF anchor JSON)
  - `createdAt`/`updatedAt`

✅ **PDF Anchor Format**
```json
{
  "type": "pdf",
  "page": 5,
  "selectionRects": null,
  "fallbackHash": "a1b2c3d4e5f6..."
}
```

---

## Phase 1.3 - Card Creation from Selection ✅

### Features Implemented

✅ **Card Creation**
- "Card" button in bottom toolbar (enabled when text is selected)
- Green accent color to differentiate from Section button
- Opens CardEditorSheet with comprehensive form

✅ **Card Types Supported**
- **Q&A**: Traditional question and answer format
- **Cloze**: Fill-in-the-blank style cards
- **True/False**: Statement with boolean answer

✅ **Card Editor UI**
- Type selector (segmented control for 3 types)
- Dynamic fields based on card type:
  - **Front**: Question/Sentence/Statement (multiline)
  - **Back**: Answer field (text) or True/False toggle
  - **Tags**: Optional comma-separated tags
  - **Status**: Draft or Active (segmented control)
  - **Source**: Read-only preview (first 200 chars)
- Smart prefilling for True/False type
- Real-time validation with Save button state
- Character count warnings for long text

✅ **Card Storage**
- Saves card to database with:
  - `documentId`
  - `sectionId` (null in MVP)
  - `type` (qa/cloze/trueFalse)
  - `front` (required, trimmed)
  - `back` (required for all types)
  - `tags` (JSON array)
  - `status` (draft/active/suspended)
  - `sourceSnippet` (max 500 chars)
  - `sourceAnchor` (PDF anchor JSON)
  - `createdAt`/`updatedAt`

✅ **Card Source Anchor**
```json
{
  "type": "pdf",
  "page": 5,
  "selectionRects": null,
  "fallbackHash": "abc123..."
}
```
- `fallbackHash`: SHA-1 of full selected text (before truncation)
- `sourceSnippet`: Truncated to 500 chars max

✅ **Validation Rules**
- Front text required (non-empty after trim)
- Back text required for Q&A and Cloze
- True/False back must be "true" or "false"
- Source snippet auto-truncates to 500 chars
- Hash computed from full text before truncation

✅ **User Experience**
- Haptic feedback on successful save
- Success confirmation dialog
- Error handling with friendly messages
- Selection automatically clears after save
- Type switching preserves text where possible

---

### Repository Methods

**DocumentRepository:**
```dart
Future<Document?> getDocumentById(String id)
Future<void> updateLastPosition(String documentId, Map<String, dynamic> json)
Future<void> updateLastOpened(String documentId)
```

**SectionRepository:**
```dart
Future<String> createSection({...})
Future<List<Section>> getSectionsByDocumentId(String documentId)
Stream<List<Section>> watchSectionsByDocumentId(String documentId)
Future<Section?> getSectionById(String id)
Future<void> updateSection(Section section)
Future<void> deleteSection(String id)
```

**CardRepository:**
```dart
Future<String> createCard({...})
Future<List<Card>> getCardsByDocumentId(String documentId)
Stream<List<Card>> watchCardsByDocumentId(String documentId)
Stream<int> watchCardCountByDocumentId(String documentId)
Future<Card?> getCardById(String id)
Future<void> updateCard(Card card)
Future<void> deleteCard(String id)
Future<List<Card>> getAllCards()
Stream<List<Card>> watchAllCards()
```

---

### UI Components

**Navigation Bar:**
- Back button (left)
- Document title (center)
- Search icon - disabled (right)
- Overflow menu (…) - disabled (right)

**Body:**
- Optional warning banner for non-selectable PDFs
- PDF viewer with vertical scrolling
- Full-screen PDF display

**Bottom Toolbar:**
- Page indicator: "Page X / Y"
- "Select" button (opens text selection dialog)
- "Section" button (blue, with stack icon)
- "Card" button (green, with card icon)
- Selection status chip (when text is selected)

**Card Editor Sheet:**
- Handle bar for dragging
- Header with Cancel/Save buttons (Save disabled until valid)
- Type selector (Q&A / Cloze / True/False)
- Front input field (dynamic placeholder based on type)
- Back input field or True/False toggle
- Tags input (optional)
- Status selector (Draft / Active)
- Source preview (read-only)
- Truncation warning for long text

---

### Data Models

**Card** (database model):
- `id`: UUID
- `documentId`: Foreign key to document
- `sectionId`: Nullable (null in MVP)
- `type`: Enum (qa, cloze, trueFalse)
- `front`: Question/statement text
- `back`: Answer text or "true"/"false"
- `tags`: JSON array of strings
- `status`: Enum (draft, active, suspended)
- `sourceSnippet`: Selected text (max 500 chars)
- `sourceAnchor`: JSON string (PDFAnchor)
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**CardType Enum:**
```dart
enum CardType {
  qa,         // Q&A
  cloze,      // Cloze deletion
  trueFalse   // True/False
}
```

**CardStatus Enum:**
```dart
enum CardStatus {
  draft,      // Not yet ready for review
  active,     // Ready for SRS
  suspended   // Temporarily disabled
}
```

---

### User Flows

#### Create Card Flow:

1. User opens PDF in ReaderScreen
2. User taps "Select" button
3. Dialog appears prompting to paste text
4. User copies text from PDF and pastes into dialog
5. User taps "Use Text"
6. Selection indicator appears with character count
7. "Card" button becomes enabled (green)
8. User taps "Card"
9. CardEditorSheet appears
10. User selects card type (Q&A/Cloze/True-False)
11. User fills in front text
12. User fills in back (text or toggle)
13. Optionally adds tags
14. Optionally changes status
15. User taps "Save"
16. Card is saved to database
17. Success haptic and alert dialog
18. Selection is cleared
19. Sheet dismisses

#### Card Type Behaviors:

**Q&A:**
- Front: Question text
- Back: Answer text (multiline input)
- Use case: "What is X?" → "X is..."

**Cloze:**
- Front: Sentence with {{blank}} markers
- Back: Expected answer(s)
- Use case: "The {{capital}} of France" → "Paris"

**True/False:**
- Front: Statement to evaluate
- Back: "true" or "false" (toggle control)
- Auto-prefills front from first line of selection
- Use case: "Python is a compiled language" → false

#### Error Handling:

- **Empty front**: Save disabled, error on attempt
- **Empty back** (Q&A/Cloze): Save disabled
- **Save failure**: Error alert, selection preserved
- **Long text (>500 chars)**: Auto-truncated with warning
- **Missing file**: Error screen
- **Non-selectable PDF**: Banner shown, buttons disabled

---

### Integration Points

**For Create Tab:**

Display all cards with live updates:

```dart
StreamBuilder<List<Card>>(
  stream: _cardRepository.watchAllCards(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CupertinoActivityIndicator();
    
    final cards = snapshot.data!;
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CardListItem(card: card);
      },
    );
  },
)
```

**For DocumentDetail Screen:**

Show card count:

```dart
StreamBuilder<int>(
  stream: _cardRepository.watchCardCountByDocumentId(documentId),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    return Text('$count cards');
  },
)
```

Or watch cards directly:

```dart
StreamBuilder<List<Card>>(
  stream: _cardRepository.watchCardsByDocumentId(documentId),
  builder: (context, snapshot) {
    final cards = snapshot.data ?? [];
    return Text('${cards.length} cards');
  },
)
```

**For Library Screen:**

Cards are automatically counted in `Document.cardsCount` field, which updates when cards are created/deleted.

---

### Out of Scope (Current MVP)

❌ Native text selection overlay
❌ Template generation from selection
❌ Bulk card creation
❌ Card-to-section auto-linking
❌ SRS study session integration
❌ Card editing UI (after creation)
❌ Card deletion UI
❌ Image occlusion cards
❌ Audio cards
❌ Video cards
❌ Import from Anki

---

### Testing Checklist

**Phase 1.1:**
- [x] PDF opens and displays correctly
- [x] Page navigation works
- [x] Position saves and restores

**Phase 1.2:**
- [x] Text selection dialog works
- [x] Section creation saves correctly
- [x] Section appears in database

**Phase 1.3:**
- [x] Card button appears and enables correctly
- [x] Card editor opens with all fields
- [x] Type switching works (Q&A, Cloze, True/False)
- [x] True/False toggle saves correctly
- [x] Front/back validation works
- [x] Save creates card in database
- [x] Success feedback appears
- [x] Selection clears after save
- [x] Long text truncates properly (500 chars)
- [x] Hash computed from full text
- [x] Card appears in Create tab stream
- [x] Document card count updates
- [x] Error handling works for all cases
- [x] No crashes in any flow


