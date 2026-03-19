// ExerciseDetailView.swift
// FemFit – Hier werden Sätze eingetragen
// Einfügen in Xcode: File > New > File > Swift File > "ExerciseDetailView"

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    let exercise: Exercise

    // Eingabe-Felder
    @State private var weightInput  = ""
    @State private var repsInput    = ""
    @State private var noteInput    = ""
    @State private var savedBanner  = false

    var isInPeriod: Bool { cycleManager.isInPeriod }
    var accentColor: Color { isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75") }

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

    // Letztes Gewicht als Vorschlag
    var suggestedWeight: String {
        if let last = exercise.lastWeight(period: isInPeriod) {
            return String(format: "%.1f", last)
        }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

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

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Letztes Gewicht vorausfüllen
            weightInput = suggestedWeight
            repsInput   = exercise.lastReps(period: isInPeriod).map(String.init) ?? ""
        }
        .onChange(of: isInPeriod) { _, _ in
            // Felder aktualisieren wenn Modus wechselt
            weightInput = suggestedWeight
            repsInput   = exercise.lastReps(period: isInPeriod).map(String.init) ?? ""
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Modus-Badge
    // ───────────────────────────────────────────

    var modeBadge: some View {
        HStack {
            Spacer()
            Text(isInPeriod ? "🌸 Perioden-Gewichte" : "💪 Normal-Gewichte")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(isInPeriod ? Color(hex: "#880E4F") : Color(hex: "#085041"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.15))
                .cornerRadius(20)
            Spacer()
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
    // MARK: – Vergleichskarte Normal vs Periode
    // ───────────────────────────────────────────

    var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deine Gewichte im Vergleich")
                .font(.headline)

            HStack(spacing: 12) {
                // Normal
                VStack(spacing: 6) {
                    Text("💪 Normal")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#085041"))
                    if let w = exercise.lastWeight(period: false) {
                        Text("\(String(format: "%.1f", w)) kg")
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(Color(hex: "#1D9E75"))
                        Text("\(exercise.lastReps(period: false) ?? 0) Wdh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("–")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "#1D9E75").opacity(0.1))
                .cornerRadius(12)

                // Periode
                VStack(spacing: 6) {
                    Text("🌸 Periode")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#880E4F"))
                    if let w = exercise.lastWeight(period: true) {
                        Text("\(String(format: "%.1f", w)) kg")
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(Color(hex: "#E84393"))
                        Text("\(exercise.lastReps(period: true) ?? 0) Wdh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("–")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "#E84393").opacity(0.1))
                .cornerRadius(12)
            }

            // Differenz-Info
            if let nw = exercise.lastWeight(period: false),
               let pw = exercise.lastWeight(period: true) {
                let diff = nw - pw
                let pct  = Int((diff / nw) * 100)
                Text("Differenz: \(String(format: "%.1f", diff)) kg (\(pct)%) – das ist völlig normal durch den Hormonspiegel! 🌱")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
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
            note:           noteInput
        )
        newSet.exercise = exercise
        context.insert(newSet)

        // Felder zurücksetzen (Gewicht behalten als Vorschlag)
        repsInput   = ""
        noteInput   = ""

        // Kurzes Feedback
        withAnimation {
            savedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { savedBanner = false }
        }
    }
}
