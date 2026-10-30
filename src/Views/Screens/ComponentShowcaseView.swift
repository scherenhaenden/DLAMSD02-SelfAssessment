import SwiftUI

/// An interactive showcase view displaying all atomic assessment components in a single scrollable container.
public struct ComponentShowcaseView: View {
    @Environment(\.appTheme) private var theme

    // Interactive state for Single Choice
    @State private var selectedSingleChoiceId: String? = "sc-opt-1"

    // Interactive state for Multiple Choice
    @State private var selectedMultiChoiceIds: Set<String> = ["mc-opt-1", "mc-opt-2"]

    // Interactive state for Slider
    @State private var sliderValue: Double = 4.0

    // Interactive state for Short Text (initially empty to demonstrate placeholder and milestone transitions)
    @State private var reflectionText: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header Card
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Sprint 3 Component Showcase")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary.color)
                        Text("Interaktive Validierung der vier Fragetypen mit responsivem Design und VoiceOver-Semantik.")
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary.color)
                    }
                    .padding(.bottom, theme.spacing.sm)

                    // Section 1: Single Choice
                    sectionHeader(title: "1. Single Choice Component", dimensionId: "architecture")
                    VStack(spacing: theme.spacing.sm) {
                        ChoiceOptionButton(
                            option: ChoiceOption(id: "sc-opt-1", title: "Clean Architecture mit strikt entkoppelten Domain Services", scoreWeight: 100.0),
                            isSelected: selectedSingleChoiceId == "sc-opt-1",
                            dimensionId: "architecture",
                            onSelect: { selectedSingleChoiceId = "sc-opt-1" }
                        )

                        ChoiceOptionButton(
                            option: ChoiceOption(id: "sc-opt-2", title: "Monolithische View Controller mit implizitem Zustand", scoreWeight: 20.0),
                            isSelected: selectedSingleChoiceId == "sc-opt-2",
                            dimensionId: "architecture",
                            onSelect: { selectedSingleChoiceId = "sc-opt-2" }
                        )
                    }

                    // Section 2: Multiple Choice Chips
                    sectionHeader(title: "2. Multiple Choice Chip Grid", dimensionId: "platform")
                    MultiSelectChipGrid(
                        options: [
                            ChoiceOption(id: "mc-opt-1", title: "SwiftUI", scoreWeight: 30.0),
                            ChoiceOption(id: "mc-opt-2", title: "SwiftPM", scoreWeight: 30.0),
                            ChoiceOption(id: "mc-opt-3", title: "XCTest", scoreWeight: 20.0),
                            ChoiceOption(id: "mc-opt-4", title: "Instruments", scoreWeight: 20.0)
                        ],
                        selectedIds: selectedMultiChoiceIds,
                        minSelectCount: 1,
                        maxSelectCount: 3,
                        dimensionId: "platform",
                        onToggle: { id in
                            if selectedMultiChoiceIds.contains(id) {
                                selectedMultiChoiceIds.remove(id)
                            } else if selectedMultiChoiceIds.count < 3 {
                                selectedMultiChoiceIds.insert(id)
                            }
                        }
                    )

                    // Section 3: Likert Slider Card
                    sectionHeader(title: "3. Likert Slider Card (1 bis 5)", dimensionId: "quality")
                    LikertSliderCard(
                        value: sliderValue,
                        minVal: 1.0,
                        maxVal: 5.0,
                        step: 1.0,
                        minLabel: "Stimme überhaupt nicht zu",
                        maxLabel: "Stimme voll und ganz zu",
                        dimensionId: "quality",
                        onValueChange: { sliderValue = $0 }
                    )

                    // Section 4: Short Text Prompt Card
                    sectionHeader(title: "4. Short Text Reflection Card", dimensionId: "agile")
                    ShortTextPromptCard(
                        text: reflectionText,
                        minCharacters: 15,
                        maxCharacters: 250,
                        placeholder: "Beschreibe hier deine Praxiserfahrungen...",
                        dimensionId: "agile",
                        onTextChange: { reflectionText = $0 }
                    )
                }
                .padding(theme.spacing.md)
                .frame(maxWidth: theme.layout.maxContentWidthiPad)
                .frame(maxWidth: .infinity)
            }
            .background(theme.colors.background.color.ignoresSafeArea())
            .navigationTitle("AssessYourself UI")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func sectionHeader(title: String, dimensionId: String) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(theme.colorToken(forDimension: dimensionId).color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary.color)
        }
    }
}
