# Spend Gremlin — Project Handoff Document

## What is this app?
A MyFitnessPal-style **daily spending tracker** for Android called **Spend Gremlin**.
Mascot is a raccoon. Dark theme. Money-green accent. Terminal/utility aesthetic.

---

## Stack Decision
- **Flutter (Dart)** — cross-platform, runs on Android, builds real APKs
- **Local DB: drift** (SQLite wrapper for Flutter)
- **State management: flutter_riverpod**
- **Navigation: go_router**
- **OS: Kali Linux (rolling)**
- **Java: 21**
- **Flutter: 3.41.6 stable**
- **Android SDK: 36.0.0 ✅**

---

## Project Location
```
~/spend_gremlin/
```
Raccoon image should be at:
```
~/spend_gremlin/assets/images/raccoon.jpg
```
Original image filename: `artworks-JrzT3yNhcILYh3He-Oy3D4g-t500x500.jpg`

Visual mockup file: `spend_gremlin_full_mockup_v2.html` — keep this in the project directory so Cursor can read it directly.

---

## Dependencies Added (pubspec.yaml)
```
drift
drift_flutter
sqflite
path
provider
flutter_riverpod
riverpod_annotation
go_router
percent_indicator
shared_preferences
intl
image_picker

dev:
drift_dev
build_runner
riverpod_generator
```

---

## Current Setup State — ALL DONE ✅
- [x] Flutter installed at `~/flutter`
- [x] PATH set in `~/.bashrc`
- [x] Android SDK at `~/Android` (version 36.0.0)
- [x] Android licenses accepted
- [x] Flutter project created at `~/spend_gremlin`
- [x] All dependencies added via `flutter pub add`
- [x] Android SDK 36 + build-tools installed and verified
- [x] `flutter doctor` — Android toolchain ✓, Connected device ✓, Network ✓
- [ ] App code — NOT STARTED YET

### flutter doctor output (final verified state)
```
[✓] Flutter (Channel stable, 3.41.6)
[✓] Android toolchain (Android SDK version 36.0.0)
[✓] Connected device (1 available)
[✓] Network resources
```
Chrome and Linux toolchain warnings are irrelevant — building for Android only.

---

## App Feature Spec (complete)

### Screens
1. **Splash** — raccoon photo in a circle, text "Spend Gremlin" only, nothing else
2. **Dashboard** (home) — main screen
3. **Day Detail** — tap a category card to view/edit
4. **Add Expense Sheet** — bottom sheet via + button
5. **Settings**
6. **Insights**

### Bottom Nav (5 slots)
| Position | Item |
|----------|------|
| Far Left | Dashboard (home icon) |
| Left-centre | History |
| **Centre** | **Floating + button (add expense)** |
| Right-centre | Insights |
| Far Right | Settings |

### Category System (3 tiers)
| Tier | Name | Behaviour |
|------|------|-----------|
| Core | Food | Always present every day, editable from dashboard tap |
| Core | Travel | Always present every day, editable from dashboard tap |
| Custom | User-defined | Unlimited, user picks name + emoji (optional, defaults to 🦝), managed via + button |
| Special | Miscellaneous | Catch-all bucket, managed via + button, has its OWN separate spending limit |

### Limits
- **Daily Spend Limit** — set in Settings, covers total of all categories
- **Misc Limit** — separate limit set in Settings, only for miscellaneous category
- Both are set by the user

### The Ring (Dashboard centrepiece)
- Circular progress bar (like MyFitnessPal calorie ring)
- Shows: spent / daily limit
- Tapping it toggles view: **Daily → Weekly → Monthly**
- **Ring only turns red and overshoots past 360° if TOTAL daily spend exceeds daily limit**
- Individual category overflows do NOT affect the ring
- When over limit: ring arc continues in red past the full circle

### Overflow / Warning UI
- **Misc over its limit**: misc card border turns red, shows `⚠ over by ₹X` tag
- **Total day over daily limit**: ring overshoots in red + a red warning banner appears below all cards
- Overflow is visual only on the relevant card/ring — nothing else changes

### Include / Exclude Toggle
- Each expense item has a micro-toggle to exclude it from the ring counter
- Settings has master include/exclude toggles per category
- User can choose per-item or per-category what feeds into the daily total

### Add Expense Sheet (via + button)
- Select category (core / custom / misc)
- Amount — **MANDATORY** (only required field)
- Name — optional
- When creating a NEW custom category: name (required) + emoji (optional, defaults to 🦝)

### Dashboard Behaviour
- Food and Travel cards are tappable → opens Day Detail screen with inline add/edit
- Custom and Misc items are only manageable via the + button
- Shows today's spend per category under each card

### Settings Screen
- Set daily spend limit
- Set misc limit
- Per-category include/exclude master toggles

### Insights Screen (content)
1. **Spend trends** — bar/line chart of daily total over last 7/30 days
2. **Category breakdown** — donut chart showing % split across categories for the month
3. **Best/worst days** — "Your cheapest day this week was Tuesday (₹340)"
4. **Daily limit breach log** — GitHub-style calendar heatmap (red = over, green = under)
5. **Misc creep tracker** — how often and how much misc bleeds over its limit
6. **Streak counter** — consecutive days under daily limit (gamification)
7. **Monthly forecast** — projects month-end total based on average daily spend so far

---

## Design Language
- **Theme**: Dark background, money-green accent (`#00C853` or similar), monospace font for labels
- **Numbers**: Serif (Georgia-style) font for amounts — feels weighty
- **Labels**: Monospace for all category/data labels — feels precise
- **Personality**: Bloomberg Terminal meets a raccoon's wallet

---

## Build Order
1. ~~Install + setup~~ ✅ Complete
2. App theme + constants
3. Data layer (drift DB models + DAOs)
4. Navigation shell (go_router + bottom nav)
5. Splash screen
6. Dashboard (ring + category cards)
7. Add expense bottom sheet
8. Day detail / edit screen
9. Settings screen
10. Insights screen

---

## IDE
**Cursor** is installed and will be used as the agent to build everything.
Project is open at `~/spend_gremlin`. Cursor has full directory access.
The mockup HTML file `spend_gremlin_full_mockup_v2.html` should be placed in the project root so Cursor can read it directly.

---

## Prompt to Paste into Cursor Chat (Agent Mode)

> You are building a Flutter Android app called **Spend Gremlin** for me. The project already exists at `~/spend_gremlin` with all pub dependencies installed, Android SDK 36 configured, and `flutter doctor` showing all green for Android. Flutter 3.41.6 stable, Dart 3.11.4, Java 21.
>
> Read the file `spend_gremlin_full_mockup_v2.html` in this directory — it is the full interactive visual mockup showing every screen, state, overflow UI, and the insights layout. Use it as your design reference for everything.
>
> The raccoon image for the splash screen is at `assets/images/raccoon.jpg`.
>
> Full feature spec is below. Build the entire app autonomously in this order, creating and writing all files directly into the project:
> 1. App theme + constants
> 2. Data layer — drift DB models and DAOs
> 3. go_router navigation shell + bottom nav
> 4. Splash screen
> 5. Dashboard with ring + category cards
> 6. Add expense bottom sheet
> 7. Day detail / edit screen
> 8. Settings screen
> 9. Insights screen
>
> After all files are written, run `flutter build apk --debug` and fix any errors until the build succeeds.
>
> --- FEATURE SPEC BELOW ---
> [paste the rest of this document here]
