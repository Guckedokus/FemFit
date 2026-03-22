// PlanGeneratorView.swift
// FemFit – Intelligenter Trainingsplan-Generator
// Inspiriert von Alpha Progression, aber mit Zyklus-Integration!

import SwiftUI
import SwiftData

struct PlanGeneratorView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var cycleManager = CycleManager.shared
    
    @State private var selectedFrequency: Int = 3  // 3x pro Woche Standard
    @State private var selectedProgramType: ProgramType = .pushPullLegs
    @State private var currentStep: GeneratorStep = .frequency
    @State private var selectedDays: [Weekday] = []
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Steps
                progressSteps
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .frequency:
                            frequencyStep
                        case .programType:
                            programTypeStep
                        case .schedule:
                            scheduleStep
                        case .summary:
                            summaryStep
                        }
                    }
                    .padding()
                }
                
                // Bottom Button
                VStack(spacing: 12) {
                    if currentStep != .frequency {
                        Button {
                            withAnimation {
                                currentStep = currentStep.previous()
                            }
                        } label: {
                            Text("Zurück")
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color(uiColor: .systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(14)
                        }
                    }
                    
                    Button {
                        handleNext()
                    } label: {
                        HStack {
                            Image(systemName: currentStep == .summary ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            Text(currentStep == .summary ? "Plan erstellen" : "Weiter")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!canProceed)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Plan-Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: – Progress Steps
    
    var progressSteps: some View {
        HStack(spacing: 8) {
            ForEach(GeneratorStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    if step != .summary {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: step == .summary ? 8 : .infinity)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
    }
    
    // MARK: – Step 1: Frequency
    
    var frequencyStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Wie oft möchtest du trainieren?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Wähle die Anzahl der Trainingstage pro Woche")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Grid mit 1x-7x
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(1...7, id: \.self) { frequency in
                    FrequencyCard(
                        frequency: frequency,
                        isSelected: selectedFrequency == frequency,
                        accentColor: accentColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFrequency = frequency
                            // Auto-assign days
                            selectedDays = autoAssignDays(for: frequency)
                        }
                    }
                }
            }
            
            // Empfehlung
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Empfohlen: 3-4x pro Woche für optimale Ergebnisse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: – Step 2: Program Type
    
    var programTypeStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Welchen Plan-Typ?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Wähle einen Trainingsplan, der zu deiner Frequenz passt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Program Types
            ForEach(ProgramType.allCases.filter { $0.isCompatible(with: selectedFrequency) }, id: \.self) { type in
                ProgramTypeCard(
                    type: type,
                    isSelected: selectedProgramType == type,
                    accentColor: accentColor
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedProgramType = type
                    }
                }
            }
        }
    }
    
    // MARK: – Step 3: Schedule
    
    var scheduleStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Wann möchtest du trainieren?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Wähle \(selectedFrequency) Tage für dein Training")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Wochentage
            VStack(spacing: 12) {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    WeekdaySelectionRow(
                        weekday: weekday,
                        isSelected: selectedDays.contains(weekday),
                        dayNumber: selectedDays.firstIndex(of: weekday).map { $0 + 1 },
                        accentColor: accentColor
                    ) {
                        toggleWeekday(weekday)
                    }
                }
            }
            
            // Zyklus-Tipp
            if cycleManager.isInPeriod {
                HStack(spacing: 8) {
                    Text("🌸")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zyklus-Tipp")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Während der Periode: Plane leichtere Tage am Anfang des Zyklus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(hex: "#E84393").opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: – Step 4: Summary
    
    var summaryStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Dein Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Überprüfe deinen Trainingsplan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Summary Cards
            VStack(spacing: 16) {
                SummaryRow(icon: "calendar", title: "Trainingshäufigkeit", value: "\(selectedFrequency)x pro Woche")
                SummaryRow(icon: "list.bullet.clipboard", title: "Plan-Typ", value: selectedProgramType.name)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(accentColor)
                        Text("Trainingstage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ForEach(Array(selectedDays.enumerated()), id: \.offset) { index, weekday in
                        HStack {
                            Text(weekday.displayName)
                                .font(.subheadline)
                            Spacer()
                            Text(selectedProgramType.dayName(for: index))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(12)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: – Helpers
    
    var canProceed: Bool {
        switch currentStep {
        case .frequency:
            return selectedFrequency > 0
        case .programType:
            return true
        case .schedule:
            return selectedDays.count == selectedFrequency
        case .summary:
            return true
        }
    }
    
    func handleNext() {
        if currentStep == .summary {
            createProgram()
        } else {
            withAnimation {
                currentStep = currentStep.next()
            }
        }
    }
    
    func toggleWeekday(_ weekday: Weekday) {
        if let index = selectedDays.firstIndex(of: weekday) {
            selectedDays.remove(at: index)
        } else if selectedDays.count < selectedFrequency {
            selectedDays.append(weekday)
        }
    }
    
    func autoAssignDays(for frequency: Int) -> [Weekday] {
        // Intelligente Standard-Verteilung
        let suggestions: [[Weekday]] = [
            [], // 0
            [.monday], // 1x
            [.monday, .thursday], // 2x
            [.monday, .wednesday, .friday], // 3x - KLASSISCH!
            [.monday, .tuesday, .thursday, .friday], // 4x
            [.monday, .tuesday, .wednesday, .thursday, .friday], // 5x
            [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday], // 6x
            Weekday.allCases // 7x
        ]
        return suggestions[safe: frequency] ?? []
    }
    
    func createProgram() {
        // Erstelle Programm
        let program = WorkoutProgram(name: selectedProgramType.name)
        program.weeklyFrequency = selectedFrequency
        context.insert(program)
        
        // Erstelle Trainingstage basierend auf Typ
        for (index, dayName) in selectedProgramType.dayNames.enumerated() {
            let day = WorkoutDay(name: dayName, order: index)
            day.program = program
            context.insert(day)
        }
        
        // Speichere Wochenplan
        var schedule: [Weekday: Int] = [:]
        for (index, weekday) in selectedDays.enumerated() {
            schedule[weekday] = index % selectedProgramType.dayNames.count
        }
        program.scheduledDays = schedule
        
        // Speichern
        try? context.save()
        
        dismiss()
    }
}

// MARK: – Generator Step Enum

enum GeneratorStep: Int, CaseIterable {
    case frequency = 0
    case programType = 1
    case schedule = 2
    case summary = 3
    
    func next() -> GeneratorStep {
        GeneratorStep(rawValue: rawValue + 1) ?? self
    }
    
    func previous() -> GeneratorStep {
        GeneratorStep(rawValue: rawValue - 1) ?? self
    }
}

// MARK: – Program Type Enum

enum ProgramType: String, CaseIterable {
    case fullBody = "full_body"
    case upperLower = "upper_lower"
    case pushPullLegs = "push_pull_legs"
    case bro_split = "bro_split"
    
    var name: String {
        switch self {
        case .fullBody: return "Ganzkörper"
        case .upperLower: return "OK/UK Split"
        case .pushPullLegs: return "Push/Pull/Legs"
        case .bro_split: return "Bro Split"
        }
    }
    
    var description: String {
        switch self {
        case .fullBody: return "Trainiere den ganzen Körper in jeder Einheit"
        case .upperLower: return "Wechsel zwischen Oberkörper und Unterkörper"
        case .pushPullLegs: return "Push (Drück), Pull (Zieh), Beine"
        case .bro_split: return "Jeder Tag ein anderer Muskel"
        }
    }
    
    var dayNames: [String] {
        switch self {
        case .fullBody:
            return ["Ganzkörper A", "Ganzkörper B"]
        case .upperLower:
            return ["Oberkörper", "Unterkörper"]
        case .pushPullLegs:
            return ["Push", "Pull", "Legs"]
        case .bro_split:
            return ["Brust", "Rücken", "Beine", "Schultern", "Arme"]
        }
    }
    
    func dayName(for index: Int) -> String {
        dayNames[index % dayNames.count]
    }
    
    var recommendedFrequency: ClosedRange<Int> {
        switch self {
        case .fullBody: return 2...3
        case .upperLower: return 4...4
        case .pushPullLegs: return 3...6
        case .bro_split: return 5...6
        }
    }
    
    func isCompatible(with frequency: Int) -> Bool {
        recommendedFrequency.contains(frequency) || frequency >= 3
    }
    
    var emoji: String {
        switch self {
        case .fullBody: return "💪"
        case .upperLower: return "🔄"
        case .pushPullLegs: return "🎯"
        case .bro_split: return "🏋️"
        }
    }
}

// MARK: – Supporting Views

struct FrequencyCard: View {
    let frequency: Int
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(frequency)x")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? accentColor : .primary)
                Text("pro Woche")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    : LinearGradient(
                        colors: [Color(uiColor: .systemGray6), Color(uiColor: .systemGray6)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProgramTypeCard: View {
    let type: ProgramType
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(type.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(accentColor)
                }
            }
            .padding(16)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    : LinearGradient(
                        colors: [Color(uiColor: .systemGray6), Color(uiColor: .systemGray6)],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WeekdaySelectionRow: View {
    let weekday: Weekday
    let isSelected: Bool
    let dayNumber: Int?
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(weekday.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? accentColor : .primary)
                
                Spacer()
                
                if let number = dayNumber {
                    Text("Tag \(number)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.15))
                        .cornerRadius(8)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding(16)
            .background(isSelected ? accentColor.opacity(0.1) : Color(uiColor: .systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(16)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

// MARK: – Preview

#Preview {
    PlanGeneratorView()
}
