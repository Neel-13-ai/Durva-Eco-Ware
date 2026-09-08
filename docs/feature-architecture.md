# Feature Architecture & Canonical Template

## 1. Feature Module Anatomy

Every business feature in Durvaeco is organized as a self-contained vertical slice under `lib/features/<feature_name>/`:

```text
lib/features/<feature_name>/
├── application/             # State management, StateNotifiers & Providers
│   ├── <feature>_controller.dart
│   └── <feature>_providers.dart
├── data/                    # Repositories & API clients
│   └── <feature>_repository.dart
├── domain/                  # Models, DTO extensions & value objects
│   └── <feature>_models.dart
└── presentation/            # UI layer
    ├── screens/             # Route target screens
    │   ├── <feature>_screen.dart
    │   └── <feature>_detail_screen.dart
    └── widgets/             # Feature-specific subcomponents
        ├── <feature>_card.dart
        └── <feature>_filter_dialog.dart
```

---

## 2. Canonical Feature Blueprint Template

Use this canonical template whenever creating a new feature module:

### Step 1: Define Domain Model (`domain/item_model.dart`)
```dart
class ItemModel {
  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
}
```

### Step 2: Implement Data Repository (`data/item_repository.dart`)
```dart
import 'package:medbuddie_api_client/api.dart';
import '../../../core/error/failure.dart';
import '../../../core/result/result.dart';
import '../domain/item_model.dart';

class ItemRepository {
  const ItemRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<Result<List<ItemModel>>> fetchItems() async {
    try {
      // Perform API call using generated client
      return const Success([]);
    } on ApiException catch (e) {
      return Err(ServerFailure(e.code, e.message ?? 'Server error'));
    } on Object catch (_) {
      return const Err(NetworkFailure());
    }
  }
}
```

### Step 3: Implement StateNotifier Controller (`application/item_controller.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/item_repository.dart';
import '../domain/item_model.dart';

class ItemState {
  const ItemState({this.isLoading = false, this.items = const [], this.errorMessage});
  final bool isLoading;
  final List<ItemModel> items;
  final String? errorMessage;
}

class ItemController extends StateNotifier<ItemState> {
  ItemController(this._repository) : super(const ItemState()) {
    loadItems();
  }

  final ItemRepository _repository;

  Future<void> loadItems() async {
    state = ItemState(isLoading: true, items: state.items);
    final result = await _repository.fetchItems();
    result.when(
      success: (items) => state = ItemState(items: items),
      failure: (failure) => state = ItemState(errorMessage: failure.message),
    );
  }
}
```

### Step 4: Declare Providers (`application/item_providers.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/item_repository.dart';
import 'item_controller.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(authenticatedApiClientProvider));
});

final itemControllerProvider =
    StateNotifierProvider.autoDispose<ItemController, ItemState>((ref) {
  return ItemController(ref.watch(itemRepositoryProvider));
});
```

### Step 5: Build Screen Widget (`presentation/screens/item_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/item_providers.dart';

class ItemScreen extends ConsumerWidget {
  const ItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemControllerProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.errorMessage != null) {
      return Scaffold(body: Center(child: Text(state.errorMessage!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return ListTile(title: Text(item.title));
        },
      ),
    );
  }
}
```
