## What changed?
Describe the module/scope and why it is different from existing games.

## Ownership and integration
- Branch: `feature/...`
- Owned paths:
- Did you edit a shared integration file? If yes, who approved it?
- New game ID, catalog title, icon path:
- Objective and completion condition:
- Session result fields and storage changes required:
- Requested additions for integration owner:
- Campaign schedule impact (normally none):

## Safety / user experience
- [ ] Existing nine games and user progress are preserved
- [ ] Seeded/generated levels are solvable
- [ ] Invalid/double input is handled safely
- [ ] No unnecessary vertical gameplay scrolling at 360x640
- [ ] Async callbacks cannot update disposed or restarted sessions
- [ ] UI matches light pastel theme and remains legible

## Verification
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build web --release --base-href /flooria/` (for UI changes)
- [ ] CI checks green
- Screenshots / known limitations:
