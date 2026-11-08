# AssessYourself (DevProfile)

Native SwiftUI self-assessment application developed for **DLAMSD02 Apple Mobile Solution Development II** at IU International University of Applied Sciences.

## Current Development Stage

Version **0.7.1** (Build `20261108.140000`), Sprint 7 Patch Released: Persistent History Resilience, Save-Failure UI Banner with Retry, Strict Version Compatibility & Date-Tie Ordering, Explicit Corruption Recovery & 111/111 Tests.

### Implemented

- **Protocol-Oriented State & ViewModel Architecture (POP / MVVM):**
  - Zero static singletons: Pure dependency injection via initializers and SwiftUI Environment.
  - `AssessmentViewModelProtocol`: Contract defining session state machine, navigation affordances, answer recording, evaluation coordination, `hapticService`, and persistence error / retry capabilities (`persistenceError`, `retryPersistence()`).
  - `AssessmentViewModel`: Conforms to `ObservableObject` with `@Published` state properties, managing 24 questions across 4 dimensions (*Architecture*, *Platform*, *Quality*, *Agile*), maintaining `[String: AnswerPayload]`, duration tracking, resilient error handling (surfacing persistence errors via `persistenceError` without losing evaluated record, with `retryPersistence()`), and haptic coordination. Planned future evolution path: `@Observable` / `@MainActor` (Swift 5.9+).
  - Deterministic state machine: `AssessmentSessionState` (`.idle`, `.loading`, `.inProgress`, `.completed(AssessmentRecord)`, `.error(String)`).
- **Sequential Assessment Flow & Validation Gating:**
  - `AssessmentQuestionContainerView`: Polymorphic SwiftUI container dynamically hosting `ChoiceOptionButton`, `MultiSelectChipGrid`, `LikertSliderCard`, or `ShortTextPromptCard` based on question type.
  - `AssessmentFlowView`: Full navigation screen with top progress bar (`ProgressView(value: viewModel.progress)`), question counter pill (`Frage N / 24`), dimension badge, and bottom navigation toolbar.
  - Strict validation gating: "Zurück" disabled on question 1; "Weiter" and "Abschließen" strictly gated by `isCurrentAnswerValid`.
  - State persistence during traversal: Navigating back preserves previous user inputs without data loss.
- **Sprint 7 History Persistence, Temporal Progression & Resilience (`v0.7.0` & `v0.7.1`):**
  - *Decoupled Local Store (`HistoryStoreProtocol` & `UserDefaultsHistoryStore`):* Thread-safe (`NSLock`) local persistence using `UserDefaults` and `Codable` JSON serialization with defensive error handling (`HistoryStoreError.corruptedData` thrown without silently wiping user data).
  - *Pure FIFO Retention Policy:* Strict capacity ceiling of **50 records** ordered chronologically descending by `completedAt` (newest first) and `id.uuidString` descending for total ordering, ensuring predictable, score-independent eviction.
  - *Idempotent Persistence:* Saving records by unique `record.id` updates existing entries without duplication.
  - *Save Failure Resilience:* Visible warning banner in `AssessmentResultView` if saving fails, allowing immediate retry (`retryPersistence()`) without losing evaluated results.
  - *Strict Version Compatibility & Missing Dimension Handling:* SemVer major version matching (`areVersionsCompatible`) and defensive nil-handling for unmapped dimensions (no arbitrary zero defaults).
  - *Acyclic Date-Tie Comparator:* Strict total order comparator in `findPreviousCompatibleRecord` preventing mutual or circular previous record references on identical timestamps.
  - *Explicit Corruption Recovery:* User-confirmed reset dialog ("Beschädigten Verlauf zurücksetzen") allowing users to clear unparseable historical storage explicitly without automatic silent data loss.
  - *Temporal Comparison Service (`HistoryComparisonService`):* Calculates progress deltas between successive compatible assessment runs expressed in percentage points (`pp` / *Prozentpunkte*, e.g., `+5.0 pp`, `-2.5 pp`, `0.0 pp`) for overall score and per-dimension competencies.
  - *Ergonomic History Dashboard (`HistoryView`):* Chronological log displaying date, duration, dominant archetype badges, overall scores, dynamic dimension rendering (`record.dimensionScores.keys`), progress deltas, empty state illustration, and clear-history action with confirmation dialog. Max-width constraint (640 pt) for iPad ergonomics.
  - *Automatic Persistence Integration:* `AssessmentViewModel` auto-saves completed assessment records into `historyStore` upon successful submission with tactile error/warning notification and non-blocking recovery banner.
