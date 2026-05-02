# Project Overview: herta_assistant_bot

`herta_assistant_bot` is a Flutter-based desktop assistant themed after **Madam Herta** (*Honkai: Star Rail*). The assistant features a "Genius" persona and acts as a functional system-level utility for Windows.

## Core Features
- **AI Persona**: Enforces a Madam Herta persona (elegant, dry, slightly arrogant) via system prompt.
- **Backend**: Uses Google Gemini API (`gemini-2.0-flash`) for efficient and reliable inference.
- **Desktop Integration**:
    - **Window Management**: Borderless design with custom drag-to-move controls.
    - **Global Hotkeys**: `Alt+Space` to summon/hide the assistant from anywhere in the OS.
    - **System Automation**: Capable of launching system apps (Notepad, Task Manager), opening URLs, and performing web searches (YouTube, Google, GitHub) based on natural language commands.
- **Robustness**: Includes automatic model fallback and request rate-limiting to manage API quotas.

## Tech Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **AI Backend**: `google_generative_ai` (Gemini API)
- **Desktop Utilities**: `window_manager`, `hotkey_manager`, `url_launcher`, `process_run`

## Architecture
- `lib/core/`:
    - `ai/`: Persona system prompt.
    - `models/`: Data structures.
    - `services/`: Core logic (`GeminiService`, `CommandExecutor`, `HistoryService`).
- `lib/features/chat/`:
    - `provider/`: `ChatProvider` for state management and rate-limiting.
    - `ui/`: Main chat interface.
- `lib/shared/widgets/`: Modular, decoupled UI components.

## Setup
1. **API Key**: Ensure you have a valid Google Gemini API Key. (Recommend storing in a `.env` file).
2. **Commands**:
    - **Run Application**: `flutter run -d windows`.
    - **Dependencies**: `flutter pub get`.

## Development Conventions
- **Persona**: Maintain a balance between efficiency (Work Mode) and Herta's character (Banter Mode).
- **State Management**: Use `Provider` for all reactive UI updates.
- **Security**: Never commit API keys to version control.
