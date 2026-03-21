// WorkoutDayView.swift
// FemFit – Übungsliste eines Trainingstages
// DAS ist der Kern-Screen mit dem Normal/Periode-Toggle!
// Einfügen in Xcode: File > New > File > Swift File > "WorkoutDayView"

import SwiftUI
import SwiftData

struct WorkoutDayView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    let day: WorkoutDay

    @State private var showAddExercise   = false
    @State private var showEditExercise  = false
    @State private var editingExercise: Exercise? = nil
    @State private var editName = ""
    @State private var editSets = "3"
    @State private var editReps = "10"
    @State private var showFinishConfirmation = false
    @State private var showStartPrompt = false
    @State private var showModeSelection = false
    @State private var hasShownPrompt = false

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var modeLabel: String {
        cycleManager.isInPeriod ? "🌸 Angepasste Gewichte" : "💪 Voll-Power Gewichte"
    }
    
    var hasActiveSession: Bool {
        day.activeSession != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // ── Session-Status Banner ──
                if let session = day.activeSession {
                    activeSessionBanner(session: session)
                }

                // ── Modus-Toggle ──
                modeToggle
                
                // ── Info wenn Modus gesperrt ──
                if hasActiveSession {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Modus während Training gesperrt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // ── Info-Banner wenn Periode aktiv ──
                if cycleManager.isInPeriod {
                    periodInfoBanner
                }

                // ── Übungen ──
                if day.sortedExercises.isEmpty {
                    emptyExercises
                } else {
                    VStack(spacing: 10) {
                        ForEach(day.sortedExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    context.delete(exercise)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingExercise = exercise
                                    editName = exercise.name
                                    editSets = "\(exercise.targetSets)"
                                    editReps = "\(exercise.targetReps)"
                                    showEditExercise = true
                                } label: {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }

                // ── Übung hinzufügen ──
                Button {
                    showAddExercise = true
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(uiColor: UIColor.systemGray6))
                        .cornerRadius(12)
                }
                
                // ── Training starten / beenden ──
                if !day.sortedExercises.isEmpty {
                    workoutControlButton
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Zeige Prompt nur einmal beim Öffnen UND wenn kein aktives Training läuft
            if !hasShownPrompt && !hasActiveSession {
                showStartPrompt = true
                hasShownPrompt = true
            }
        }
        .alert("Neues Training starten?", isPresented: $showStartPrompt) {
            Button("Ja, starten!", role: .none) {
                // Zeige Modus-Auswahl
                showModeSelection = true
            }
            Button("Nein, nur ansehen", role: .cancel) { }
        } message: {
            Text("Möchtest du jetzt ein neues Training für '\(day.name)' starten?")
        }
        .alert("In welchem Modus trainieren?", isPresented: $showModeSelection) {
            Button("\(CyclePhase.follicular.emoji) \(CyclePhase.follicular.rawValue) (Power!)") {
                cycleManager.isInPeriod = false
                startWorkout(phase: .follicular)
            }
            Button("\(CyclePhase.menstruation.emoji) \(CyclePhase.menstruation.rawValue) (Schonend)") {
                cycleManager.isInPeriod = true
                startWorkout(phase: .menstruation)
            }
            Button("\(CyclePhase.ovulation.emoji) \(CyclePhase.ovulation.rawValue) (Peak)") {
                cycleManager.isInPeriod = false
                startWorkout(phase: .ovulation)
            }
            Button("\(CyclePhase.luteal.emoji) \(CyclePhase.luteal.rawValue) (Moderat)") {
                cycleManager.isInPeriod = false
                startWorkout(phase: .luteal)
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Wähle deine aktuelle Zyklus-Phase.\n\nAktuell: \(cycleManager.currentPhase.emoji) \(cycleManager.currentPhase.rawValue) (Tag \(cycleManager.currentCycleDay))")
        }
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView(day: day)
        }
        .sheet(isPresented: $showEditExercise) {
            NavigationStack {
                Form {
                    Section("Übungsname") {
                        TextField("Name", text: $editName)
                    }
                    Section("Ziel") {
                        HStack {
                            Text("Sätze"); Spacer()
                            TextField("3", text: $editSets).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                        }
                        HStack {
                            Text("Wiederholungen"); Spacer()
                            TextField("10", text: $editReps).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                        }
                    }
                }
                .navigationTitle("Übung bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading)  { Button("Abbrechen") { showEditExercise = false } }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Speichern") {
                            if let ex = editingExercise {
                                ex.name       = editName
                                ex.targetSets = Int(editSets) ?? ex.targetSets
                                ex.targetReps = Int(editReps) ?? ex.targetReps
                            }
                            showEditExercise = false
                        }
                        .fontWeight(.semibold)
                        .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFinishConfirmation) {
            if let session = day.activeSession {
                WorkoutFinishView(session: session, day: day, onFinish: { finishWorkout() })
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Session Status Banner
    // ───────────────────────────────────────────
    
    func activeSessionBanner(session: WorkoutSession) -> some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                    Text("Training läuft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                }
                Spacer()
                Text(session.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Fortschritt
            HStack(spacing: 6) {
                Text("\(day.todayCompletedExercises) von \(day.sortedExercises.count) Übungen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Workout Control Button
    // ───────────────────────────────────────────
    
    var workoutControlButton: some View {
        VStack(spacing: 8) {
            Button {
                if hasActiveSession {
                    showFinishConfirmation = true
                } else {
                    // Zeige Modus-Auswahl vor dem Start
                    showModeSelection = true
                }
            } label: {
                HStack {
                    Image(systemName: hasActiveSession ? "checkmark.circle.fill" : "play.circle.fill")
                        .font(.title3)
                    Text(hasActiveSession ? "Training beenden" : "Neues Training starten")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(hasActiveSession ? Color.green : accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            
            // Info-Text
            if !hasActiveSession {
                let todaySessions = day.sessions.filter { 
                    Calendar.current.isDateInToday($0.startTime) 
                }
                if !todaySessions.isEmpty {
                    Text("Heute schon \(todaySessions.count) Training(s) absolviert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // ───────────────────────────────────────────
    // MARK: – Session Management
    // ───────────────────────────────────────────
    
    func startWorkout(phase: CyclePhase? = nil) {
        // Verwende übergebene Phase oder aktuelle Phase vom CycleManager
        let sessionPhase = phase ?? cycleManager.currentPhase
        
        // Neue Session erstellen mit Phase-Info
        let session = WorkoutSession(
            workoutDay: day, 
            isDuringPeriod: sessionPhase == .menstruation,
            cyclePhase: sessionPhase
        )
        context.insert(session)
        
        do {
            try context.save()
            print("✅ Neues Training gestartet in Phase: \(sessionPhase.emoji) \(sessionPhase.rawValue)")
            
            // Zähle heutige Sessions
            let todaySessions = day.sessions.filter { 
                Calendar.current.isDateInToday($0.startTime) 
            }
            print("📊 Training #\(todaySessions.count) heute")
        } catch {
            print("❌ Fehler beim Starten: \(error)")
        }
    }
    
    func finishWorkout() {
        guard let session = day.activeSession else { return }
        session.endTime = .now
        session.completedExerciseCount = day.todayCompletedExercises
        
        // Speichern
        do {
            try context.save()
            print("✅ Session beendet und gespeichert!")
        } catch {
            print("❌ Fehler beim Speichern der Session: \(error)")
        }
        
        // Sheet schließen
        showFinishConfirmation = false
        
        // Prompt-Flag zurücksetzen, damit beim nächsten Öffnen wieder gefragt wird
        hasShownPrompt = false
    }

    // ───────────────────────────────────────────
    // MARK: – Modus Toggle
    // ───────────────────────────────────────────

    var modeToggle: some View {
        HStack(spacing: 0) {
            // Voll-Power Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    cycleManager.isInPeriod = false
                }
            } label: {
                HStack(spacing: 6) {
                    // Icon nur wenn aktiv
                    if !cycleManager.isInPeriod {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                    }
                    Text("💪")
                    Text("Voll-Power")
                        .fontWeight(cycleManager.isInPeriod ? .regular : .semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    !cycleManager.isInPeriod
                    ? Color(hex: "#1D9E75")
                    : Color.clear
                )
                .foregroundColor(!cycleManager.isInPeriod ? .white : .secondary)
            }
            .disabled(hasActiveSession)  // ← Während Session nicht wechselbar!

            // Angepasst Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    cycleManager.isInPeriod = true
                }
            } label: {
                HStack(spacing: 6) {
                    // Icon nur wenn aktiv
                    if cycleManager.isInPeriod {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                    }
                    Text("🌸")
                    Text("Angepasst")
                        .fontWeight(cycleManager.isInPeriod ? .semibold : .regular)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    cycleManager.isInPeriod
                    ? Color(hex: "#E84393")
                    : Color.clear
                )
                .foregroundColor(cycleManager.isInPeriod ? .white : .secondary)
            }
            .disabled(hasActiveSession)  // ← Während Session nicht wechselbar!
        }
        .background(Color(uiColor: UIColor.systemGray6))
        .cornerRadius(12)
        .animation(.spring(response: 0.3), value: cycleManager.isInPeriod)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        )
        .opacity(hasActiveSession ? 0.6 : 1.0)  // ← Visuelles Feedback
    }

    // ───────────────────────────────────────────
    // MARK: – Perioden-Info-Banner
    // ───────────────────────────────────────────

    var periodInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundColor(Color(hex: "#E84393"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Angepasster Modus aktiv")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#880E4F"))
                Text("Deine Gewichte sind auf deinen Zyklus abgestimmt. Perfekt angepasst!")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#AD1457"))
            }
        }
        .padding(12)
        .background(Color(hex: "#E84393").opacity(0.12))
        .cornerRadius(12)
    }

    // ───────────────────────────────────────────
    // MARK: – Leere Liste
    // ───────────────────────────────────────────

    var emptyExercises: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Noch keine Übungen")
                .font(.headline)
            Text("Füge deine erste Übung hinzu.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }

    // ───────────────────────────────────────────
    // MARK: – Sheet: Übung hinzufügen
    // ───────────────────────────────────────────

}

// ───────────────────────────────────────────
// MARK: – Übungs-Zeile
// ───────────────────────────────────────────

struct ExerciseRow: View {

    var cycleManager = CycleManager.shared
    let exercise: Exercise

    var isInPeriod: Bool { cycleManager.isInPeriod }
    var accentColor: Color { isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75") }

    var lastWeight: Double? { exercise.lastWeight(period: isInPeriod) }
    var lastReps:   Int?    { exercise.lastReps(period: isInPeriod) }

    // Zum Vergleich: Gewicht im anderen Modus
    var otherWeight: Double? { exercise.lastWeight(period: !isInPeriod) }

    var completion: Double { exercise.todayCompletion }

    var body: some View {
        HStack(spacing: 14) {

            // Fortschritts-Kreis
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: completion)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Letztes Gewicht im aktuellen Modus
                    if let w = lastWeight, let r = lastReps {
                        Text("\(String(format: "%.1f", w)) kg · \(r) Wdh")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(accentColor)
                    } else {
                        Text("Noch kein Eintrag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Vergleichs-Gewicht (anderer Modus)
                    if let other = otherWeight, lastWeight != nil {
                        Text("(vs \(String(format: "%.1f", other)) kg)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Ziel-Info
                Text("Ziel: \(exercise.targetSets)×\(exercise.targetReps)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