- **Sprint 6 Result Analytics & Competency Dashboard (`v0.6.0` & `v0.6.1`):**
  - *Dominant Archetype Presentation (`ArchetypeCardView`):* Diagnostic card showcasing evaluated archetype profile (`ArchetypeProfile`), prominent SF Symbol badge, title, subtitle, comprehensive description, categorized key strengths with checkmark indicators, and growth opportunities. Represents the user's relative dominant profile among the evaluated dimensions.
  - *Graphical Competency Dashboard (`DimensionScoreBarView`):* Adaptive horizontal progress bars for all 4 dimensions (*Architecture*, *Platform*, *Quality*, *Agile*) with exact percentage formatting (`%.1f %%`), semantic dimension color tokens, VoiceOver accessibility elements (`dimensionBar.<id>`), and full `accessibilityReduceMotion` animation suppression.
  - *Didactic Learning Recommendations (`PedagogicalRecommendationsView`):* Scoring-derived pedagogical recommendations prioritized by dimension scores (*Hohe Priorität*, *Empfohlen*, *Vertiefung*), providing structured learning guidance aligned with IU DLAMSD02 module themes. Employs a mathematically transitive quantized comparator and deterministic tie-breaker hierarchy (`canonicalDimensionPrecedence: [architecture: 0, platform: 1, quality: 2, agile: 3]` with fallback).
  - *Integrated Result Screen (`AssessmentResultView`):* Unified assessment summary featuring celebration hero header, formatted duration tracking (`X Min. Y Sek.`), archetype card, dynamic dimension counter (`\(dimensionsToDisplay.count) Dimensionen`), multi-dimensional bar dashboard, recommendations, persistence warning banner with retry action, and terminal restart button *"Assessment wiederholen"* (`flow.resetButton`) inside the `ScrollView` to prevent safe-area clipping on compact viewports.
- **Sprint 5 Multisensory Feedback, Haptics & Accessibility (`v0.5.3`):**
  - *Decoupled Haptic Service (`HapticFeedbackServiceProtocol`):* Pure Swift protocol abstracting tactile feedback with `SystemHapticFeedbackService` (retained generators, thread-safe `stateLock` + `generatorLock`, TSan-verified against concurrent reads/writes with 200,000 iterations probe, pre-warming lifecycle, and crash-free execution across iOS, iPadOS, Catalyst, and Simulator) and deterministic `MockHapticFeedbackService` spy.
  - *Strict Dependency Injection Precedence:* Designated initializer injection (`hasExplicitHapticService: true`) takes absolute precedence over SwiftUI Environment fallback, guaranteeing that explicitly disabled services (`isEnabled: false`) or mock configurations are preserved across view lifecycles (`onAppear`).
  - *Interaction Haptic Triggers:* Selection ticks on choice options, multiple choice chips, and slider updates; light impact on navigation; medium impact on session reset; success/error notifications on assessment completion.
  - *Adaptive Reduce Motion Support:* `TactileButtonStyle` suppresses decorative scaling (`scaleEffect(1.0)`) and disables animations when `accessibilityReduceMotion` is active, maintaining subtle opacity change for confirmation. `AssessmentFlowView` suppresses spring/ease motion and transitions using standard opacity.
  - *Tactile Button Feedback (`TactileButtonStyle`):* Native responsive touch compression (`scaleEffect(0.98)`) and subtle dimming (`0.92`) across all primary action buttons.
  - *Audit Remediation Baseline:* Welcome screen retention until explicit start tap, WCAG AAA adaptive dark mode contrast (`onAccent`), robust UIKit test host measurement without fallback masking, and full 24-question end-to-end traversal.
- **Root Application Navigation:**
  - `AssessYourselfApp`: Triple-tab entry point connecting `AssessmentFlowView` as primary assessment experience (`tab.assessmentFlow`), `HistoryView` (`tab.history`), and `ComponentShowcaseView` (`tab.showcase`).
- **Test Suite & Code Coverage:**
  - **104 SwiftPM unit tests** passing on macOS 14 (`swift test`, `arm64e-apple-macos14.0`, 0 failures, 0 warnings, version `v0.7.1`), including 17 comprehensive tests in `HistoryStoreTests.swift` covering roundtrip persistence, idempotency, chronological sorting descending, FIFO 50 pruning, defensive error handling on corrupted data, thread-safety under concurrent load, percentage-point comparison math, acyclic date-tie breaking, version compatibility, dynamic dimension rendering, and UI hosting lifecycle verification.
  - **7 XCUITest integration tests** (`ui-tests/AssessYourselfUITests.swift`) passing on iPhone 17 Simulator (`iOS 27.0`), verifying end-to-end traversal, dimension bars, score headers, reset affordances, history navigation & state transitions, and UI interactions (**111/111 native tests passed**).
  - *Archived Baseline Audit (v0.6.0, commit `8bb5c3a`, iPhone 17 Simulator runtime `iOS 27.0` / macOS 14):* **83 unit tests** (`audit-unit.log:231`, `audit-native.log:1189`) + **6 XCUITest UI tests**, totaling **89/89 passed native tests** (`audit-native-summary.json`).
  - *Coverage Baseline (v0.6.0 audit, commit `8bb5c3a`):* **94.37% line coverage on macOS** (`llvm-cov report`: 4,847 / 5,136 lines in 24 `src` production files, `audit-macos-coverage.json`), with $\ge 82.22\%$ on every production source file (`PedagogicalRecommendationsView.swift`: 99.70%; 100% on `ArchetypeCardView`, `DimensionScoreBarView`, `AssessmentResultView`, `TactileButtonStyle`, `HapticFeedbackService`).
  - *iOS Coverage Baseline (v0.6.0 audit, commit `8bb5c3a`):* **96.46% line coverage on native iOS target sources** (5,173 / 5,363 lines in 25 files, `audit-ios-coverage.json`).

