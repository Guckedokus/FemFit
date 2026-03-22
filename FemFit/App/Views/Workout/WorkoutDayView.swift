// WorkoutDayView.swift
// FemFit – Übungsliste eines Trainingstages
// DAS ist der Kern-Screen mit dem Normal/Periode-Toggle!
// Einfügen in Xcode: File > New > File > Swift File > "WorkoutDayView"

import SwiftUI
import SwiftData
import Combine

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
    @State private var showModeSelection = false

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
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasActiveSession {
                    // Stop Button mit Timer
                    stopWorkoutButton
                } else {
                    // Start Button
                    startWorkoutButton
                }
            }
        }
        // onAppear removed - user can manually tap "Start" button instead
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
    // MARK: – Toolbar Buttons (NEU!)
    // ───────────────────────────────────────────
    
    var startWorkoutButton: some View {
        Button {
            showModeSelection = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                Text("Start")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#1D9E75"))
            .cornerRadius(20)
        }
    }
    
    var stopWorkoutButton: some View {
        Button {
            showFinishConfirmation = true
        } label: {
            HStack(spacing: 8) {
                // Timer
                if let session = day.activeSession {
                    TimerView(session: session)
                }
                
                Image(systemName: "stop.circle.fill")
                    .font(.title3)
                Text("Stopp")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#E84393"))
            .cornerRadius(20)
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
    }

    // ───────────────────────────────────────────
    // MARK: – Modus Toggle (NEU: 4 Phasen Dropdown)
    // ───────────────────────────────────────────

    var modeToggle: some View {
        Menu {
            ForEach(CyclePhase.allCases, id: \.self) { phase in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        // Setze Phase
                        cycleManager.isInPeriod = (phase == .menstruation)
                        // TODO: Hier könnten wir später einen manuellen Override speichern
                    }
                } label: {
                    HStack {
                        Text(phase.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.rawValue)
                                .fontWeight(.semibold)
                            Text("\(Int(phase.weightMultiplier * 100))% Gewichte")
                                .font(.caption2)
                        }
                        Spacer()
                        if cycleManager.currentPhase == phase {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            // Info über automatische Erkennung
            Button {
                // Info anzeigen
            } label: {
                Label("Automatisch: Tag \(cycleManager.currentCycleDay)", systemImage: "info.circle")
            }
            .disabled(true)
            
        } label: {
            HStack(spacing: 12) {
                // Aktueller Phasen-Indikator
                ZStack {
                    Circle()
                        .fill(cycleManager.currentPhase.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(cycleManager.currentPhase.emoji)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(cycleManager.currentPhase.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(cycleManager.currentPhase.color.opacity(0.7))
                    }
                    Text(cycleManager.currentPhase.shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Gewichts-Badge
                VStack(spacing: 2) {
                    Text("\(Int(cycleManager.currentPhase.weightMultiplier * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(cycleManager.currentPhase.color)
                    Text("Gewichte")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
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
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cycleManager.currentPhase.color.opacity(0.3), lineWidth: 2)
            )
        }
        .disabled(hasActiveSession)  // ← Während Session nicht wechselbar!
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

// ───────────────────────────────────────────
// MARK: – Timer View (NEU!)
// ───────────────────────────────────────────

struct TimerView: View {
    let session: WorkoutSession
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var elapsedTime: TimeInterval {
        currentTime.timeIntervalSince(session.startTime)
    }
    
    var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        Text(formattedTime)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.2))
            .cornerRadius(6)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }
}

