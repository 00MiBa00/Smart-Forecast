# Quick Testing Guide

## Before Submitting to App Store

### 1. Generate Code & Build
```bash
# Generate database code
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze for issues
flutter analyze

# Build for iOS
flutter build ios --release
```

### 2. Fresh Install Test (CRITICAL)
This simulates the App Store reviewer's experience:

```bash
# Option A: Simulator
1. Delete app from simulator
2. Run: flutter run --release
3. Follow test steps below

# Option B: Physical Device
1. Delete app from device
2. Install via Xcode or TestFlight
3. Follow test steps below
```

### 3. Test Checklist

#### First Launch (1 minute)
- [ ] App launches without crashes
- [ ] Onboarding shows (4 screens)
- [ ] Can skip onboarding
- [ ] Lands on Library tab with empty state
- [ ] "Try Demo Document" button is visible and prominent
- [ ] "Import PDF" button is visible as secondary

#### Demo Content (2 minutes)
- [ ] Tap "Try Demo Document"
- [ ] Loading indicator shows
- [ ] Demo document appears in Library
- [ ] Demo opens in Reader view
- [ ] Can see document title and content placeholder

#### Review Flow (3 minutes)
- [ ] Switch to Review tab
- [ ] See "12 cards due today"
- [ ] Tap "Start Review"
- [ ] Review session starts
- [ ] Can tap to reveal answers
- [ ] Can rate cards (Again/Hard/Good/Easy)
- [ ] Complete at least 3 cards
- [ ] End session shows summary

#### Browse Cards (1 minute)
- [ ] Switch to Create tab
- [ ] See 20 demo cards listed
- [ ] Can tap to view card details
- [ ] Cards show proper content

#### Import User Content (2 minutes)
- [ ] Return to Library tab
- [ ] Tap + button
- [ ] Select "Import PDF"
- [ ] Pick a PDF from Files
- [ ] Document imports successfully
- [ ] Opens in Reader

#### Regression Tests
- [ ] Demo doesn't duplicate (tap "Try Demo" again)
- [ ] User documents and demo coexist
- [ ] Review works with both demo and user cards
- [ ] App doesn't crash on any screen

### 4. Empty State Tests

Test these scenarios by:
- Deleting demo (if you added delete functionality)
- Fresh install

#### Library Empty State
- [ ] Shows "No documents yet"
- [ ] "Try Demo Document" button present
- [ ] "Import PDF" button present

#### Review Empty State (no cards)
- [ ] Shows "No cards to review yet"
- [ ] "Try Demo Session" button present
- [ ] "Import PDF" button present

#### Review Empty State (all caught up)
- [ ] Shows success icon
- [ ] Shows "You're all caught up!"
- [ ] "Browse Documents" button present

#### Create Empty State
- [ ] Shows "No cards yet"
- [ ] "Try Demo" button present
- [ ] "Create Card" button present

### 5. Offline Test
- [ ] Enable Airplane Mode
- [ ] Launch app (fresh or existing)
- [ ] Verify all demo features work
- [ ] Verify review session works
- [ ] No network error messages

### 6. Performance Test
- [ ] App launches in < 3 seconds
- [ ] Demo loads in < 2 seconds
- [ ] Review session is responsive
- [ ] No stuttering or lag
- [ ] Memory usage is reasonable

## Common Issues & Fixes

### Issue: Demo doesn't appear
**Fix:** Check that database migration ran. Delete app and reinstall.

### Issue: Cards not showing in Review
**Fix:** Check that SRS records were created with past due dates.

### Issue: Onboarding shows every time
**Fix:** Check SharedPreferences is working. Look for `onboarding_complete` key.

### Issue: Build fails
**Fix:** 
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Database errors
**Fix:** Delete app completely to reset database, then reinstall.

## App Store Connect Setup

### Review Notes
Copy content from `docs/app_review_notes.txt` to:
- App Store Connect → App Review Information → Notes

### Screenshots
Capture:
1. Library with demo document
2. Review with due cards
3. Active review session
4. Cards list in Create tab

### Test Account
Not needed! App works without login.

## What Reviewers Will Test

Based on Guideline 4.2, reviewers will likely:
1. ✅ Launch app and check for immediate value
2. ✅ Look for clear user journey
3. ✅ Test core features without importing content
4. ✅ Verify app works offline
5. ✅ Check that features are complete, not placeholder

## Success Criteria

Your app will pass if:
- ✅ Demo content is immediately accessible
- ✅ Full review session works start-to-finish
- ✅ All core features are demonstrated
- ✅ No network required
- ✅ Clear CTAs at every step
- ✅ Professional UX (no bugs or crashes)

## Before Submission Checklist

- [ ] All tests above pass
- [ ] No analyzer warnings or errors
- [ ] App builds successfully for release
- [ ] Demo PDF asset exists (or works without it)
- [ ] App review notes prepared
- [ ] Screenshots captured
- [ ] Version number updated
- [ ] Release notes written

## Timeline

Expected review time: 1-3 days after submission

If rejected again:
1. Read rejection reason carefully
2. Check which test case failed
3. Fix and document changes
4. Retest thoroughly
5. Resubmit with updated notes

## Need Help?

If tests fail or you're unsure about something:
1. Check `IMPLEMENTATION_SUMMARY.md` for technical details
2. Review `docs/app_review_notes.txt` for reviewer instructions
3. Check Flutter/Xcode console for error messages
4. Test on multiple devices if possible
