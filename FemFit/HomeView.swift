// HomeView.swift
// FemFit – Startseite mit Programm-Übersicht
// Einfügen in Xcode: File > New > File > Swift File > "HomeView"

import SwiftUI
import SwiftData

struct HomeView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    // Alle Programme aus der Datenbank laden
    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]

    @State private var showAddProgram   = false
    @State private var newProgramName   = ""
    @State private var showAddDay       = false
    @State private var newDayName       = ""
    @State private var selectedProgram: WorkoutProgram?

    var activeProgram: WorkoutProgram? { programs.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // ── Zyklus-Banner ──
                    cycleBanner

                    if let program = activeProgram {
                        // ── Programm-Header ──
                        programHeader(program)

                        // ── Trainingstage ──
                        VStack(spacing: 10) {
                            ForEach(program.sortedDays) { day in
                                NavigationLink(destination: WorkoutDayView(day: day)) {
                                    WorkoutDayCard(day: day)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // ── Neuen Tag hinzufügen ──
                        Button {
                            selectedProgram = program
                            showAddDay = true
                        } label: {
                            Label("Trainingstag hinzufügen", systemImage: "plus.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(uiColor: UIColor.systemGray6))
                                .cornerRadius(12)
                        }

                    } else {
                        // ── Kein Programm vorhanden ──
                        emptyState
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("FemFit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddProgram = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // ── Programm erstellen ──
            .alert("Neues Programm", isPresented: $showAddProgram) {
                TextField("Name (z.B. Push Pull Legs)", text: $newProgramName)
                Button("Erstellen") { createProgram() }
                Button("Abbrechen", role: .cancel) { newProgramName = "" }
            }
            // ── Trainingstag erstellen ──
            .alert("Neuer Trainingstag", isPresented: $showAddDay) {
                TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
                Button("Hinzufügen") { addDay() }
                Button("Abbrechen", role: .cancel) { newDayName = "" }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Zyklus-Banner
    // ───────────────────────────────────────────

    var cycleBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: cycleManager.isInPeriod ? "moon.fill" : "sun.max.fill")
                .font(.title2)
                .foregroundColor(cycleManager.cyclePhaseColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(cycleManager.cyclePhaseText)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(cycleManager.cyclePhaseColor)

                if !cycleManager.isInPeriod {
                    Text("Nächste Periode in \(cycleManager.daysUntilNextPeriod) Tagen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Modus-Toggle
            Toggle("", isOn: Binding(
                get: { cycleManager.isInPeriod },
                set: { cycleManager.isInPeriod = $0 }
            ))
            .tint(Color(hex: "#E84393"))
            .labelsHidden()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cycleManager.isInPeriod
                      ? Color(hex: "#E84393").opacity(0.1)
                      : Color(hex: "#1D9E75").opacity(0.1))
        )
    }

    // ───────────────────────────────────────────
    // MARK: – Programm-Header
    // ───────────────────────────────────────────

    func programHeader(_ program: WorkoutProgram) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mein Programm")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(program.name)
                    .font(.title2).fontWeight(.bold)
                Text("\(program.completedWorkouts) Workouts absolviert")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Leerer Zustand
    // ───────────────────────────────────────────

    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Noch kein Programm")
                .font(.title3).fontWeight(.semibold)

            Text("Erstelle dein erstes Trainingsprogramm und fang an zu tracken.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddProgram = true
            } label: {
                Label("Programm erstellen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(hex: "#E84393"))
                    .cornerRadius(14)
            }
        }
        .padding(.top, 40)
    }

    // ───────────────────────────────────────────
    // MARK: – Daten-Aktionen
    // ───────────────────────────────────────────

    func createProgram() {
        guard !newProgramName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let program = WorkoutProgram(name: newProgramName)
        context.insert(program)
        newProgramName = ""
    }

    func addDay() {
        guard let program = selectedProgram,
              !newDayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let day = WorkoutDay(name: newDayName, order: program.days.count)
        day.program = program
        context.insert(day)
        newDayName = ""
        selectedProgram = nil
    }
}

// ───────────────────────────────────────────
// MARK: – Trainingstag-Karte
// ───────────────────────────────────────────

struct WorkoutDayCard: View {

    var cycleManager = CycleManager.shared
    let day: WorkoutDay

    var completion: Double { day.completionPercent }

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var body: some View {
        HStack(spacing: 14) {
            // Fortschritts-Ring
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: completion)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(completion * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(day.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(day.exercises.count) Übungen · ~\(day.exercises.count * 10)min")
                    .font(.caption)
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
