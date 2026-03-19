// ProgressChartView.swift
// FemFit – Fortschritts-Charts (Normal vs. Periode)
// Einfügen in Xcode: File > New > File > Swift File > "ProgressChartView"

import SwiftUI
import SwiftData
import Charts

struct ProgressChartView: View {

    var cycleManager = CycleManager.shared
    @Query private var exercises: [Exercise]

    @State private var selectedExercise: Exercise?

    // Nur Übungen die mindestens einen Eintrag haben
    var loggedExercises: [Exercise] {
        exercises.filter { !$0.sets.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    if loggedExercises.isEmpty {
                        emptyState
                    } else {
                        // ── Übungs-Auswahl ──
                        exercisePicker

                        if let exercise = selectedExercise ?? loggedExercises.first {
                            // ── Haupt-Chart ──
                            mainChart(for: exercise)

                            // ── Zusammenfassung ──
                            summaryCards(for: exercise)

                            // ── Erkenntnis-Karte ──
                            insightCard(for: exercise)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Fortschritt")
            .onAppear {
                if selectedExercise == nil {
                    selectedExercise = loggedExercises.first
                }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Übungs-Picker
    // ───────────────────────────────────────────

    var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(loggedExercises) { exercise in
                    Button {
                        withAnimation { selectedExercise = exercise }
                    } label: {
                        Text(exercise.name)
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedExercise?.id == exercise.id
                                ? Color(hex: "#E84393")
                                : Color(uiColor: UIColor.systemGray5)
                            )
                            .foregroundColor(
                                selectedExercise?.id == exercise.id
                                ? .white
                                : .secondary
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Haupt-Chart
    // ───────────────────────────────────────────

    func mainChart(for exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.headline)
            Text("Gewichtsverlauf – Normal (grün) vs. Periode (pink)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Daten vorbereiten
            let normalData = chartData(from: exercise.normalSets)
            let periodData = chartData(from: exercise.periodSets)

            if normalData.isEmpty && periodData.isEmpty {
                Text("Noch keine Daten vorhanden.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                Chart {
                    ForEach(normalData) { point in
                        LineMark(
                            x: .value("Datum", point.date),
                            y: .value("Gewicht", point.weight)
                        )
                        .foregroundStyle(Color(hex: "#1D9E75"))
                        .symbol(Circle())
                        .symbolSize(40)

                        AreaMark(
                            x: .value("Datum", point.date),
                            y: .value("Gewicht", point.weight)
                        )
                        .foregroundStyle(Color(hex: "#1D9E75").opacity(0.1))
                    }

                    ForEach(periodData) { point in
                        LineMark(
                            x: .value("Datum", point.date),
                            y: .value("Gewicht", point.weight)
                        )
                        .foregroundStyle(Color(hex: "#E84393"))
                        .symbol(Circle())
                        .symbolSize(40)
                        .lineStyle(StrokeStyle(dash: [5, 3]))

                        AreaMark(
                            x: .value("Datum", point.date),
                            y: .value("Gewicht", point.weight)
                        )
                        .foregroundStyle(Color(hex: "#E84393").opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }

                // Legende
                HStack(spacing: 20) {
                    legendItem(color: Color(hex: "#1D9E75"), label: "Normal")
                    legendItem(color: Color(hex: "#E84393"), label: "Periode", dashed: true)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    func legendItem(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 6, height: 2)
                    }
                }
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Zusammenfassungs-Karten
    // ───────────────────────────────────────────

    func summaryCards(for exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            statCard(
                title: "Bestes Normal",
                value: exercise.normalSets.map(\.weight).max().map { "\(String(format: "%.1f", $0)) kg" } ?? "–",
                color: Color(hex: "#1D9E75")
            )
            statCard(
                title: "Bestes Periode",
                value: exercise.periodSets.map(\.weight).max().map { "\(String(format: "%.1f", $0)) kg" } ?? "–",
                color: Color(hex: "#E84393")
            )
            statCard(
                title: "Sessions",
                value: "\(Set(exercise.sets.map { Calendar.current.startOfDay(for: $0.date) }).count)",
                color: Color(hex: "#7B68EE")
            )
        }
    }

    func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.headline).fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    // ───────────────────────────────────────────
    // MARK: – Erkenntnis-Karte
    // ───────────────────────────────────────────

    func insightCard(for exercise: Exercise) -> some View {
        let normalBest  = exercise.normalSets.map(\.weight).max() ?? 0
        let periodBest  = exercise.periodSets.map(\.weight).max() ?? 0
        let normalFirst = exercise.normalSets.first?.weight ?? 0
        let normalLast  = exercise.normalSets.last?.weight  ?? 0
        let progress    = normalLast - normalFirst

        return VStack(alignment: .leading, spacing: 12) {
            Label("Deine Erkenntnis", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.orange)

            if progress > 0 {
                Text("Du bist stärker geworden! Dein Normal-Gewicht ist um \(String(format: "%.1f", progress)) kg gestiegen. Super gemacht! 💪")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            } else if normalBest > 0 {
                Text("Bleib dran – Fortschritt braucht Zeit. Du trainierst konsequent!")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            if normalBest > 0 && periodBest > 0 {
                let diff = normalBest - periodBest
                let pct  = Int((diff / normalBest) * 100)
                Divider()
                Text("Perioden-Unterschied: \(String(format: "%.1f", diff)) kg (\(pct)%) – Das liegt am Östrogenspiegel und ist bei fast allen Frauen so. Du wirst NICHT schwächer, sondern trainierst clever! 🌸")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Leerer Zustand
    // ───────────────────────────────────────────

    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Noch keine Daten")
                .font(.title3).fontWeight(.semibold)
            Text("Starte dein erstes Training und trage Gewichte ein – dann siehst du hier deinen Fortschritt.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // ───────────────────────────────────────────
    // MARK: – Hilfsfunktionen
    // ───────────────────────────────────────────

    struct ChartPoint: Identifiable {
        let id    = UUID()
        let date:   Date
        let weight: Double
    }

    func chartData(from sets: [WorkoutSet]) -> [ChartPoint] {
        // Pro Tag den Durchschnitt nehmen
        let grouped = Dictionary(grouping: sets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { date, sets in
                ChartPoint(date: date, weight: sets.map(\.weight).reduce(0, +) / Double(sets.count))
            }
            .sorted { $0.date < $1.date }
    }
}
