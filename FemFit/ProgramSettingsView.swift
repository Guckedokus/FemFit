// ProgramSettingsView.swift
// FemFit – Programm-Einstellungen: Wochenplan ändern, Frequenz anpassen
// Inspiriert von Alpha Progression

import SwiftUI
import SwiftData

struct ProgramSettingsView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var cycleManager = CycleManager.shared
    
    @Bindable var program: WorkoutProgram
    
    @State private var selectedFrequency: Int
    @State private var selectedDays: [Weekday] = []
    @State private var hasChanges = false
    
    init(program: WorkoutProgram) {
        self.program = program
        _selectedFrequency = State(initialValue: program.weeklyFrequency)
        _selectedDays = State(initialValue: Array(program.scheduledDays.keys).sorted(by: { 
            Weekday.allCases.firstIndex(of: $0)! < Weekday.allCases.firstIndex(of: $1)! 
        }))
    }
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Programm-Info
                    programInfoCard
                    
                    // Frequenz anpassen
                    frequencySection
                    
                    // Wochentage zuweisen
                    weekdaySection
                    
                    // Trainingstage-Zuordnung
                    if !selectedDays.isEmpty {
                        assignmentSection
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Programm-Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
        }
    }
    
    // MARK: – Program Info Card
    
    var programInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(program.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(program.days.count) Trainingstage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(program.completedWorkouts)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(accentColor)
                    Text("Workouts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.1), accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    // MARK: – Frequency Section
    
    var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trainingshäufigkeit")
                .font(.headline)
            
            Text("Wie oft möchtest du pro Woche trainieren?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Grid 1-7x
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(1...7, id: \.self) { frequency in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFrequency = frequency
                            adjustDaysForFrequency(frequency)
                            hasChanges = true
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(frequency)x")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedFrequency == frequency
                                ? accentColor.opacity(0.15)
                                : Color(uiColor: .systemGray6)
                        )
                        .foregroundColor(selectedFrequency == frequency ? accentColor : .primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedFrequency == frequency ? accentColor : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: – Weekday Section
    
    var weekdaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trainingstage")
                .font(.headline)
            
            Text("Wähle \(selectedFrequency) Tage für dein Training")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    WeekdayToggleRow(
                        weekday: weekday,
                        isSelected: selectedDays.contains(weekday),
                        dayNumber: selectedDays.firstIndex(of: weekday).map { $0 + 1 },
                        accentColor: accentColor
                    ) {
                        toggleWeekday(weekday)
                    }
                }
            }
        }
    }
    
    // MARK: – Assignment Section
    
    var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tag-Zuordnung")
                .font(.headline)
            
            Text("Welcher Trainingstag wird an welchem Wochentag absolviert?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                ForEach(Array(selectedDays.enumerated()), id: \.offset) { index, weekday in
                    if let currentDayIndex = program.scheduledDays[weekday] {
                        AssignmentRow(
                            weekday: weekday,
                            dayNumber: index + 1,
                            selectedDayIndex: Binding(
                                get: { currentDayIndex },
                                set: { newIndex in
                                    var schedule = program.scheduledDays
                                    schedule[weekday] = newIndex
                                    program.scheduledDays = schedule
                                    hasChanges = true
                                }
                            ),
                            availableDays: program.sortedDays,
                            accentColor: accentColor
                        )
                    } else {
                        // Für neue Tage
                        AssignmentRow(
                            weekday: weekday,
                            dayNumber: index + 1,
                            selectedDayIndex: Binding(
                                get: { index % program.sortedDays.count },
                                set: { _ in }
                            ),
                            availableDays: program.sortedDays,
                            accentColor: accentColor
                        )
                    }
                }
            }
        }
    }
    
    // MARK: – Helpers
    
    func toggleWeekday(_ weekday: Weekday) {
        if let index = selectedDays.firstIndex(of: weekday) {
            selectedDays.remove(at: index)
        } else if selectedDays.count < selectedFrequency {
            selectedDays.append(weekday)
        }
        hasChanges = true
    }
    
    func adjustDaysForFrequency(_ frequency: Int) {
        if selectedDays.count > frequency {
            selectedDays = Array(selectedDays.prefix(frequency))
        } else if selectedDays.count < frequency {
            // Auto-fill mit fehlenden Tagen
            let missing = frequency - selectedDays.count
            let available = Weekday.allCases.filter { !selectedDays.contains($0) }
            selectedDays.append(contentsOf: available.prefix(missing))
        }
    }
    
    func saveChanges() {
        // Update frequency
        program.weeklyFrequency = selectedFrequency
        
        // Update schedule
        var newSchedule: [Weekday: Int] = [:]
        for (index, weekday) in selectedDays.enumerated() {
            // Verteile Trainingstage rotierend
            newSchedule[weekday] = index % program.sortedDays.count
        }
        program.scheduledDays = newSchedule
        
        // Speichern
        try? context.save()
        
        dismiss()
    }
}

// MARK: – Supporting Views

struct WeekdayToggleRow: View {
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
            .padding(14)
            .background(isSelected ? accentColor.opacity(0.1) : Color(uiColor: .systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentRow: View {
    let weekday: Weekday
    let dayNumber: Int
    @Binding var selectedDayIndex: Int
    let availableDays: [WorkoutDay]
    let accentColor: Color
    
    var body: some View {
        HStack {
            // Wochentag Badge
            Text(weekday.shortName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(accentColor)
                .cornerRadius(8)
            
            Text(weekday.displayName)
                .font(.subheadline)
            
            Spacer()
            
            // Picker für Trainingstag
            Menu {
                ForEach(Array(availableDays.enumerated()), id: \.offset) { index, day in
                    Button {
                        selectedDayIndex = index
                    } label: {
                        HStack {
                            Text(day.name)
                            if selectedDayIndex == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let day = availableDays[safe: selectedDayIndex] {
                        Text(day.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor)
                    } else {
                        Text("Wählen")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(accentColor.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

// MARK: – Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutProgram.self, configurations: config)
    let program = WorkoutProgram(name: "Push/Pull/Legs")
    program.weeklyFrequency = 3
    container.mainContext.insert(program)
    
    return ProgramSettingsView(program: program)
        .modelContainer(container)
}
