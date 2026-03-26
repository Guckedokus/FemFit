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
    
    // ── Tonnage-Berechnungen ──────────────────────
    
    // Gesamt-Tonnage aller Zeiten (kg × Reps über alle Übungen)
    var totalTonnage: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
    
    // Wöchentliche Tonnage (letzte 8 Wochen)
    var weeklyTonnageData: [WeekTonnage] {
        let calendar = Calendar.current
        return (0..<8).reversed().compactMap { weekOffset -> WeekTonnage? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: .now) else { return nil }
            let weekNum = calendar.component(.weekOfYear, from: weekStart)
            let year = calendar.component(.year, from: weekStart)
            let allSets = exercises.flatMap(\.sets).filter {
                calendar.component(.weekOfYear, from: $0.date) == weekNum &&
                calendar.component(.year, from: $0.date) == year
            }
            let tonnage = allSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            return WeekTonnage(label: "W\(weekNum)", tonnage: tonnage)
        }
    }
    
    // Muskelgruppen-Volumen (Tonnage pro Muskelgruppe, letzte 4 Wochen)
    var muscleGroupData: [MuscleGroupVolume] {
        let calendar = Calendar.current
        guard let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: .now) else { return [] }
        
        var grouped: [String: Double] = [:]
        for exercise in exercises {
            // Muskelgruppe aus der Library ermitteln
            let muscleGroup = ExerciseLibrary.all.first(where: { $0.name == exercise.name })?.muscleGroup.rawValue ?? "Sonstige"
            let recentSets = exercise.sets.filter { $0.date >= fourWeeksAgo }
            let tonnage = recentSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            if tonnage > 0 {
                grouped[muscleGroup, default: 0] += tonnage
            }
        }
        return grouped.map { MuscleGroupVolume(name: $0.key, tonnage: $0.value) }
            .sorted { $0.tonnage > $1.tonnage }
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
                
                // ── Tonnage-Übersicht ──
                if totalTonnage > 0 {
                    tonnageOverviewCard
                    weeklyTonnageChart
                    if !muscleGroupData.isEmpty {
                        muscleGroupBalanceChart
                    }
                }

                if loggedExercises.isEmpty {
                    emptyState
                } else {
                    exercisePicker
                    if let exercise = selectedExercise ?? loggedExercises.first {
                        mainChart(for: exercise)
                        summaryCards(for: exercise)
                        prCard(for: exercise)
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
    
    // ───────────────────────────────────────────
    // MARK: – Tonnage Übersicht Card
    // ───────────────────────────────────────────
    
    var tonnageOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Gesamtvolumen", systemImage: "scalemass.fill")
                .font(.headline)
                .foregroundColor(Color(hex: "#4A90D9"))
            
            HStack(spacing: 12) {
                tonnageStat(
                    title: "Gesamt-Tonnage",
                    value: formatTonnage(totalTonnage),
                    subtitle: "kg bewegt",
                    color: Color(hex: "#4A90D9")
                )
                tonnageStat(
                    title: "Diese Woche",
                    value: formatTonnage(weeklyTonnageData.last?.tonnage ?? 0),
                    subtitle: "kg Volumen",
                    color: Color(hex: "#1D9E75")
                )
                tonnageStat(
                    title: "Übungen",
                    value: "\(loggedExercises.count)",
                    subtitle: "getrackt",
                    color: Color(hex: "#7B68EE")
                )
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    func tonnageStat(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Wöchentlicher Tonnage-Chart
    // ───────────────────────────────────────────
    
    var weeklyTonnageChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wöchentliches Trainingsvolumen")
                .font(.headline)
            Text("Gesamte bewegte Last (kg × Wdh) pro Woche")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(weeklyTonnageData) { week in
                    BarMark(
                        x: .value("Woche", week.label),
                        y: .value("Tonnage", week.tonnage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#4A90D9"), Color(hex: "#4A90D9").opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatTonnage(v))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Muskelgruppen-Balance
    // ───────────────────────────────────────────
    
    var muscleGroupBalanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muskelgruppen-Balance")
                .font(.headline)
            Text("Trainingsvolumen letzte 4 Wochen")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Horizontale Balken
            VStack(spacing: 8) {
                ForEach(muscleGroupData.prefix(6)) { group in
                    let maxTonnage = muscleGroupData.first?.tonnage ?? 1
                    let fraction = group.tonnage / maxTonnage
                    let muscleGroup = MuscleGroup(rawValue: group.name)
                    let emoji = muscleGroup?.emoji ?? "💪"
                    
                    HStack(spacing: 10) {
                        Text(emoji)
                            .font(.caption)
                            .frame(width: 20)
                        Text(group.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(uiColor: UIColor.systemGray5))
                                    .frame(height: 16)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(muscleGroupColor(group.name))
                                    .frame(width: geo.size.width * fraction, height: 16)
                            }
                        }
                        .frame(height: 16)
                        
                        Text(formatTonnage(group.tonnage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    func muscleGroupColor(_ name: String) -> Color {
        switch name {
        case "Brust":    return Color(hex: "#E84393")
        case "Rücken":   return Color(hex: "#1D9E75")
        case "Beine":    return Color(hex: "#4A90D9")
        case "Schulter": return Color(hex: "#F4A623")
        case "Bizeps":   return Color(hex: "#7B68EE")
        case "Trizeps":  return Color(hex: "#E8861A")
        case "Gluteus":  return Color(hex: "#E84393").opacity(0.7)
        case "Bauch":    return Color(hex: "#1D9E75").opacity(0.7)
        default:         return Color(hex: "#4A90D9").opacity(0.7)
        }
    }
    
    // ───────────────────────────────────────────
    // MARK: – PR Card pro Übung
    // ───────────────────────────────────────────
    
    func prCard(for exercise: Exercise) -> some View {
        let pr = exercise.sets.map(\.weight).max()
        let prReps = exercise.sets.filter { $0.weight == pr }.last?.reps
        return Group {
            if let pr = pr {
                HStack(spacing: 14) {
                    Text("🏆")
                        .font(.title2)
                        .padding(10)
                        .background(Color(hex: "#F4A623").opacity(0.15))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Persönlicher Rekord")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            Text("\(String(format: "%.1f", pr)) kg")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#F4A623"))
                            if let reps = prReps {
                                Text("× \(reps) Wdh")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(hex: "#F4A623").opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#F4A623").opacity(0.3), lineWidth: 1.5)
                )
            }
        }
    }
    
    // ───────────────────────────────────────────
    // MARK: – Hilfsfunktionen
    // ───────────────────────────────────────────
    
    func formatTonnage(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1ft", kg / 1000)
        } else {
            return String(format: "%.0fkg", kg)
        }
    }
    
    struct WeekTonnage: Identifiable {
        let id = UUID()
        let label: String
        let tonnage: Double
    }
    
    struct MuscleGroupVolume: Identifiable {
        let id = UUID()
        let name: String
        let tonnage: Double
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
