// ProgressChartView.swift
// FemFit – Fortschritt mit Unternavigation
import SwiftUI
import SwiftData
import Charts

struct ProgressChartView: View {
    var cycleManager = CycleManager.shared
    @Query private var exercises: [Exercise]

    @State private var selectedExercise: Exercise?
    @State private var showBody       = false
    @State private var showAchievements = false
    @State private var showHistory = false
    @State private var showRestDay = false

    var loggedExercises: [Exercise] { exercises.filter { !$0.sets.isEmpty } }

    // Streak für Achievements (basierend auf Sessions)
    @Query private var allSessions: [WorkoutSession]
    var currentStreak: Int {
        cycleManager.calculateStreak(sessions: allSessions)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Quick-Links
                HStack(spacing: 12) {
                    quickLink(icon: "scalemass.fill", label: "Körpermaße", color: Color(hex: "#1D9E75")) { showBody = true }
                    quickLink(icon: "trophy.fill",   label: "Achievements", color: Color(hex: "#F4A623")) { showAchievements = true }
                }
                
                HStack(spacing: 12) {
                    quickLink(icon: "clock.fill", label: "Trainings-Historie", color: Color(hex: "#4A90D9")) { showHistory = true }
                    quickLink(icon: "bed.double.fill", label: "Ruhetag-Tracker", color: Color(hex: "#7B68EE")) { showRestDay = true }
                }

                if loggedExercises.isEmpty {
                    emptyState
                } else {
                    exercisePicker
                    if let exercise = selectedExercise ?? loggedExercises.first {
                        mainChart(for: exercise)
                        summaryCards(for: exercise)
                        insightCard(for: exercise)
                    }
                }
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Fortschritt")
        .onAppear { if selectedExercise == nil { selectedExercise = loggedExercises.first } }
        .sheet(isPresented: $showBody)         { NavigationStack { BodyTrackingView() } }
        .sheet(isPresented: $showAchievements) { NavigationStack { AchievementsView(streak: currentStreak) } }
        .sheet(isPresented: $showHistory)      { NavigationStack { WorkoutHistoryView() } }
        .sheet(isPresented: $showRestDay)      { NavigationStack { RestDayView() } }
    }

    func quickLink(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.title3).foregroundColor(color)
                Text(label).font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(14)
            .background(color.opacity(0.08))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    var exercisePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(loggedExercises) { exercise in
                    Button { withAnimation { selectedExercise = exercise } } label: {
                        Text(exercise.name)
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedExercise?.id == exercise.id ? Color(hex: "#E84393") : Color(uiColor: UIColor.systemGray5))
                            .foregroundColor(selectedExercise?.id == exercise.id ? .white : .secondary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    func mainChart(for exercise: Exercise) -> some View {
        // let accentColor = ... ← DIESE ZEILE GELÖSCHT
        let normalData = chartData(from: exercise.normalSets)
        let periodData = chartData(from: exercise.periodSets)
        // ... Rest bleibt gleich
        return VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name).font(.headline)
            Text("Normal (grün) vs. Periode (pink)").font(.caption).foregroundColor(.secondary)
            if normalData.isEmpty && periodData.isEmpty {
                Text("Noch keine Daten.").font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                Chart {
                    ForEach(normalData) { p in
                        LineMark(x: .value("Datum", p.date), y: .value("kg", p.weight)).foregroundStyle(Color(hex: "#1D9E75")).symbol(Circle()).symbolSize(40)
                        AreaMark(x: .value("Datum", p.date), y: .value("kg", p.weight)).foregroundStyle(Color(hex: "#1D9E75").opacity(0.1))
                    }
                    ForEach(periodData) { p in
                        LineMark(x: .value("Datum", p.date), y: .value("kg", p.weight)).foregroundStyle(Color(hex: "#E84393")).symbol(Circle()).symbolSize(40).lineStyle(StrokeStyle(dash: [5,3]))
                        AreaMark(x: .value("Datum", p.date), y: .value("kg", p.weight)).foregroundStyle(Color(hex: "#E84393").opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false))
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    func summaryCards(for exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Bestes Normal", value: exercise.normalSets.map(\.weight).max().map { "\(String(format: "%.1f", $0)) kg" } ?? "–", color: Color(hex: "#1D9E75"))
            statCard(title: "Bestes Periode", value: exercise.periodSets.map(\.weight).max().map { "\(String(format: "%.1f", $0)) kg" } ?? "–", color: Color(hex: "#E84393"))
            statCard(title: "Sessions", value: "\(Set(exercise.sets.map { Calendar.current.startOfDay(for: $0.date) }).count)", color: Color(hex: "#7B68EE"))
        }
    }

    func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            Text(value).font(.headline).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding(12).background(color.opacity(0.1)).cornerRadius(12)
    }

    func insightCard(for exercise: Exercise) -> some View {
        let normalFirst = exercise.normalSets.first?.weight ?? 0
        let normalLast  = exercise.normalSets.last?.weight  ?? 0
        let progress    = normalLast - normalFirst
        return VStack(alignment: .leading, spacing: 12) {
            Label("Deine Erkenntnis", systemImage: "lightbulb.fill").font(.headline).foregroundColor(.orange)
            if progress > 0 {
                Text("Du bist stärker geworden! +\(String(format: "%.1f", progress)) kg 💪").font(.subheadline)
            } else {
                Text("Bleib dran – Fortschritt braucht Zeit!").font(.subheadline)
            }
            if let nw = exercise.normalSets.map(\.weight).max(), let pw = exercise.periodSets.map(\.weight).max() {
                let diff = nw - pw; let pct = Int((diff / nw) * 100)
                Divider()
                Text("Perioden-Unterschied: \(String(format: "%.1f", diff)) kg (\(pct)%) – völlig normal! 🌸").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16).background(Color(uiColor: UIColor.systemBackground)).cornerRadius(16).shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 60)).foregroundColor(.secondary)
            Text("Noch keine Daten").font(.title3).fontWeight(.semibold)
            Text("Starte dein erstes Training um hier deinen Fortschritt zu sehen.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(.top, 60)
    }

    struct ChartPoint: Identifiable { let id = UUID(); let date: Date; let weight: Double }
    func chartData(from sets: [WorkoutSet]) -> [ChartPoint] {
        let grouped = Dictionary(grouping: sets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { date, sets in ChartPoint(date: date, weight: sets.map(\.weight).reduce(0,+) / Double(sets.count)) }.sorted { $0.date < $1.date }
    }
}
