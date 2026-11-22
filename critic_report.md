# Stage 7 Review Report: Critic Review

**Target:** `docs/designs/api_routes_standardization_plan.md` (FeatureRange: Lines 1–78)  
**Reviewers:** `egm-design` (Design Critic), `egm-structural` (Structural Validator), `egm-style` (Copy Editor)  
**Date:** 2026-11-22  

---

## Prioritized Findings

### 🔴 Blocker: Idempotency Breakdown & Dangerous Auto-Retry on POST Operations
* **Reviewer:** `egm-design`
* **Affected Scope:** Lines 16–18, 27, 45–46, 53–54, 70–71
* **Discrepancy Description:** `PUT` and `DELETE` are idempotent per RFC 9110, while `POST` is non-idempotent. In `NativeHttpClient` (`api_client.dart`), all failed requests undergo an automatic 3-attempt retry loop on `SocketException`. If a network connection drops after the server processes a `POST /update/{id}` or `POST /delete/{id}` (e.g. inventory adjustments, payments, production stage entries), `NativeHttpClient` will resubmit the `POST` payload, risking duplicate operations or state corruption.
* **Proposed Action:** Mandate that `NativeHttpClient` restricts automatic retries to idempotent HTTP methods (`GET`, `HEAD`, `OPTIONS`) or document safety requirements for `POST` actions.

---

### 🔴 Blocker: Critical Security Policy — Standardizing Insecure TLS Certificate Bypass
* **Reviewer:** `egm-design`
* **Affected Scope:** Lines 60–65, 74–76
* **Discrepancy Description:** Elevating `ApiClient` to the standardized production transport engine without gating `badCertificateCallback = ((cert, host, port) => true)` behind `kDebugMode` leaves enterprise credentials and tokens vulnerable to MITM attacks.
* **Proposed Action:** Update the specification in Section 2 to mandate that `badCertificateCallback` is strictly restricted to `kDebugMode` and that production builds enforce standard TLS verification.

---

### 🟡 Major: Structural Asymmetry & Missing Component Breakdown
* **Reviewer:** `egm-structural`
* **Affected Scope:** Lines 41–76 (Section 2)
* **Discrepancy Description:** The architecture diagram presents a three-tier model (1: `ApiEndpoints`, 2: `Repositories`, 3: `ApiClient & AuthenticatedApiClient`), but the subsections skip Repositories entirely and misnumber `ApiClient` as Component 2. Section 2.2 is also under-specified as a single generic sentence.
* **Proposed Action:** Restructure Section 2 into three symmetrical subsections: `2.1 ApiEndpoints`, `2.2 Repositories`, and `2.3 Transport Layer (ApiClient & AuthenticatedApiClient)`.

---

### 🟡 Major: Semantic Contradiction & Vague Jargon ("Transparent", "Pure")
* **Reviewer:** `egm-style`
* **Affected Scope:** Lines 1, 21, 28, 52, 60, 75
* **Discrepancy Description:** The term "transparent" is used in opposing senses (hidden runtime rewriting vs explicit observable code). The term "pure" is subjective and technically inaccurate for an I/O client.
* **Proposed Action:** Rename title to "Explicit HTTP Architecture", replace "pure" with "decoupled/direct", and calibrate all evaluative adjectives.

---

### 🟡 Major: Unencoded Path Parameter Injection in `ApiEndpoints`
* **Reviewer:** `egm-design`
* **Affected Scope:** Lines 45–46, 70–71
* **Discrepancy Description:** `ApiEndpoints.update` and `delete` perform raw string interpolation of `id` (`$endpoint/update/$id`). Non-integer entity identifiers (such as sequence codes like `PO/2026/001`) with slashes or reserved characters cause route truncation or 404 mismatches.
* **Proposed Action:** Enforce URI component encoding: `Uri.encodeComponent(id.toString())`.

---

### 🟡 Major: Architectural Conflation of `ApiClient` vs `AuthenticatedApiClient`
* **Reviewer:** `egm-design`
* **Affected Scope:** Lines 60–65, 74–76
* **Discrepancy Description:** The diagram claims `ApiClient` injects Bearer tokens and handles 401 refreshes, but this is solely implemented in `AuthenticatedApiClient`. Conflating them obscures component boundaries.
* **Proposed Action:** Formally separate `ApiClient` (base transport) and `AuthenticatedApiClient` (session middleware) in Section 2.

---

### 🟡 Major: Protocol Mismatch — Empty Body Handling on `POST /delete/{id}`
* **Reviewer:** `egm-design`
* **Affected Scope:** Lines 18, 54, 75, 86
* **Discrepancy Description:** Issuing `POST` with `Content-Type: application/json` and `body: null` (length 0) triggers `400 Bad Request` or `411 Length Required` on ASP.NET Core controllers and reverse proxies.
* **Proposed Action:** Specify that `ApiClient` omits `Content-Type` when `body == null`, or standardize on sending `{}`.
