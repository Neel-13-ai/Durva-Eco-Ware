# Monorepo to Standalone Migration Matrix

## 1. Monorepo Separation Summary

The Reference Project is a multi-language pnpm monorepo containing Node.js microservices, Next.js web applications, and shared TypeScript packages.

The **Durvaeco** project is a pure, independent **Standalone Flutter Project**.

---

## 2. KEEP, REMOVE & ADAPT Breakdown

```text
Reference Monorepo (MedBuddieApps)        Standalone Project (durvaeco)
──────────────────────────────────        ─────────────────────────────
apps/mobile/lib/...                 ──►   lib/...
apps/mobile/test/...                ──►   test/...
apps/mobile/assets/...              ──►   assets/...
packages/medbuddie_api_client/...   ──►   lib/infrastructure/api/generated/...
packages/design-tokens/...          ──►   lib/app/theme/tokens.dart (Native Dart)

pnpm-workspace.yaml                 ──►   REMOVE
turbo.json                          ──►   REMOVE
package.json / pnpm-lock.yaml       ──►   REMOVE
docker-compose.yaml                 ──►   REMOVE
Node.js / TS workspace packages     ──►   REMOVE
```

| Component | Status | Transformation Details |
|---|---|---|
| 4-Layer Architecture (`lib/app`, `lib/core`, `lib/features`, `lib/infrastructure`) | **KEEP** | Copy directly into `lib/` |
| Riverpod State Management & GoRouter | **KEEP** | Copy directly; maintain provider and guard structure |
| Auth & Token Lifecycle (`SessionManager`, `AuthenticatedApiClient`) | **KEEP** | Copy directly; maintain in-memory access + secure storage refresh |
| Root `package.json`, `turbo.json`, `pnpm-workspace.yaml` | **REMOVE** | Monorepo orchestrators not needed in standalone Flutter |
| TypeScript Shared Packages (`@medbuddie/auth`, `@medbuddie/events`) | **REMOVE** | Flutter does not consume TypeScript directly |
| OpenAPI Generator Script (`scripts/generate-dart-client.sh`) | **ADAPT** | Adapt into standalone script `scripts/generate_api_client.sh` taking spec URL or local JSON |
| Design Tokens (`@medbuddie/design-tokens`) | **ADAPT** | Migrate JSON design tokens directly into `lib/app/theme/tokens.dart` |
