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

    @State private var showAddExercise = false

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var modeLabel: String {
        cycleManager.isInPeriod ? "🌸 Perioden-Gewichte" : "💪 Normal-Gewichte"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // ── Modus-Toggle ──
                modeToggle

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
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView(day: day)
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Modus Toggle
    // ───────────────────────────────────────────

    var modeToggle: some View {
        HStack(spacing: 0) {
            // Normal-Taste
            Button {
                withAnimation(.spring(response: 0.3)) {
                    cycleManager.isInPeriod = false
                }
            } label: {
                HStack(spacing: 6) {
                    Text("💪")
                    Text("Normal")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    !cycleManager.isInPeriod
                    ? Color(hex: "#1D9E75")
                    : Color.clear
                )
                .foregroundColor(!cycleManager.isInPeriod ? .white : .secondary)
            }

            // Perioden-Taste
            Button {
                withAnimation(.spring(response: 0.3)) {
                    cycleManager.isInPeriod = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text("🌸")
                    Text("Periode")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    cycleManager.isInPeriod
                    ? Color(hex: "#E84393")
                    : Color.clear
                )
                .foregroundColor(cycleManager.isInPeriod ? .white : .secondary)
            }
        }
        .background(Color(uiColor: UIColor.systemGray6))
        .cornerRadius(12)
        .animation(.spring(response: 0.3), value: cycleManager.isInPeriod)
    }

    // ───────────────────────────────────────────
    // MARK: – Perioden-Info-Banner
    // ───────────────────────────────────────────

    var periodInfoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundColor(Color(hex: "#E84393"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Perioden-Modus aktiv")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#880E4F"))
                Text("Deine angepassten Gewichte werden angezeigt. Kein Vergleich mit Normal-Werten nötig!")
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
