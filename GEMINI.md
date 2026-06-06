# Gemini Project Context: Ineffa Assistant Bot

`ineffa_assistant_bot` is a Flutter-based desktop assistant for Windows, themed after **Ineffa**, a cheerful yet level-headed robotic persona from Nod-Krai. It integrates the Google Gemini API to provide intelligent responses and system-level automation.

## Project Overview

- **Core Technology**: Flutter (Windows Desktop)
- **AI Backend**: Google Gemini API (`google_generative_ai` package)
  - Models: `gemini-3-flash`, `gemini-3.1-flash-lite`, `gemma-4-31b`
- **Persona**: **Ineffa** - Polite, robotic, caring, and pun-loving. Refers to the user as "Arnab".
- **Primary Platform**: Windows (supports custom window management and global hotkeys).
- **UI Aesthetic**: Glassmorphism (Frosted glass effect using `BackdropFilter` and semi-transparent theme colors).
- **System Dashboard**: Live hardware telemetry in the sidebar (CPU, RAM, Battery usage).
- **Global Memory**: Persistent long-term memory across all chat sessions (via `global_memory.json`).
- **Vision System**: On-demand screen capture (held in RAM) for AI visual analysis.
- **Mood-Reactive UI**: Ineffa autonomously shifts her mood (happy, neutral, affectionate, focused, annoyed) based on conversation context, dynamically changing the app's entire color palette and glassmorphism tints.

## Architecture & Structure

The project follows a modular structure:

- **`lib/core/`**: Core infrastructure.
  - `ai/`: Contains `system_prompt.dart`, defining the Ineffa persona and command trigger phrases.
  - `models/`: Data models (e.g., `messages.dart` for chat history and media support).
  - `services/`: 
    - `GeminiService`: Manages AI interactions, model fallback, and memory/vision injection.
    - `MemoryService`: Manages the persistent global memory file.
    - `ThemeService`: Manages the dynamic theme state based on Ineffa's mood.
    - `SystemStatsProvider`: Provides real-time hardware telemetry data to the UI.
    - `CommandExecutor`: Parses AI responses for trigger phrases and executes system actions.
    - `HistoryService`: Manages chat session persistence.
  - `theme/`: Contains `app_theme.dart`, which acts as a dynamic factory for generating `ThemeData` per mood.
- **`lib/features/chat/`**: Main functional feature.
  - `provider/`: `ChatProvider` handles state management, screen capture, and coordinating between services.
  - `ui/`: Chat interface components.
- **`lib/shared/widgets/`**: Reusable UI components.

## Key Features & Triggers

### System Commands
The assistant can execute Windows commands if the AI response includes:
- `Open path: [C:\path]` -> Opens a folder or file.
- `Write to Notepad: [text]` -> Creates a temp file with the text and opens it in Notepad.
- `Type this: [text]` -> Simulates typing the text into the currently active window (PowerShell SendKeys).
- `MEMORIZE: [fact]` -> Saves a fact about Arnab to the global memory file.
- `Open Task Manager`, `Open Notepad`, `Open Brave`, etc. -> Launches system apps.
- `Search Google for [query]` or `Search YouTube for [query]` -> Opens browser.

### Vision (Screen Analysis)
- **Manual Capture**: Click the Eye icon to snapshot the screen.
- **AI Analysis**: Once captured, ask Ineffa things like "What's on my screen?" or "Explain this error." 
- **Privacy**: Screenshots are stored in volatile memory (RAM) and never saved to the disk.

### Desktop Integration
- **Global Hotkey**: `Alt + Space` (managed by `hotkey_manager`).
- **Window Management**: Borderless window with custom move controls (managed by `window_manager`).

## Development Guidelines

### Commands
- **Install Dependencies**: `flutter pub get`
- **Run App (Windows)**: `flutter run -d windows`
- **Analyze Code**: `flutter analyze`

### Conventions
- **State Management**: Use `Provider`.
- **Persona Consistency**: Always maintain Ineffa's robotic yet sweet tone. Responses should be concise (1-3 sentences).
- **AI Fallback**: The system automatically switches models if one fails or hits a quota.
- **Context Injection**: `GeminiService` injects OS environment details and Global Memories into every prompt.

## Security
- **API Keys**: Stored locally via `SettingsService` (shared_preferences). Never hardcode or commit API keys.
