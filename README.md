# AssessYourself (DevProfile)

Native SwiftUI self-assessment application developed for **DLAMSD02 Apple Mobile Solution Development II** at IU International University of Applied Sciences.

## Current Development Stage

Version **0.5.1** (Build `20261104.090000`), Sprint 5 Completed: Multisensory Feedback Engine, Decoupled Haptics, Tactile Button Styling & 70-Test Suite.

### Implemented

- **Protocol-Oriented State & ViewModel Architecture (POP / MVVM):**
  - Zero static singletons: Pure dependency injection via initializers and SwiftUI Environment.
  - `AssessmentViewModelProtocol`: Contract defining session state machine, navigation affordances, answer recording, and evaluation coordination.
  - `AssessmentViewModel`: `@ObservableObject` managing 24 questions across 4 dimensions (*Architecture*, *Platform*, *Quality*, *Agile*), maintaining `[String: AnswerPayload]`, duration tracking, and error handling.
  - Deterministic state machine: `AssessmentSessionState` (`.idle`, `.loading`, `.inProgress`, `.completed(AssessmentRecord)`, `.error(String)`).
- **Sequential Assessment Flow & Validation Gating:**
  - `AssessmentQuestionContainerView`: Polymorphic SwiftUI container dynamically hosting `ChoiceOptionButton`, `MultiSelectChipGrid`, `LikertSliderCard`, or `ShortTextPromptCard` based on question type.
  - `AssessmentFlowView`: Full navigation screen with top progress bar (`ProgressView(value: viewModel.progress)`), question counter pill (`Frage N / 24`), dimension badge, and bottom sticky navigation toolbar.
  - Strict validation gating: "Zurück" disabled on question 1; "Weiter" and "Abschließen" strictly gated by `isCurrentAnswerValid`.
  - State persistence during traversal: Navigating back preserves previous user inputs without data loss.
- **Sprint 5 Multisensory Feedback & Haptics Engine (`v0.5.1`):**
  - *Decoupled Haptic Service (`HapticFeedbackServiceProtocol`):* Pure Swift protocol abstracting tactile feedback with `SystemHapticFeedbackService` (retained generators, `NSLock` thread safety, pre-warming lifecycle, and crash-free execution on iPad/macOS/Simulator) and deterministic `MockHapticFeedbackService` spy.
  - *Interaction Haptic Triggers:* Selection ticks on choice options, multiple choice chips, and slider updates; light impact on navigation; medium impact on session reset; success/error notifications on assessment completion.
  - *Tactile Button Feedback (`TactileButtonStyle`):* Native responsive touch compression (`scaleEffect(0.98)`) and subtle dimming (`0.92`) across all primary action buttons.
  - *Fluid Animations:* Dynamic spring progress bar animations and smooth dimension transitions.
  - *Audit Remediation Baseline:* Welcome screen retention, WCAG AAA adaptive dark mode contrast (`onAccent`), and full 24-question end-to-end traversal.
- **Root Application Navigation:**
  - `AssessYourselfApp`: Dual-tab entry point connecting `AssessmentFlowView` as primary assessment experience alongside `ComponentShowcaseView`.
- **Test Suite & Code Coverage:**
  - **70 XCTest unit tests** passing with 100% success rate across SwiftPM.
  - **6 XCUITest integration tests** passing with 100% success rate on iPhone 17 Simulator (`testCompleteFull24QuestionAssessmentFlowAndVerifyCompletion`, `testWelcomeScreenRemainsVisibleUntilStartTapped`, `testSequentialAssessmentFlowProgressionAndValidation`, `testSingleChoiceMutualExclusionInteraction`, `testMultipleChoiceBoundsAndToggleInteraction`, `testLikertSliderAndShortTextInputInteraction`).
  - **92.86% global line coverage** (`llvm-cov report`: 3,501 / 3,770 lines), with **$\ge 82.22\%$ on every individual source file**.

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
| **0.6.0** | Result analytics, competency dashboard, archetype categorization | 🟡 Next |
| **0.7.0** | Local persistence (`UserDefaultsHistoryStore`), history & progress trends | ⚪ Planned |
| **0.8.0** | Multi-device layout (iPad 640pt container), VoiceOver accessibility | ⚪ Planned |
| **0.9.0** | In-app authoring, sandbox storage, JSON/URL import with rollback | ⚪ Planned |
| **1.0.0** | Final code freeze, $\ge 80\%$ llvm-cov, UI acceptance suite, academic report | ⚪ Planned |

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
