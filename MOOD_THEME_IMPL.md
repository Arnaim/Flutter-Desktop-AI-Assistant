# Ineffa: Mood-Reactive Theme System — Implementation Guide

> **Scope**: Wires `AppTheme.getThemeData(mood)` to live AI responses via `ThemeService` and `Provider`,
> so Ineffa's entire color palette shifts automatically when her mood changes.

---

## 1. `ThemeService` — Mood State Holder

**Location**: `lib/core/services/theme_service.dart`

```dart
import 'package:flutter/material.dart';
import '../models/mood.dart';

class ThemeService extends ChangeNotifier {
  Mood _mood = Mood.neutral;

  Mood get mood => _mood;

  void setMood(Mood newMood) {
    if (_mood != newMood) {
      _mood = newMood;
      notifyListeners(); // triggers full app theme rebuild
    }
  }
}
```

> `ThemeService` likely already exists in your project — confirm it extends `ChangeNotifier`
> and exposes `setMood()`. If it uses a different pattern (e.g. `ValueNotifier`), adapt accordingly.

---

## 2. Register `ThemeService` in `main.dart`

Wrap your root widget so `ThemeService` is accessible app-wide:

```dart
import 'package:provider/provider.dart';
import 'core/services/theme_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        // ... your other existing providers (ChatProvider, SystemStatsProvider, etc.)
      ],
      child: const IneffaApp(),
    ),
  );
}
```

---

## 3. Wire `ThemeService` into `MaterialApp`

**Location**: Your root `App` widget (wherever `MaterialApp` is declared).

```dart
class IneffaApp extends StatelessWidget {
  const IneffaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds MaterialApp whenever mood changes
    final mood = context.watch<ThemeService>().mood;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getThemeData(mood), // ← the reactive hook
      home: const HomeScreen(),
    );
  }
}
```

**Why here**: `MaterialApp` sits above all widgets, so a theme change here propagates
via `Theme.of(context)` to every widget in the tree — no manual rebuilds needed anywhere else.

---

## 4. Mood Detection in `GeminiService`

After receiving an AI response, parse the mood and push it to `ThemeService`.

**Location**: `lib/core/services/gemini_service.dart`

```dart
// Add to your response-handling method
void _applyMoodFromResponse(String response, ThemeService themeService) {
  final lower = response.toLowerCase();

  Mood detected;

  if (_containsAny(lower, ['😊', ':)', 'hehe', 'yay', 'glad', 'happy'])) {
    detected = Mood.happy;
  } else if (_containsAny(lower, ['❤️', '💙', 'care', 'miss', 'warmth', 'affection'])) {
    detected = Mood.affectionate;
  } else if (_containsAny(lower, ['focus', "let's get", 'task', 'working on', 'analyzing'])) {
    detected = Mood.focused;
  } else if (_containsAny(lower, ['hmph', 'annoyed', 'sigh', 'really?', '😤'])) {
    detected = Mood.annoyed;
  } else {
    detected = Mood.neutral;
  }

  themeService.setMood(detected);
}

bool _containsAny(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));
```

Call this right after the Gemini response is received and before returning it to `ChatProvider`:

```dart
// Inside your existing send/stream method, after getting `responseText`:
_applyMoodFromResponse(responseText, themeService);
```

> **Alternative (more reliable)**: Instruct Gemini via the system prompt to prefix responses
> with a mood tag (e.g. `[MOOD:happy]`) and strip it before display. This avoids keyword
> brittleness entirely. See §7 for the system prompt addition.

---

## 5. Inject `ThemeService` into `GeminiService`

Pass `ThemeService` to `GeminiService` at construction or via the Provider:

```dart
// Option A — Constructor injection (preferred for services)
class GeminiService {
  final ThemeService _themeService;

  GeminiService({required ThemeService themeService})
      : _themeService = themeService;
  // ...
}

// In main.dart providers list:
ChangeNotifierProvider(create: (_) => ThemeService()),
ProxyProvider<ThemeService, GeminiService>(
  update: (_, themeService, __) => GeminiService(themeService: themeService),
),
```

