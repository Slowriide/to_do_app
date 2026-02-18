# ToDo App

A clean, offline-first Flutter app for managing notes and tasks with reminders, subtasks, and folder organization.

Designed with **Clean Architecture** and built for multi-platform Flutter targets (mobile, desktop, and web), this project focuses on clear structure, maintainability, and a polished user experience.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Development Commands](#development-commands)
- [Future Improvements](#future-improvements)
- [Contributing](#contributing)

## Overview

This application helps users:

- Capture notes quickly
- Track todos with subtasks
- Schedule reminders and local notifications
- Organize content with folders
- Search and filter content efficiently

It uses local persistence (Isar), so core functionality works without a backend.

## Features

- Notes CRUD: create, read, update, delete notes
- Todos CRUD: create, read, update, delete todos
- Subtasks: add, reorder, complete, and remove subtasks
- Reminders: date/time reminders for notes and todos
- Notifications: scheduled local notifications
- Folders: organize notes and todos by folder
- Search and filtering: query by content and folder
- Pinning and ordering: prioritize important items
- Theme support: light/dark mode
- Responsive UI across Flutter platforms

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: `flutter_bloc` (Cubit)
- **Routing**: `go_router`
- **Local Database**: Isar
- **Persistence**: `shared_preferences`
- **Notifications**: `flutter_local_notifications`, `timezone`
- **UI**: Material 3, custom reusable widgets

## Architecture

The project follows **Clean Architecture** with three layers:

### 1. Domain (`lib/domain/`)

- Pure Dart entities (`Note`, `Todo`, `Folder`)
- Repository contracts (`NoteRepository`, `TodoRepository`, `FolderRepository`)
- No framework dependencies

### 2. Data (`lib/data/`)

- Isar models (`isar_note.dart`, `isar_todo.dart`, `isar_folder.dart`)
- Repository implementations for persistence
- Mapping between domain models and database models

### 3. Presentation (`lib/presentation/`)

- Feature pages and reusable UI widgets
- Cubits for feature state (`NoteCubit`, `TodoCubit`, `ThemeCubit`, etc.)
- Search/filter Cubits for derived view state

## Getting Started

### Prerequisites

- Flutter SDK (3.x or newer recommended)
- Dart SDK (bundled with Flutter)
- A device/emulator or desktop/web target

### Installation

```bash
git clone https://github.com/Slowriide/to_do_app.git
cd to_do_app
flutter pub get
```

### Run the App

```bash
flutter run
```

Run on a specific target:

```bash
flutter run -d windows
flutter run -d chrome
```

## Project Structure

```text
lib/
  common/          # Shared widgets and utilities
  core/            # Router, theme, notifications, local storage, bootstrap
  data/            # Isar models + repository implementations
  domain/          # Entities + repository interfaces
  presentation/    # Pages, cubits, and feature UI
```

## Development Commands

Install dependencies:

```bash
flutter pub get
```

Run tests:

```bash
flutter test
```

Run a single test file:

```bash
flutter test test/widget_test.dart
```

Analyze code:

```bash
flutter analyze
```

Format code:

```bash
dart format lib/
```

Regenerate Isar code after model changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Future Improvements

- Better onboarding and first-run experience
- Undo/redo and action history
- Rich text support for notes
- Recurring reminders
- Cloud sync and backup
- CI pipeline for linting, tests, and build checks
- Improved accessibility and keyboard navigation

## Contributing

Contributions are welcome. If you open a PR, please:

- Keep changes focused and well-scoped
- Follow existing architecture and naming patterns
- Add or update tests when behavior changes

---

Created by Thiago Gobbi.