## Open and Build

The project supports both standalone SwiftPM workflows and native Xcode Simulator builds.

### SwiftPM Tests & Coverage
```sh
swift test
swift test --enable-code-coverage
```

### Xcode Simulator Build & UI Tests
```sh
# Build application for iPhone 17 Simulator
xcodebuild -project AssessYourself.xcodeproj -scheme AssessYourself \
  -destination "platform=iOS Simulator,name=iPhone 17" build

# Run XCUITest interaction suite
xcodebuild -project AssessYourself.xcodeproj -scheme AssessYourself \
  -destination "platform=iOS Simulator,name=iPhone 17" test \
  -only-testing:AssessYourselfUITests
```

## Source Layout

```text
Package.swift              SwiftPM definition for AssessYourselfCore and tests
AssessYourself.xcodeproj   Native Xcode project for iOS application, tests & UI tests
ui-tests/                  XCUITest interaction test suite (AssessYourselfUITests.swift)
scripts/                   Tooling scripts (project generation)
src/App/                   App entry point (AssessYourselfApp.swift)
src/Models/                Domain entities (Dimension, Question, Answer, Record, Archetype)
src/Services/              Catalog loader and evaluation engine protocols & implementations
src/ViewModels/            Reactive state management and assessment coordinators
src/Views/Components/      Atomic UI controls (Choice, MultiSelect, Slider, ShortText, DesignTokens)
src/Views/Screens/         Primary screens (AssessmentFlowView, AssessmentQuestionContainerView, ComponentShowcaseView)
src/Resources/             Bundled assessment catalogs (JSON, 24 questions across 4 dimensions)
src/Tests/                 XCTest unit and integration test suites
design/                    Design system specifications, tokens, and wireframes
docs/                      Sprint documentation and technical verification reports
```

## Roadmap

| Milestone | Scope & Deliverables | Status |
| :---: | :--- | :---: |
| **0.1.0** | Domain core, Codable models, bundled catalog, scoring engine | ✅ Completed |
| **0.2.0** | Design system, WCAG 2.1 AA/AAA adaptive color tokens, wireframes | ✅ Completed |
| **0.2.1** | Domain hardening, catalog invariants, transitive ordering, tie-breaking | ✅ Completed |
| **0.2.2** | Completeness contract, payload validation, $\ge 84\%$ coverage, ADR matrices | ✅ Completed |
| **0.3.0** | Modular atomic UI components (Choice, Chips, Slider, Text), native iOS App target | ✅ Completed |
| **0.3.1** | UI interaction tests (XCUITest), a11y & contrast hardening, $\ge 80\%$ coverage per file | ✅ Completed |
| **0.3.2** | Verified XCUITest state assertions, slider delta, empty/typed text, closing Sprint 3 | ✅ Completed |
| **0.3.3** | Placeholder visibility on iOS (`scrollContentBackground`), strict equality text assertions | ✅ Completed |
| **0.4.0** | AssessmentViewModel, sequential navigation flow & question coordinator | ✅ Completed |
| **0.4.1** | Flow hardening, boundary enforcement, slider auto-sync & full paradigm XCUITest | ✅ Completed |
| **0.5.0** | Welcome retention, WCAG AAA dark contrast, 24-Q XCUITest suite | ✅ Completed |
| **0.5.1** | Multisensory feedback engine, decoupled haptics & tactile button styling | ✅ Completed |
| **0.5.2** | TSan thread safety, Reduce Motion adaptation, host sizing fix | ✅ Completed |
| **0.5.3** | Strict DI precedence, mock lifecycle verification, zero-fallback host sizing | ✅ Completed |
| **0.6.0** | Result analytics, competency dashboard, archetype categorization | ✅ Completed |
| **0.6.1** | Deterministic tie-breaker, transitive quantized comparator, dashboard UI test assertions | ✅ Completed |
| **0.7.0** | Local persistence (`UserDefaultsHistoryStore`), history & progress trends | 🟡 Next |
| **0.8.0** | Multi-device layout (iPad 640pt container), VoiceOver accessibility | ⚪ Planned |
| **0.9.0** | In-app authoring, sandbox storage, JSON/URL import with rollback | ⚪ Planned |
| **1.0.0** | Final code freeze, $\ge 80\%$ llvm-cov, UI acceptance suite, academic report | ⚪ Planned |

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
