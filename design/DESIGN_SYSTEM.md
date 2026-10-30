# AssessYourself Design System & WCAG 2.1 Accessibility Specification

> **Module:** DLAMSD02 – Apple Mobile Solution Development II  
> **Target Platforms:** iOS 17+, iPadOS 17+ (iPhone 17, iPad 9th Gen 10.2")  
> **Design Paradigm:** Human Interface Guidelines (HIG) with Declarative SwiftUI Tokens  
> **Compliance:** WCAG 2.1 Level AA ($\ge 4.5:1$) & Level AAA ($\ge 7.0:1$)

---

## 1. Visual Hierarchy & Mathematical Color System

To guarantee accessibility for all users, colors are defined as adaptive token pairs (`AdaptiveColorToken`) that automatically adjust based on the current system appearance (`Light` vs. `Dark` Mode).

### 1.1. Relative Luminance & Contrast Ratio Formulas (W3C Standard)

Relative luminance $L$ in sRGB color space is defined as:

$$c_{\text{linear}} = \begin{cases} \frac{c}{12{,}92} & \text{für } c \le 0{,}04045 \\ \left(\frac{c + 0{,}055}{1{,}055}\right)^{2{,}4} & \text{für } c > 0{,}04045 \end{cases}$$

$$L = 0{,}2126 \cdot R_{\text{linear}} + 0{,}7152 \cdot G_{\text{linear}} + 0{,}0722 \cdot B_{\text{linear}}$$

The contrast ratio $CR$ between two relative luminances $L_1$ and $L_2$ (with $L_1 \ge L_2$) is calculated as:

$$CR = \frac{L_1 + 0{,}05}{L_2 + 0{,}05}$$

### 1.2. Audited Semantic Tokens & Measured Contrast Ratios

| Token Name | Light Mode Hex | Dark Mode Hex | Baseline Surface | Contrast Light | Contrast Dark | WCAG 2.1 Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`textPrimary`** | `#0F172A` | `#F8FAFC` | Surface Card | **17.85 : 1** | **13.98 : 1** | 🟢 **AAA Pass** ($\ge 7.0:1$) |
| **`textSecondary`** | `#475569` | `#94A3B8` | Surface Card | **7.58 : 1** | **5.71 : 1** | 🟢 **AA/AAA Pass** ($\ge 4.5:1$) |
| **`successFeedback`** | `#14532D` | `#4ADE80` | Surface Card | **9.11 : 1** | **8.40 : 1** | 🟢 **AAA Pass** ($\ge 7.0:1$) |
| **`warningFeedback`** | `#854D0E` | `#FACC15` | Surface Card | **6.85 : 1** | **9.55 : 1** | 🟢 **AA/AAA Pass** ($\ge 4.5:1$) |
| **`errorFeedback`** | `#991B1B` | `#F87171` | Surface Card | **8.31 : 1** | **5.29 : 1** | 🟢 **AA/AAA Pass** ($\ge 4.5:1$) |

### 1.3. Dimension Accent Colors

Each of the four engineering evaluation dimensions has its dedicated semantic color token:

| Dimension ID | Dimension Name | Light Hex | Dark Hex | Contrast on Surface | Role |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **`architecture`** | Software Architecture & System Design | `#1E3A8A` | `#38BDF8` | **10.36 : 1** (L, AAA) / **6.83 : 1** (D, AA) | Structural integrity, modularity, diagrams |
| **`platform`** | Swift & Apple Platform Engineering | `#581C87` | `#C084FC` | **10.88 : 1** (L, AAA) / **5.54 : 1** (D, AA) | Native Swift, HIG idioms, platform APIs |
| **`quality`** | Quality Assurance & Verification | `#14532D` | `#4ADE80` | **9.11 : 1** (L, AAA) / **8.40 : 1** (D, AAA) | Testing, coverage, boundary invariants |
| **`agile`** | Agile Practices & Collaboration | `#9A3412` | `#FBBF24` | **7.31 : 1** (L, AAA) / **8.76 : 1** (D, AAA) | Sprints, DoD, documentation, Git |

---

## 2. Spacing Grid & Layout Dimensions

Following Apple HIG, layouts are built on a consistent 4 pt base unit:

```text
Spacing.xs =  4 pt   (Inner padding between small badges and icons)
Spacing.sm =  8 pt   (Stack separation for related label pairs)
Spacing.md = 16 pt   (Standard padding around interactive cards)
Spacing.lg = 24 pt   (Major section separation)
Spacing.xl = 32 pt   (Hero headers and bottom action bar offsets)
```

### 2.1. Continuous Corner Radii (Apple Squircles)
* **`CornerRadius.small` (8 pt):** Tags, chips, dimension pills, and rank badges.
* **`CornerRadius.medium` (14 pt):** Interactive answer buttons, option cards, slider containers.
* **`CornerRadius.large` (20 pt):** Primary surface cards, modal sheet headers, result scorecards.

### 2.2. Ergonomics & Multi-Device Standards
* **Minimum Touch Target:** $\ge 44 \times 44\,\text{pt}$ (strict adherence to HIG).
* **Primary Interactive Button Height:** $\ge 56\,\text{pt}$ with full-width centered bounding box for thumb accessibility.
* **iPadOS Regular Size Class Container:** Centered width capped at **640 pt** on iPad (9th generation, 10.2") in both Portrait and Landscape to avoid visual line dispersal (maintaining 50–75 characters per line).

---

## 3. Atomic Assessment UI Components

In Sprint 3 (`v0.3.0`), the four foundational atomic input components were developed in SwiftUI, encapsulating the four question modalities with strict adherence to the Design System tokens and HIG accessibility:

### 3.1. ChoiceOptionButton (Single Choice)
* **Purpose:** Mutually exclusive option selection with immediate visual and tactile feedback.
* **Visual States:**
  * *Unselected:* Card surface fill (`surfaceCard`), subtle 1 pt border (`textSecondary` at 20% opacity), hollow circle indicator (`circle`).
  * *Selected:* Dimension-accented 2 pt continuous squircle border, subtle dimension tint fill (12% opacity), filled radio indicator (`largecircle.fill.circle`).
* **Ergonomics & Accessibility:**
  * Height $\ge 56\,\text{pt}$ with vertical thumb-friendly padding.
  * Traits: `.isButton`, conditionally `.isSelected`.
  * Dynamic Accessibility Hint: *"Selected. Double tap to change selection."* vs. *"Not selected. Double tap to select."*

### 3.2. MultiSelectChipGrid (Multiple Choice)
* **Purpose:** Multi-selection within defined minimum and maximum selection constraints.
* **Layout:**
  * 2-column adaptive grid (`LazyVGrid`) with flexible column width ($\ge 140\,\text{pt}$).
  * Interactive chips with touch targets $\ge 44 \times 44\,\text{pt}$.
* **Live Constraint Feedback:**
  * Selection counter pill showing `selected/max`.
  * Status text adapting dynamically:
    * Exact quota ($min = max$): *"Wähle genau X Optionen"*
    * Bounded range ($min > 1$): *"Wähle zwischen X und Y Optionen"*
    * Standard: *"Mehrfachauswahl (maximal Y)"*
  * Semantic color transition: `warningFeedback` when below minimum or exceeding maximum; dimension accent when within valid range.

### 3.3. LikertSliderCard (Stepped Slider)
* **Purpose:** Standardized rating scale (1.0 to 5.0) for self-efficacy evaluation.
* **Visual Structure:**
  * Value badge header featuring an accented score pill (e.g. `Wert: 4.0 / 5.0`).
  * Verbal anchor row rendering textual indicators (e.g. *"Stimme überhaupt nicht zu"* $\leftrightarrow$ *"Stimme voll und ganz zu"*).
  * Native stepped `Slider` styled with dimension accent color.
* **Accessibility:**
  * Supports `.accessibilityAdjustableAction` for increment/decrement gestures by configured step size.
  * VoiceOver reads: *"Slider, value X of Y, step Z"*.

### 3.4. ShortTextPromptCard (Reflective Text)
* **Purpose:** Qualitative free-text self-reflection with live boundary supervision.
* **Visual Structure:**
  * Inset `TextEditor` with custom placeholder overlay that disappears upon user input.
  * Live character count with three semantic states:
    1. *Below minimum:* Displays remaining characters needed with subtle warning tone.
    2. *Valid range ($min \le len \le max$):* Displays character count with `successFeedback` border and badge.
    3. *Exceeded maximum:* Displays excess character count with `errorFeedback` border and negative milestone marker.
* **Ergonomics:**
  * Fixed comfortable height (140 pt) preventing abrupt layout shifts during typing.
  * Dismiss keyboard affordance and explicit VoiceOver character status announcement.
