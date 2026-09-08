# Widget Architecture & Design System

## 1. Widget Hierarchy Taxonomy

```text
┌────────────────────────────────────────────────────────┐
│                     SCREEN WIDGETS                     │
│  - Located in: features/<name>/presentation/screens/   │
│  - Registered in GoRouter route table                  │
│  - Responsible for Scaffold, AppBar, top-level layout  │
└───────────────────────────┬────────────────────────────┘
                            │ Contains
                            ▼
┌────────────────────────────────────────────────────────┐
│                 FEATURE-SCOPED WIDGETS                 │
│  - Located in: features/<name>/presentation/widgets/   │
│  - Domain-specific (e.g. PostCard, DoseDialog)         │
│  - Consumes feature StateNotifiers                     │
└───────────────────────────┬────────────────────────────┘
                            │ Composes
                            ▼
┌────────────────────────────────────────────────────────┐
│                  SHARED / ATOMIC UI                    │
│  - Located in: shared/widgets/ and app/theme/          │
│  - Domain-agnostic (Buttons, Badges, Cards, Guards)    │
│  - Consumes design tokens (Colors, Spacing, Radii)     │
└────────────────────────────────────────────────────────┘
```

---

## 2. Design Tokens (`lib/app/theme/tokens.dart`)

Design tokens centralize visual primitives into compile-time constants:

```dart
abstract final class BrandColors {
  static const Color primary = Color(0xFF1E6FD9);
  static const Color secondary = Color(0xFF2AA98B);
  static const Color surface = Color(0xFFF5F7FA);
}

abstract final class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

abstract final class Radii {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double pill = 999.0;
}
```

---

## 3. UI Layer Separation Rules

1. **No Raw HTTP in Widgets**: Widgets must never invoke `http.Client` or OpenAPI clients.
2. **Dumb vs Connected Components**:
   - Leaf widgets (cards, dialogs, buttons) should accept immutable data and callbacks (`onPressed: () => ...`).
   - Screen widgets connect to Riverpod (`ref.watch()`, `ref.read()`) and pass data down.