---

## 6. Optional — Smooth Theme Transition

Replace the hard cut with a gentle crossfade using `AnimatedTheme`:

```dart
// In IneffaApp.build():
return MaterialApp(
  theme: AppTheme.getThemeData(mood),
  builder: (context, child) => AnimatedTheme(
    data: AppTheme.getThemeData(mood),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    child: child!,
  ),
  home: const HomeScreen(),
);
```

For the glassmorphism tint (your `BackdropFilter` overlays), also animate their color:

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 600),
  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: yourContent,
  ),
)
```

---

## 7. System Prompt Addition (Recommended)

Add this block to `system_prompt.dart` so mood is machine-readable and consistent:

```
At the very start of every response, output one of these tags on its own line, then continue normally:
[MOOD:happy] [MOOD:affectionate] [MOOD:focused] [MOOD:annoyed] [MOOD:neutral]

Choose based on your current emotional state in the conversation.
Strip this tag from what you display — it is for internal use only.
```

Then in `GeminiService`, parse and strip it before returning:

```dart
(Mood, String) _extractMood(String raw) {
  final moodPattern = RegExp(r'\[MOOD:(\w+)\]');
  final match = moodPattern.firstMatch(raw);

  Mood mood = Mood.neutral;
  if (match != null) {
    mood = Mood.values.firstWhere(
      (m) => m.name == match.group(1),
      orElse: () => Mood.neutral,
    );
  }

  final cleaned = raw.replaceAll(moodPattern, '').trimLeft();
  return (mood, cleaned);
}

// Usage:
final (detectedMood, displayText) = _extractMood(rawResponse);
themeService.setMood(detectedMood);
return displayText; // send this to UI
```

---

## 8. Data Flow Summary

```
User sends message
       ↓
GeminiService → Gemini API
       ↓
Raw response received
       ↓
_extractMood() → strips [MOOD:x] tag
       ↓                    ↓
Display text          ThemeService.setMood()
sent to ChatProvider        ↓
       ↓              notifyListeners()
   Chat UI                  ↓
                    IneffaApp rebuilds
                            ↓
                 AppTheme.getThemeData(newMood)
                            ↓
                  Entire app repaints ✓
```

---

## 9. Issues Noticed in Existing Code

| # | File | Issue | Fix |
|---|------|-------|-----|
| 1 | `app_theme.dart` | `withOpacity()` is deprecated in Flutter 3.27+ | Replace with `.withValues(alpha: 0.5)` |
| 2 | `app_theme.dart` | `fontFamily: 'Segoe UI'` — Segoe UI is a Windows system font, not bundled | Add it via `pubspec.yaml` fonts or fall back to a bundled font like `Raleway` |
| 3 | `app_theme.dart` | `inputDecorationTheme` uses `surfaceColor` from a local variable but `ThemeData` is static — if the input field is rebuilt without a full theme refresh it may not repaint | Ensure all glassmorphism containers listen to `Theme.of(context)` rather than holding color values in local state |
| 4 | `main.dart` (assumed) | If `GeminiService` is instantiated before `ThemeService` is registered, injection will fail silently | Register `ThemeService` first in `MultiProvider` list |
| 5 | `system_prompt.dart` | Mood is currently inferred from keywords client-side — fragile for a multilingual or pun-heavy persona like Ineffa | Use the `[MOOD:x]` tag approach (§7) for deterministic parsing |

---

## Files Modified / Created

| File | Change |
|------|--------|
| `lib/core/services/theme_service.dart` | Ensure `ChangeNotifier` + `setMood()` |
| `lib/core/services/gemini_service.dart` | Add `_extractMood()`, call `themeService.setMood()` |
| `lib/core/theme/app_theme.dart` | Fix deprecated `withOpacity` → `withValues` |
| `main.dart` | `MultiProvider` with `ThemeService` first; `MaterialApp` watches mood |
| `lib/core/ai/system_prompt.dart` | Add `[MOOD:x]` instruction block |
