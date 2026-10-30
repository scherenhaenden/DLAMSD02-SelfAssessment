# AssessYourself Screen Wireframes & Interaction Specifications

> **Module:** DLAMSD02 – Apple Mobile Solution Development II  
> **Author:** Edward Sergio José Flores Mogollón (4236756)  
> **Document Purpose:** Visual screen blueprints and interactive state diagrams for the *Projektbericht* (Kapitel 2 & 4).

---

## 1. Overview of Core Application Screens

The application comprises 5 primary views connected through declarative SwiftUI navigation:

```text
┌─────────────────────────────────────────────────────────────┐
│                          HomeView                           │
│     (Hero Banner, Target Dimensions, Test Kickoff)         │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
      [Start Assessment]              [History / Manage]
               │                              │
               ▼                              ▼
┌─────────────────────────────┐  ┌─────────────────────────────┐
│     AssessmentFlowView      │  │        HistoryView /        │
│  (Step 1..24, Polymorphic)  │  │     CatalogManagerView      │
└──────────────┬──────────────┘  └─────────────────────────────┘
               │
        [Finish & Score]
               │
               ▼
┌─────────────────────────────┐
│     AssessmentResultView    │
│ (Dominant Profile & Charts) │
└─────────────────────────────┘
```

---

## 2. Screen 1: HomeView (Einleitender Screen mit Zielsetzung)

*Required by IU Aufgabenstellung p. 2: "Die App zeigt einen einleitenden Screen mit der Zielsetzung des Tests an."*

```text
┌─────────────────────────────────────────────────────────────┐
│ ⚙️ [Catalog]                             AssessYourself  🕒 [History] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  DevProfile: Software Engineering Readiness         │   │
│   │                                                     │   │
│   │  Diagnostiziere Deine ingenieurmäßigen Kern-        │   │
│   │  kompetenzen in 4 Schlüsselbereichen des Apple-     │   │
│   │  und Software-Engineerings.                         │   │
│   │                                                     │   │
│   │  ⏱️ 24 Fragen  ·  ca. 8-10 Min  ·  Ohne Zeitdruck    │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   EVALUIERTE DIMENSIONEN                                    │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ [🏛️] Architecture & System Design      (6 Fragen)   │   │
│   │ [🍎] Swift & Apple Platform Engineering (6 Fragen)   │   │
│   │ [🛡️] Quality Assurance & Verification  (6 Fragen)   │   │
│   │ [👥] Agile Practices & Collaboration    (6 Fragen)   │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │            🚀 Assessment starten (56 pt)            │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Screen 2: AssessmentFlowView (Polymorphe Fragesequenz)

*Required by IU Aufgabenstellung p. 2: "Die App durchläuft mehrere, aufeinanderfolgende Screens zur Beantwortung von Fragen... Schieberegler, Kurzantworten als Texteingabe".*

### 3.1. Header & Navigation Controls (Shared across all question types)

```text
┌─────────────────────────────────────────────────────────────┐
│  [< Zurück]               Frage 7 von 24            [Abbrechen] │
│  ██████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ (29%)     │
├─────────────────────────────────────────────────────────────┤
│  DIMENSION: Software Architecture & System Design           │
```

### 3.2. Polymorphic Interaction Body (4 Types)

#### Type A: Single Choice (`singleChoice`)
```text
│  Wie strukturierst Du Geschäftslogik in SwiftUI?            │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ (•) MVVM mit reaktivem ViewModel (@Observable)        │  │
│  │     Strikte Trennung, vollständig ohne UI testbar.    │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ( ) Logik direkt im View-Body und @State              │  │
│  │     Schnell für Prototypen, erschwert Tests.          │  │
│  └───────────────────────────────────────────────────────┘  │
```

#### Type B: Multiple Choice Chips (`multipleChoice`)
```text
│  Welche Architekturprinzipien wendest Du aktiv an?          │
│                                                             │
│  [  Single Responsibility  ✓ ]  [ Dependency Inversion ✓ ]  │
│  [  Defensive Invariants   ✓ ]  [ Entkoppelte Persistenz ]  │
│                                                             │
│  Mindestens 1, maximal 4 Optionen auswählen.                │
```

#### Type C: Likert Rating Slider (`likertSlider`)
```text
│  Ich refaktorisiere Dateien mit > 250 Zeilen proaktiv.      │
│                                                             │
│  Wert: [ 4 / 5 ]  ·  "Stimme eher zu"                       │
│                                                             │
│  1 ─────── 2 ─────── 3 ─────── 4 ─────── 5                  │
│  (Stimme gar                   (Stimme voll                 │
│   nicht zu)                     und ganz zu)                │
```

#### Type D: Short Text Entry (`shortText`)
```text
│  Beschreibe ein Beispiel für erfolgreiche Entkopplung:      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Durch die Einführung des CatalogLoaderProtocol        │  │
│  │ konnten wir Tests ohne echte Dateien ausführen...     │  │
│  │                                                       │  │
│  │                                 74 / 350 Zeichen (✓)  │  │
│  └───────────────────────────────────────────────────────┘  │
```

### 3.3. Action Footer
```text
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Weiter -> (56 pt)                  │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Screen 3: AssessmentResultView (Ergebnis & Kategorisierung)

