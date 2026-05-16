# FinAssets Management

An offline-first Flutter application designed for managing financial assets and tracking their value over time.

## 🚀 Features

- **Offline-First Architecture**: View and manage your assets even without an internet connection.
- **Background Synchronization**: Automatically syncs local changes with a remote server once connectivity is restored.
- **Asset History**: Track value updates for each asset with detailed history.
- **Robust Sync Queue**: Uses a transaction-log style queue to ensure data integrity during synchronization.
- **Multi-Platform Support**: Designed to work on Android, Windows, and Linux.

## 🏗️ Architecture

The project follows a clean repository-pattern architecture:

- **Models**: Immutable data classes for `Asset` and `Update`.
- **Local Database**: SQLite-based storage using `sqflite` with optimized indexing and foreign key support.
- **Repositories**: Handle the logic of switching between local cache and remote API (PostgREST).
- **Sync Service**: Manages the synchronization lifecycle and connectivity monitoring.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Networking**: [http](https://pub.dev/packages/http)
- **ID Generation**: [uuid](https://pub.dev/packages/uuid)
- **State Management**: (Add your specific state management here, e.g., Provider/Riverpod)

## 🏁 Getting Started

### Prerequisites

- Flutter SDK
- A PostgREST-compatible backend API

### Configuration

Create or update your environment configuration in `lib/config/env.dart`:

```dart
class Env {
  static const String baseUrl = 'YOUR_API_BASE_URL';
}
```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/flutter_assets_management.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
