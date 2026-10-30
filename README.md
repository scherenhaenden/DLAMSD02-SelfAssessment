# AssessYourself (DevProfile)

Native SwiftUI self-assessment application developed for **DLAMSD02 Apple Mobile Solution Development II** at IU International University of Applied Sciences.

## Current Development Stage

Version **0.1.0** (Build `20261029.210300`), Sprint 1: Domain Core, Catalog Loader & Psychometric Scoring Engine.

### Implemented

- Domain Layer (DDD): `AssessmentDimension`, `QuestionType`, `ChoiceOption`, `AssessmentQuestion`, `ArchetypeProfile`, `AssessmentAnswer`, and `AssessmentRecord`.
- Polymorphic Interaction Support: Domain models for Single Choice, Multiple Choice (Chips), Likert Slider (1–5 continuous/discrete), and Short Text entry with minimum length constraints.
- Strict Invariant Validation: `validateInvariants()` ensures non-empty IDs, valid dimension associations, non-empty prompts, minimum 2 options for choice questions, valid slider ranges, and positive text bounds.
- Bundled Evaluation Catalog: `assessment_catalog.json` containing 24 vetted items distributed evenly across 4 core engineering dimensions (Architecture, Platform Engineering, Quality Assurance, Agile Collaboration) with 4 diagnostic archetypes.
- Local Catalog Service (`CatalogLoaderProtocol`): Resilient JSON decoding, resource bundle extraction, and integrity verification.
- Psychometric Scoring Engine (`EvaluationEngineProtocol`, `AssessmentEvaluationEngine`):
  - Normalization of all question types to a standard 0.0–100.0% scale.
  - Linear normalization for Likert sliders ($[min, max] \to [0, 100]$).
  - Additive weights for single and multiple choice selections.
  - Heuristic keyword analysis and length scoring for short-text technical reflections.
  - Dimension-level weighted aggregation and dominant archetype synthesis (`system-architect`, `platform-craftsperson`, `quality-champion`, `agile-orchestrator`).
- Test Suite: 12 XCTest unit tests passing with 100% success rate in 0.008s. Instrumented line coverage on core scoring engine: 82.12%.

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
src/Views/Components/      Atomic UI controls (Choice, Slider, Chips, Text, Color tokens)
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
| **0.2.0** | Design system, WCAG 2.1 AA/AAA adaptive color tokens, wireframes | 🟡 Next |
| **0.3.0** | Modular atomic UI components (Choice, Chips, Slider, Text) | ⚪ Planned |
| **0.4.0** | Multidimensional evaluation engine & sequential screen flow | ⚪ Planned |
| **0.5.0** | Interactive validation, transition feedback, decoupled haptics | ⚪ Planned |
| **0.6.0** | Result analytics, competency dashboard, archetype categorization | ⚪ Planned |
| **0.7.0** | Local persistence (`UserDefaultsHistoryStore`), history & progress trends | ⚪ Planned |
| **0.8.0** | Multi-device layout (iPad 640pt container), VoiceOver accessibility | ⚪ Planned |
| **0.9.0** | In-app authoring, sandbox storage, JSON/URL import with rollback | ⚪ Planned |
| **1.0.0** | Final code freeze, $\ge 80\%$ llvm-cov, UI acceptance suite, academic report | ⚪ Planned |

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
