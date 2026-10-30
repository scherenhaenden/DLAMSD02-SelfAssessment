# AssessYourself (DevProfile)

Native SwiftUI self-assessment application developed for **DLAMSD02 Apple Mobile Solution Development II** at IU International University of Applied Sciences.

## Current Development Stage

Version **0.2.2** (Build `20261030.092800`), Sprint 2.2: Comprehensive Hardening, Complete Assessment Contract, Invariant Defense & Code Coverage ($\ge 84\%$).

### Implemented

- Domain Hardening & Verification:
  - Completeness verification: `evaluate()` strictly requires all catalog questions to be answered, throwing `EvaluationEngineError.incompleteAssessment` on partial submissions.
  - Comprehensive input payload validation: Rejects single choice without selection, multiple choice violating selection bounds, sliders missing or out of bounds, and short texts failing character length constraints.
  - Defensive catalog validation: `evaluate()` validates catalog integrity first (`try catalog.validateIntegrity()`), preventing runtime crashes from malformed external catalogs.
  - Defensive decoding: `AssessmentAnswer.init(from decoder:)` clamps deserialized scores to $[0.0, 100.0]$.
  - Extended catalog invariants: Validates non-empty IDs/labels, positive slider steps, valid slider defaults, and valid multi-select bounds.
  - Strict mathematical weak ordering: `AssessmentRecord.<` guarantees strict transitivity ($A < B \land B < C \implies A < C$).
  - Deterministic archetype tie-breaking: Canonical catalog dimension order resolves ties deterministically.
  - Resolved namespace collision: Renamed `RGBColor` to `AppRGBColor`.
- Protocol-Oriented & Injectable Theme Architecture: Clean alternative to rigid static constants via `AppThemeProtocol` and `AppTheme` value type, supporting constructor injection and SwiftUI `@Environment(\.appTheme)`.
- Mathematical WCAG 2.1 Contrast Audit (TDD): Exact relative luminance and contrast ratio formulas verified via automated XCTest suite (`ColorTokenTests`). All text tokens and 4 dimension accents achieve $\ge 4.5:1$ (AA) and up to $17.85:1$ (AAA) in Light and Dark Modes.
- Ergonomic Layout & Multi-Device Tokens: 4pt/8pt grid spacing, continuous squircle radii (8pt, 14pt, 20pt), 44pt touch targets, 56pt primary button heights, and 640pt iPad container limit.
- Comprehensive Wireframes: Detailed ASCII blueprints and flow specifications in `design/wireframes/WIREFRAMES.md` covering all 5 core screens.
- Test Suite: **40 XCTest unit tests** passing with 100% success rate in 0.019s. **84.83% global line coverage** (`AssessmentCatalog`: 91.86%, `AssessmentQuestion`: 85.81%, `AssessmentRecord`: 82.22%, `CatalogLoader`: 88.52%, `EvaluationEngine`: 82.87%, `DesignTokens`: 90.62%).

## Open and Build

The core logic, models, and presentation components are packaged as a Swift Package (`AssessYourselfCore`).

To build and execute unit tests from the terminal:

```sh
swift test
```

To run tests with instrumented code coverage (`llvm-cov`):

```sh
swift test --enable-code-coverage
```

## Source Layout

```text
Package.swift              SwiftPM definition for AssessYourselfCore and tests
src/App/                   App entry point and application lifecycle
src/Models/                Domain entities (Dimension, Question, Answer, Record, Archetype)
src/Services/              Catalog loader and evaluation engine protocols & implementations
src/ViewModels/            Reactive state management and assessment coordinators
src/Views/Components/      Atomic UI controls (Color tokens, DesignTheme, Choice, Slider)
src/Views/Screens/         Primary screens (Intro, Flow, Result, History, CatalogManager)
src/Resources/             Bundled assessment catalogs (JSON)
src/Tests/                 XCTest unit and integration test suites
design/                    Design system specifications, tokens, and wireframes
docs/                      Sprint documentation and technical verification reports
ui-tests/                  XCUITest acceptance suite for iPhone 17 & iPad 9th Gen
```

## Roadmap

| Milestone | Scope & Deliverables | Status |
| :---: | :--- | :---: |
| **0.1.0** | Domain core, Codable models, bundled catalog, scoring engine | ✅ Completed |
| **0.2.0** | Design system, WCAG 2.1 AA/AAA adaptive color tokens, wireframes | ✅ Completed |
| **0.2.1** | Domain hardening, catalog invariants, transitive ordering, tie-breaking | ✅ Completed |
| **0.2.2** | Completeness contract, payload validation, $\ge 84\%$ coverage, ADR matrices | ✅ Completed |
| **0.3.0** | Modular atomic UI components (Choice, Chips, Slider, Text) | 🟡 Next |
| **0.4.0** | Multidimensional evaluation engine & sequential screen flow | ⚪ Planned |
| **0.5.0** | Interactive validation, transition feedback, decoupled haptics | ⚪ Planned |
| **0.6.0** | Result analytics, competency dashboard, archetype categorization | ⚪ Planned |
| **0.7.0** | Local persistence (`UserDefaultsHistoryStore`), history & progress trends | ⚪ Planned |
| **0.8.0** | Multi-device layout (iPad 640pt container), VoiceOver accessibility | ⚪ Planned |
| **0.9.0** | In-app authoring, sandbox storage, JSON/URL import with rollback | ⚪ Planned |
| **1.0.0** | Final code freeze, $\ge 80\%$ llvm-cov, UI acceptance suite, academic report | ⚪ Planned |

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
