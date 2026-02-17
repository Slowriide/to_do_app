# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Build & Development Commands

```powershell
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d windows
flutter run -d chrome

# Generate Isar database code (required after modifying isar_*.dart models)
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Format code
dart format lib/
```

## Architecture

This app follows **Clean Architecture** with three main layers:

### Domain Layer (`lib/domain/`)
- **Pure Dart models** (`Note`, `Todo`) - immutable, framework-independent
- **Repository interfaces** - abstract contracts (`NoteRepository`, `TodoRepository`)
- Domain models use `copyWith()` pattern for immutability

### Data Layer (`lib/data/`)
- **Isar models** (`NoteIsar`, `TodoIsar`) - database entities with `@collection` annotation
- **Repository implementations** - `IsarNoteRepositoryImpl`, `IsarTodoRepositoryImpl`
- Isar models have `toDomain()` and `fromDomain()` converters
- Generated files (`*.g.dart`) are created by `build_runner` - never edit manually

### Presentation Layer (`lib/presentation/`)
- **Cubits** for state management (not full Bloc pattern, just `Cubit<State>`)
- Each feature has its own cubit: `NoteCubit`, `TodoCubit`, `ThemeCubit`
- Search cubits (`NoteSearchCubit`, `TodoSearchCubit`) handle filtering

## Key Patterns

### State Management
- Uses `flutter_bloc` with Cubits (emit state directly, no events)
- Repositories injected via `RepositoryProvider` in `main.dart`
- Cubits provided globally via `MultiBlocProvider`

### Routing
- Uses `go_router` with named routes defined in `lib/core/config/router/app_router.dart`
- Pass data between routes using `state.extra`

### Database
- **Isar** for local persistence (NoSQL embedded database)
- Subtasks stored as `IsarLinks` relationship on parent Todo
- Database initialized in `main()` before `runApp()`

### Notifications
- `NotificationService` singleton in `lib/core/notifications/`
- Reminders scheduled when creating/updating notes or todos with a reminder date

## Common Widgets
Reusable widgets are in `lib/common/widgets/`:
- `TodoItem`, `NoteItem` - list item components
- `MyDrawer` - navigation drawer
- `MyBottomSheet` - modal bottom sheets
- `SubtasksItemsView` - subtask list with reordering support
