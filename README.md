# AssessYourself (DevProfile)

Native SwiftUI self-assessment application developed for **DLAMSD02 Apple Mobile Solution Development II** at IU International University of Applied Sciences.

## Current Development Stage

Version **0.3.3** (Build `20261030.121500`), Sprint 3.3: Final Closure Milestone, Verified Placeholder Rendering & Strict Text Lifecycle.

### Implemented

- **Verified XCUITest Acceptance Suite (Codex Audit Round 5 Resolved):**
  - Live simulator execution of 3 UI integration tests (`AssessYourselfUITests`) with explicit state and counter assertions after every single tap.
  - Stepped slider: Verifies initial `4 / 5` ("Eher hoch") and dynamic transition to `1 / 5` ("Sehr niedrig") after dragging to 0.0.
  - Short text reflection: Verifies visible placeholder in empty initial state (`shortTextPlaceholder`), exact typed text equality (`Praxiseinsatz mit SwiftUI.`), placeholder disappearance upon typing, exact counter (`26 von maximal 250 Zeichen`), and unconditional transition to `Mindestumfang erfüllt`.
  - Zero compiler warnings in XCUITest target (`chipSwiftPM` fully integrated into bidirectional toggle assertions).
- **Barrierefreiheit & Kontrast-Härtung (WCAG AA):**
  - `ShortTextPromptCard`: Inset placeholder uses unattenuated `textSecondary` token, achieving **7.58 : 1** (Light) and **5.71 : 1** (Dark) contrast against card surface.
  - `scrollContentBackground(.hidden)` enabled across all platforms, ensuring placeholder visibility on iOS/iPadOS behind transparent `TextEditor`.
  - VoiceOver accessibility attributes added to `TextEditor` (`accessibilityLabel`, `accessibilityHint`, live character counter values).
  - `MultiSelectChipGrid`: Dynamic-Type resilient adaptive layout (`GridItem(.adaptive(minimum: 140))`) with multi-line expansion without clipping. Touch targets $\ge 48\,\text{pt}$ height.
- **Atomic SwiftUI Components:**
  - `ChoiceOptionButton`: Radio selection with $\ge 56\,\text{pt}$ touch targets, dimension-accented borders, and VoiceOver state hints.
  - `MultiSelectChipGrid`: Adaptive grid, dynamic selection bounds feedback (`min/max`), $\ge 48\,\text{pt}$ touch targets.
  - `LikertSliderCard`: 1-to-5 discrete stepped slider with verbal anchors and `.accessibilityAdjustableAction`.
  - `ShortTextPromptCard`: Inset `TextEditor` with placeholder, live character counter, and 3-stage validation borders.
- **Component Showcase & App Target:**
  - `ComponentShowcaseView`: Interactive screen composing all 4 components with reactive `@State` and injected theme.
  - Native `AssessYourself.xcodeproj`: Configured iOS Application executable target (`com.scherenhaenden.AssessYourself`, iOS 17.0, iPhone & iPad `TARGETED_DEVICE_FAMILY = "1,2"`).
  - Simulator Verification: Successfully built, deployed, and launched on booted iPhone 17 and iPad (9th generation) simulators with Light & Dark mode screenshot evidence in `docs/screenshots/`.
- **Test Suite & Code Coverage:**
  - **51 XCTest unit tests** passing with 100% success rate across SwiftPM.
  - **3 XCUITest integration tests** passing with 100% success rate on iOS Simulator.
  - **93.15% global line coverage** (`llvm-cov report`), with **$\ge 82.22\%$ on every individual source file**.

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
src/Views/Screens/         Primary screens (ComponentShowcaseView, etc.)
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
| **0.4.0** | AssessmentViewModel, sequential navigation flow & question coordinator | 🟡 Next |
| **0.5.0** | Interactive validation, transition feedback, decoupled haptics | ⚪ Planned |
| **0.6.0** | Result analytics, competency dashboard, archetype categorization | ⚪ Planned |
| **0.7.0** | Local persistence (`UserDefaultsHistoryStore`), history & progress trends | ⚪ Planned |
| **0.8.0** | Multi-device layout (iPad 640pt container), VoiceOver accessibility | ⚪ Planned |
| **0.9.0** | In-app authoring, sandbox storage, JSON/URL import with rollback | ⚪ Planned |
| **1.0.0** | Final code freeze, $\ge 80\%$ llvm-cov, UI acceptance suite, academic report | ⚪ Planned |

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
