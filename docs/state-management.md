# State Management Architecture (Riverpod)

## 1. Philosophy: Single, Deliberate Choice

Durvaeco uses **Riverpod** (`flutter_riverpod: ^2.6.1`) as its sole, deliberate state management and dependency injection engine. Riverpod provides:
- Compile-time safety (no runtime `ProviderNotFoundException`).
- Automatic lifecycle management (`autoDispose`, `onDispose`).
- Effortless testing via `ProviderScope(overrides: [...])`.
- Decoupling of business logic from the widget tree.

---

## 2. Provider Taxonomy

| Provider Type | Usage Scenario | Real Code Example |
|---|---|---|
| `Provider<T>` | Singletons, services, repositories, and stateless utilities | `appConfigProvider`, `authRepositoryProvider`, `authorizationServiceProvider` |
| `StateNotifierProvider<Notifier, State>` | Complex UI state machines, forms, auth sessions, and mutative workflows | `authControllerProvider`, `communityBrowseControllerProvider` |
| `FutureProvider<T>` | Async data feeds, dashboard queries, and cached data | `healthProvider`, `medicationsDashboardProvider` |
| `Provider.family<T, Param>` | Parameterized services or scoped sub-authorization | `communityAuthorizationProvider(memberRole)` |

---

## 3. Canonical StateNotifier Pattern

```dart
// 1. Immutable State Class
class CommunityBrowseState {
  const CommunityBrowseState({
    this.isLoading = false,
    this.communities = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<CommunityDto> communities;
  final String? errorMessage;

  CommunityBrowseState copyWith({
    bool? isLoading,
    List<CommunityDto>? communities,
    String? errorMessage,
  }) {
    return CommunityBrowseState(
      isLoading: isLoading ?? this.isLoading,
      communities: communities ?? this.communities,
      errorMessage: errorMessage,
    );
  }
}

// 2. StateNotifier Controller
class CommunityBrowseController extends StateNotifier<CommunityBrowseState> {
  CommunityBrowseController(this._repository) : super(const CommunityBrowseState()) {
    fetchCommunities();
  }

  final CommunityRepository _repository;

  Future<void> fetchCommunities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getCommunities();
    if (!mounted) return;
    result.when(
      success: (list) => state = state.copyWith(isLoading: false, communities: list),
      failure: (err) => state = state.copyWith(isLoading: false, errorMessage: err.message),
    );
  }
}

// 3. Provider Declaration
final communityBrowseControllerProvider =
    StateNotifierProvider.autoDispose<CommunityBrowseController, CommunityBrowseState>((ref) {
  return CommunityBrowseController(ref.watch(communityRepositoryProvider));
});
```
