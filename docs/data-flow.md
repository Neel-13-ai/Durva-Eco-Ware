# End-to-End Data Flow Architecture

## 1. Query Data Flow (GET Request)

```text
┌────────────────┐
│ UI / Screen    │ (1) User opens screen -> invokes ref.watch(itemsProvider)
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ StateNotifier  │ (2) Checks state, sets isLoading: true, calls repository
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Repository     │ (3) Calls ApiClient.invokeAPI("GET /items")
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Authenticated- │ (4) Attaches Bearer JWT & Platform Headers -> Sends HTTP
│ ApiClient      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Backend API    │ (5) Responds with 200 OK + JSON Payload
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Repository     │ (6) Deserializes JSON -> Domain Models -> Returns Success(models)
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ StateNotifier  │ (7) Updates state with new models & isLoading: false
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ UI / Screen    │ (8) Widget re-renders reactively with fresh data
└────────────────┘
```

---

## 2. Mutation Data Flow (POST / PUT Request)

```text
┌────────────────┐
│ UI / Screen    │ (1) User taps "Save" -> calls ref.read(controller.notifier).save(form)
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ StateNotifier  │ (2) Sets isSubmitting: true -> calls repository.createItem(...)
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Repository     │ (3) Validates DTO -> invokes API Client -> Returns Result<Item>
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Authenticated- │ (4) Handles 401 token refresh if needed -> completes request
│ ApiClient      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ StateNotifier  │ (5) Receives Success(item) -> updates list -> isSubmitting: false
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ UI / Screen    │ (6) Shows success Snackbar / navigates to detail screen
└────────────────┘
```
