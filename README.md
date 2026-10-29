
# Desktop Assistant Bot

A Flutter-based desktop AI assistant designed to provide conversational AI capabilities alongside practical desktop automation. It integrates Google's Gemini API with native desktop functionality, allowing users to interact with an AI assistant, launch applications, manage basic system tasks, and perform web searches through natural language commands.

## Features

### AI-Powered Conversations
- Integrates Google's Gemini API for natural language processing and conversational interactions.
- Supports multiple Gemini models with automatic fallback when API quotas are exhausted.
- Configurable system prompts for customizing assistant behavior and response style.
- Request rate limiting to help manage API usage.

### Desktop Integration
- **Borderless Window:** Custom window design with drag-to-move functionality.
- **Global Hotkey:** Use `Alt + Space` to summon or hide the assistant from anywhere in the operating system.
- **Application Launcher:** Launch system applications such as Notepad and Task Manager.
- **Web Navigation:** Open URLs and perform searches across Google, YouTube, and GitHub using natural language commands.

### Reliability & Performance
- Automatic model switching when API quota limits are reached.
- Request rate limiting to manage API consumption.
- Modular architecture for easier maintenance and future development.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Desktop application framework |
| Dart | Primary programming language |
| Provider | State management |
| Google Gemini API | AI inference and conversational capabilities |
| google_generative_ai | Gemini API integration |
| window_manager | Desktop window management |
| hotkey_manager | Global keyboard shortcuts |
| url_launcher | Opening URLs and web searches |
| process_run | Executing system commands and applications |

## Project Structure

```text
lib/
├── core/
│   ├── ai/
│   │   └── System prompts and AI configuration
│   ├── models/
│   │   └── Application data models
│   └── services/
│       ├── GeminiService
│       ├── CommandExecutor
│       └── HistoryService
│
├── features/
│   └── chat/
│       ├── provider/
│       │   └── ChatProvider
│       └── ui/
│           └── Chat interface
│
└── shared/
    └── widgets/
        └── Reusable UI components
```

## Prerequisites

Before running the project, ensure you have:

- [Flutter SDK](https://flutter.dev/) installed and configured.
- [Dart SDK](https://dart.dev/) compatible with your Flutter installation.
- Windows desktop development support enabled in Flutter.
- A valid [Google Gemini API Key](https://aistudio.google.com/apikey).

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd desktop_assistant_bot
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure the API Key

Obtain an API key from [Google AI Studio](https://aistudio.google.com/apikey).

For local development, store the API key in a `.env` file:

```env
GEMINI_API_KEY=your_api_key_here
```

Ensure that `.env` is included in `.gitignore` to prevent accidentally exposing sensitive credentials.

### 4. Run the Application

```bash
flutter run -d windows
```

### 5. Build for Release

```bash
flutter build windows --release
```

The compiled application will be available in:

```text
build/windows/x64/runner/Release/
```

## AI Model Configuration

The application supports multiple Gemini models:

- `gemini-3.5-flash`
- `gemini-3.6-flash`
- `gemini-3.5-flash-lite`

The application implements automatic model fallback to improve availability when a model reaches its API quota limits.

*Note: Model availability, API quotas, and pricing are subject to Google's current Gemini API policies.*

## Development Guidelines

- **State Management:** Use Provider for reactive application state and UI updates.
- **Architecture:** Keep services, business logic, state management, and UI components separated.
- **AI Configuration:** Maintain system prompts and model configuration independently from UI components.
- **Security:** Never commit API keys, credentials, or other sensitive configuration files.
- **Maintainability:** Prefer modular, reusable components and clearly defined service responsibilities.

## Future Improvements

Potential areas for further development include:

- Persistent conversation history and chat management.
- Expanded desktop automation capabilities.
- Customizable keyboard shortcuts.
- Additional AI model integrations.
- Improved error handling and API usage monitoring.
- User-configurable assistant settings.

## License

This project is currently unlicensed unless a license is specified in the repository.