*Required by IU Aufgabenstellung p. 2: "Das Testergebnis wird angezeigt... Kategorisierung der zu testenden Person".*

```text
┌─────────────────────────────────────────────────────────────┐
│                                                   [Fertig]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   DEIN ENTWICKLER-ARCHETYP                                  │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  🏛️ Systems & Software Architect                   │   │
│   │                                                     │   │
│   │  Starke Ausprägung in modularem Denken, Entwurfs-   │   │
│   │  mustern und sauberer Schichtentrennung.            │   │
│   │                                                     │   │
│   │  Gesamtreife: 84.5%  ·  Exzellente Fundierung       │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   KOMPETENZ-PROFIL NACH DIMENSIONEN                         │
│   Architecture:  ████████████████████░░░░  88.3% (Stärke)   │
│   Platform:      ████████████████░░░░░░░░  76.5%            │
│   Quality:       █████████████████████░░░  91.2% (Spitze)   │
│   Agile:         █████████████████░░░░░░░  82.0%            │
│                                                             │
│   DIDAKTISCHE EMPFEHLUNGEN                                  │
│   • Erhöhe die UI-Testautomatisierung (XCUITest) auf iPad   │
│   • Dokumentiere Architekturentscheidungen als ADRs         │
│                                                             │
│   ┌───────────────────────────┐ ┌───────────────────────┐   │
│   │ 🔄 Test wiederholen       │ │ 💾 Im Verlauf sichern │   │
│   └───────────────────────────┘ └───────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Screen 4: HistoryView (Verlauf & Trendvergleich)

```text
┌─────────────────────────────────────────────────────────────┐
│  Schließen                     Verlauf           [Löschen]  │
├─────────────────────────────────────────────────────────────┤
│  HISTORIE ABSOLVIERTER ASSESSMENTS                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 30. Okt 2026 · 09:15 Uhr                 Score: 84% │   │
│  │ Archetyp: Systems & Software Architect              │   │
│  │ Trend: +12% gegenüber Vormonat (▲)                  │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 15. Sep 2026 · 14:20 Uhr                 Score: 72% │   │
│  │ Archetyp: Agile Engineering Orchestrator            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Screen 5: CatalogManagerView (In-App Autorenschaft & Import)

*Creative Extension conforming to ADR-09.*

```text
┌─────────────────────────────────────────────────────────────┐
│  Schließen              Kataloge & Fragen                   │
├─────────────────────────────────────────────────────────────┤
│  [ Eigene Fragen ]     [ JSON-Import ]     [ URL-Download ] │
│                                                             │
│  SANDBOX-KATALOG                                            │
│  Persistiert in: Application Support/AssessYourself/        │
│  Status: Intakt (Backup .bak synchronisiert ✓)              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [+] Neue Frage zu Dimension hinzufügen              │   │
│  │     Typ: Likert-Slider, Single-Choice, etc.          │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📥 Externen JSON-Katalog importieren                 │   │
│  │    Mit automatischem transaktionalem Rollback       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```
