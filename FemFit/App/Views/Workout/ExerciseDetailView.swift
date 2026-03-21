// ExerciseDetailView.swift
// FemFit – Hier werden Sätze eingetragen
// Einfügen in Xcode: File > New > File > Swift File > "ExerciseDetailView"

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {

    @Bindable var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    // Eingabe-Felder
    @State private var weightInput  = ""
    @State private var repsInput    = ""
    @State private var noteInput    = ""
    @State private var savedBanner  = false
    @State private var showTimer    = false
    @State private var lastSetNumber = 0
    @State private var showSkipConfirmation = false
    @State private var showFinishHint = false
    @State private var skipTarget: Exercise? = nil  // ← NEU: für programmatische Navigation nach Skip

    var isInPeriod: Bool { cycleManager.isInPeriod }
    var accentColor: Color { isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75") }
    
    // Navigation zu nächster/vorheriger Übung
    var nextExercise: Exercise? {
        guard let day = exercise.day else { return nil }
        let sorted = day.sortedExercises
        guard let currentIndex = sorted.firstIndex(where: { $0.id == exercise.id }) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < sorted.count ? sorted[nextIndex] : nil
    }
    
    var previousExercise: Exercise? {
        guard let day = exercise.day else { return nil }
        let sorted = day.sortedExercises
        guard let currentIndex = sorted.firstIndex(where: { $0.id == exercise.id }) else { return nil }
        return currentIndex > 0 ? sorted[currentIndex - 1] : nil
    }
    
    var isLastExercise: Bool {
        nextExercise == nil
    }
    
    var progress: Double {
        guard exercise.targetSets > 0 else { return 0 }
        return min(1.0, Double(todaySets.count) / Double(exercise.targetSets))
    }

    // Heutige Sätze (aktueller Modus)
    var todaySets: [WorkoutSet] {
        let today = Calendar.current.startOfDay(for: .now)
        return (isInPeriod ? exercise.periodSets : exercise.normalSets)
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    // Alle vergangenen Sätze (aktueller Modus) für Verlauf
    var historySets: [WorkoutSet] {
        let today = Calendar.current.startOfDay(for: .now)
        return (isInPeriod ? exercise.periodSets : exercise.normalSets)
            .filter { Calendar.current.startOfDay(for: $0.date) != today }
            .sorted { $0.date > $1.date }
    }

    // Letztes Gewicht als Vorschlag (NEU: phasenbasiert)
    var suggestedWeight: String {
        let currentPhase = cycleManager.currentPhase
        
        // Versuche: Gewicht aus aktueller Phase
        if let phaseWeight = exercise.suggestedWeight(for: currentPhase) {
            return String(format: "%.1f", phaseWeight)
        }
        
        // Fallback: Legacy-System
        if let last = exercise.lastWeight(period: isInPeriod) {
            return String(format: "%.1f", last)
        }
        
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Fortschrittsanzeige ──
                progressCard
                
                // ── Quick-Actions ──
                quickActionsRow

                // ── Modus-Badge ──
                modeBadge

                // ── Eingabe-Karte ──
                inputCard

                // ── Heutige Sätze ──
                if !todaySets.isEmpty {
                    todaySection
                }

                // ── Vergleich Normal vs Periode ──
                comparisonCard

                // ── Verlauf ──
                if !historySets.isEmpty {
                    historySection
                }
                
                // ── Navigation-Buttons unten ──
                bottomNavigationButtons

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Vorherige Übung
            ToolbarItem(placement: .topBarLeading) {
                if let prev = previousExercise {
                    NavigationLink(destination: ExerciseDetailView(exercise: prev)) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Zurück")
                        }
                        .font(.subheadline)
                        .foregroundColor(accentColor)
                    }
                }
            }
            
            // Nächste Übung / Fertig
            ToolbarItem(placement: .topBarTrailing) {
                if let next = nextExercise {
                    NavigationLink(destination: ExerciseDetailView(exercise: next)) {
                        HStack(spacing: 4) {
                            Text("Weiter")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                    }
                } else {
                    Button {
                        if progress >= 1.0 {
                            dismiss()
                        } else {
                            showFinishHint = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Fertig")
                            Image(systemName: "checkmark")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .alert("Übung überspringen?", isPresented: $showSkipConfirmation) {
            Button("Überspringen", role: .none) {
                if let next = nextExercise {
                    skipTarget = next          // ← FIX: State setzen statt direkt navigieren
                } else {
                    dismiss()
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Du hast erst \(todaySets.count) von \(exercise.targetSets) Sätzen gemacht.")
        }
        .alert("Noch nicht ganz fertig!", isPresented: $showFinishHint) {
            Button("Trotzdem beenden", role: .none) {
                dismiss()
            }
            Button("Weitermachen", role: .cancel) { }
        } message: {
            Text("Du hast \(todaySets.count) von \(exercise.targetSets) Sätzen geschafft. Möchtest du wirklich aufhören?")
        }
        // ← FIX: Navigation nach Skip
        .navigationDestination(item: $skipTarget) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .onAppear {
            weightInput = suggestedWeight
            repsInput   = exercise.lastReps(period: isInPeriod).map(String.init) ?? ""
        }
        .onChange(of: isInPeriod) { _, _ in
            weightInput = suggestedWeight
            repsInput   = exercise.lastReps(period: isInPeriod).map(String.init) ?? ""
        }
        .overlay {
            if showTimer {
                RestTimerView(isShowing: $showTimer, setNumber: lastSetNumber)
                    .transition(.opacity)
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Fortschritts-Card
    // ───────────────────────────────────────────
    
    var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Satz \(todaySets.count) von \(exercise.targetSets)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(progress >= 1.0 ? "Geschafft! 🎉" : "Weiter so! 💪")
                        .font(.caption)
                        .foregroundColor(progress >= 1.0 ? .green : .secondary)
                }
                Spacer()
                
                // Kreisförmiger Fortschritt
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 50, height: 50)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }
            }
            
            // Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.1), accentColor.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    // ───────────────────────────────────────────
    // MARK: – Quick Actions
    // ───────────────────────────────────────────
    
    var quickActionsRow: some View {
        HStack(spacing: 12) {
            // Letztes Gewicht übernehmen
            if let lastWeight = exercise.lastWeight(period: isInPeriod),
               let lastReps = exercise.lastReps(period: isInPeriod) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        weightInput = String(format: "%.1f", lastWeight)
                        repsInput = "\(lastReps)"
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Letztes Mal")
                                .font(.caption2)
                                .fontWeight(.medium)
                            Text("\(String(format: "%.1f", lastWeight)) kg · \(lastReps) Wdh")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            // +5kg / +2.5kg Quick Buttons
            HStack(spacing: 6) {
                quickWeightButton("+2.5kg", value: 2.5)
                quickWeightButton("+5kg", value: 5.0)
            }
        }
    }
    
    func quickWeightButton(_ label: String, value: Double) -> some View {
        Button {
            if let current = Double(weightInput) {
                weightInput = String(format: "%.1f", current + value)
            } else if let suggested = Double(suggestedWeight) {
                weightInput = String(format: "%.1f", suggested + value)
            }
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.15))
                .cornerRadius(8)
        }
    }
    
    // ───────────────────────────────────────────
    // MARK: – Bottom Navigation Buttons
    // ───────────────────────────────────────────
    
    var bottomNavigationButtons: some View {
        HStack(spacing: 12) {
            // Zurück zur vorherigen Übung
            if let prev = previousExercise {
                NavigationLink(destination: ExerciseDetailView(exercise: prev)) {
                    HStack {
                        Image(systemName: "chevron.left.circle.fill")
                        Text("Zurück")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(uiColor: UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            
            // Weiter zur nächsten / Fertig
            if let next = nextExercise {
                NavigationLink(destination: ExerciseDetailView(exercise: next)) {
                    HStack {
                        Text("Nächste Übung")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Button {
                    if progress >= 1.0 {
                        dismiss()
                    } else {
                        showFinishHint = true
                    }
                } label: {
                    HStack {
                        Text("Training fertig")
                            .fontWeight(.bold)
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Modus-Badge
    // ───────────────────────────────────────────

    var modeBadge: some View {
        VStack(spacing: 8) {
            // Aktuelle Phase mit Info
            HStack(spacing: 12) {
                // Phase-Badge
                HStack(spacing: 8) {
                    Text(cycleManager.currentPhase.emoji)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cycleManager.currentPhase.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(cycleManager.currentPhase.shortDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Gewichts-Multiplikator
                VStack(spacing: 2) {
                    Text("\(Int(cycleManager.currentPhase.weightMultiplier * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(cycleManager.currentPhase.color)
                    Text("Gewichte")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(cycleManager.currentPhase.color.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        cycleManager.currentPhase.color.opacity(0.15),
                        cycleManager.currentPhase.color.opacity(0.05)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cycleManager.currentPhase.color.opacity(0.3), lineWidth: 1.5)
            )
            
            // Legacy Badge (falls jemand manuell umschaltet)
            if isInPeriod != (cycleManager.currentPhase == .menstruation) {
                Text("⚠️ Manuell: \(isInPeriod ? "🌸 Perioden-Gewichte" : "💪 Normal-Gewichte")")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Eingabe-Karte
    // ───────────────────────────────────────────

    var inputCard: some View {
        VStack(spacing: 16) {

            Text("Satz \(todaySets.count + 1) eintragen")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // Gewicht
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gewicht (kg)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("z.B. 50", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .font(.title3).fontWeight(.semibold)
                        .padding(12)
                        .background(Color(uiColor: UIColor.systemGray6))
                        .cornerRadius(10)
                }

                // Wiederholungen
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wiederholungen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("z.B. 8", text: $repsInput)
                        .keyboardType(.numberPad)
                        .font(.title3).fontWeight(.semibold)
                        .padding(12)
                        .background(Color(uiColor: UIColor.systemGray6))
                        .cornerRadius(10)
                }
            }

            // Notiz (optional)
            TextField("Notiz (optional, z.B. 'einfach gefühlt')", text: $noteInput)
                .font(.subheadline)
                .padding(12)
                .background(Color(uiColor: UIColor.systemGray6))
                .cornerRadius(10)

            // Ziel-Anzeige
            HStack {
                Text("Ziel: \(exercise.targetSets) Sätze × \(exercise.targetReps) Wdh")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(todaySets.count)/\(exercise.targetSets) Sätze heute")
                    .font(.caption).fontWeight(.medium)
                    .foregroundColor(accentColor)
            }

            // Speichern-Button
            Button {
                saveSet()
            } label: {
                HStack {
                    Image(systemName: savedBanner ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text(savedBanner ? "Gespeichert!" : "Satz speichern")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(canSave ? accentColor : Color(uiColor: UIColor.systemGray4))
                .foregroundColor(canSave ? .white : .secondary)
                .cornerRadius(14)
            }
            .disabled(!canSave)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    var canSave: Bool {
        Double(weightInput) != nil && Int(repsInput) != nil
    }

    // ───────────────────────────────────────────
    // MARK: – Heutige Sätze
    // ───────────────────────────────────────────

    var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heute")
                .font(.headline)

            ForEach(todaySets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                HStack {
                    Text("Satz \(set.setNumber)")
                        .font(.subheadline).fontWeight(.medium)
                        .frame(width: 60, alignment: .leading)

                    Text("\(String(format: "%.1f", set.weight)) kg")
                        .font(.subheadline)
                        .foregroundColor(accentColor)
                        .frame(width: 80, alignment: .leading)

                    Text("\(set.reps) Wdh")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !set.note.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(uiColor: UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Vergleichskarte Alle 4 Phasen
    // ───────────────────────────────────────────

    var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Deine Gewichte nach Zyklus-Phase")
                .font(.headline)

            // Grid mit allen 4 Phasen
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    PhaseComparisonBox(phase: .menstruation, exercise: exercise)
                    PhaseComparisonBox(phase: .follicular, exercise: exercise)
                }
                HStack(spacing: 10) {
                    PhaseComparisonBox(phase: .ovulation, exercise: exercise)
                    PhaseComparisonBox(phase: .luteal, exercise: exercise)
                }
            }

            // Info-Text
            Text("💡 Tipp: Deine Gewichte variieren natürlich durch Hormone. Das ist völlig normal!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Verlauf
    // ───────────────────────────────────────────

    var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verlauf (\(isInPeriod ? "Periode" : "Normal"))")
                .font(.headline)

            ForEach(historySets.prefix(10)) { set in
                HStack {
                    Text(set.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .leading)
                    Text("\(String(format: "%.1f", set.weight)) kg")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(accentColor)
                    Text("× \(set.reps)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Satz speichern
    // ───────────────────────────────────────────

    func saveSet() {
        guard let weight = Double(weightInput),
              let reps   = Int(repsInput) else { return }

        let newSet = WorkoutSet(
            weight:         weight,
            reps:           reps,
            setNumber:      todaySets.count + 1,
            isDuringPeriod: isInPeriod,
            note:           noteInput,
            cyclePhase:     cycleManager.currentPhase  // NEU: Phase speichern
        )
        newSet.exercise = exercise
        context.insert(newSet)

        repsInput   = ""
        noteInput   = ""

        lastSetNumber = todaySets.count + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4)) { showTimer = true }
        }

        withAnimation {
            savedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { savedBanner = false }
        }
    }
}
// ───────────────────────────────────────────
// MARK: – Phase Comparison Box
// ───────────────────────────────────────────

struct PhaseComparisonBox: View {
    var cycleManager = CycleManager.shared
    let phase: CyclePhase
    let exercise: Exercise
    
    var isCurrentPhase: Bool {
        cycleManager.currentPhase == phase
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Text(phase.emoji)
                    .font(.caption)
                Text(phase.rawValue)
                    .font(.caption2)
                    .fontWeight(isCurrentPhase ? .bold : .medium)
            }
            .foregroundColor(phase.color)
            
            // Gewicht
            if let w = exercise.lastWeight(for: phase) {
                Text("\(String(format: "%.1f", w)) kg")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(phase.color)
                Text("\(exercise.lastReps(for: phase) ?? 0) Wdh")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("–")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Noch keine Daten")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Multiplier
            Text("\(Int(phase.weightMultiplier * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(phase.color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            LinearGradient(
                colors: [
                    phase.color.opacity(isCurrentPhase ? 0.2 : 0.1),
                    phase.color.opacity(isCurrentPhase ? 0.1 : 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(phase.color.opacity(isCurrentPhase ? 0.5 : 0.3), lineWidth: isCurrentPhase ? 2 : 1)
        )
        .shadow(color: isCurrentPhase ? phase.color.opacity(0.2) : .clear, radius: 4, y: 2)
    }
}


