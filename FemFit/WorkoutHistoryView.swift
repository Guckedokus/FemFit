// WorkoutHistoryView.swift
// FemFit – Training-Historie und Statistiken

import SwiftUI
import SwiftData
import Charts

struct WorkoutHistoryView: View {
    
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var allSessions: [WorkoutSession]
    
    var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.endTime != nil }
    }
    
    // Gruppiert nach Woche
    var sessionsByWeek: [(week: String, sessions: [WorkoutSession])] {
        let grouped = Dictionary(grouping: completedSessions) { session in
            let week = Calendar.current.component(.weekOfYear, from: session.startTime)
            let year = Calendar.current.component(.year, from: session.startTime)
            return "\(year)-W\(week)"
        }
        return grouped.map { (week: $0.key, sessions: $0.value) }
            .sorted { $0.week > $1.week }
    }
    
    // Letzte 30 Tage Stats
    var last30DaysSessions: [WorkoutSession] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return completedSessions.filter { $0.startTime >= thirtyDaysAgo }
    }
    
    var totalWorkoutTime: TimeInterval {
        completedSessions.reduce(0) { $0 + $1.duration }
    }
    
    var averageWorkoutTime: TimeInterval {
        guard !completedSessions.isEmpty else { return 0 }
        return totalWorkoutTime / Double(completedSessions.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // ── Gesamt-Statistiken ──
                statsCards
                
                // ── Chart: Sessions pro Woche (letzte 8 Wochen) ──
                weeklyChart
                
                // ── Liste der Sessions ──
                if !completedSessions.isEmpty {
                    sessionsList
                } else {
                    emptyState
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Trainings-Historie")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Stats Cards
    // ───────────────────────────────────────────
    
    var statsCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "Gesamt",
                    value: "\(completedSessions.count)",
                    subtitle: "Sessions",
                    icon: "dumbbell.fill",
                    color: Color(hex: "#1D9E75")
                )
                statCard(
                    title: "Letzte 30 Tage",
                    value: "\(last30DaysSessions.count)",
                    subtitle: "Sessions",
                    icon: "calendar",
                    color: Color(hex: "#4A90D9")
                )
            }
            
            HStack(spacing: 12) {
                statCard(
                    title: "Gesamt-Zeit",
                    value: formatDuration(totalWorkoutTime),
                    subtitle: "Training",
                    icon: "clock.fill",
                    color: Color(hex: "#F4A623")
                )
                statCard(
                    title: "Ø Dauer",
                    value: formatDuration(averageWorkoutTime),
                    subtitle: "pro Session",
                    icon: "timer",
                    color: Color(hex: "#E84393")
                )
            }
            
            // Periode-Stats
            let periodSessions = completedSessions.filter { $0.isDuringPeriod }
            let periodPercent = completedSessions.isEmpty ? 0 : Int((Double(periodSessions.count) / Double(completedSessions.count)) * 100)
            
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "#E84393"))
                Text("\(periodSessions.count) Sessions während Periode (\(periodPercent)%)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(hex: "#E84393").opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(title)\n\(subtitle)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .padding(14)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Weekly Chart
    // ───────────────────────────────────────────
    
    var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte 8 Wochen")
                .font(.headline)
            
            let last8Weeks = getLast8WeeksData()
            
            if !last8Weeks.isEmpty {
                Chart {
                    ForEach(last8Weeks) { week in
                        BarMark(
                            x: .value("Woche", week.label),
                            y: .value("Sessions", week.count)
                        )
                        .foregroundStyle(week.hasPeriodSession ? Color(hex: "#E84393") : Color(hex: "#1D9E75"))
                        .cornerRadius(6)
                    }
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("Noch keine Daten vorhanden")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    struct WeekData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let hasPeriodSession: Bool
    }
    
    func getLast8WeeksData() -> [WeekData] {
        let calendar = Calendar.current
        var result: [WeekData] = []
        
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: .now) else { continue }
            let weekNum = calendar.component(.weekOfYear, from: weekStart)
            
            let sessionsInWeek = completedSessions.filter { session in
                let sessionWeek = calendar.component(.weekOfYear, from: session.startTime)
                let sessionYear = calendar.component(.year, from: session.startTime)
                let currentYear = calendar.component(.year, from: weekStart)
                return sessionWeek == weekNum && sessionYear == currentYear
            }
            
            let hasPeriod = sessionsInWeek.contains { $0.isDuringPeriod }
            result.append(WeekData(label: "W\(weekNum)", count: sessionsInWeek.count, hasPeriodSession: hasPeriod))
        }
        
        return result
    }
    
    // ───────────────────────────────────────────
    // MARK: – Sessions List
    // ───────────────────────────────────────────
    
    var sessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alle Sessions")
                .font(.headline)
            
            ForEach(completedSessions.prefix(20)) { session in
                sessionRow(session)
            }
            
            if completedSessions.count > 20 {
                Text("... und \(completedSessions.count - 20) weitere")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }
    
    func sessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(session.isDuringPeriod ? Color(hex: "#E84393").opacity(0.2) : Color(hex: "#1D9E75").opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: session.isDuringPeriod ? "heart.fill" : "dumbbell.fill")
                    .font(.title3)
                    .foregroundColor(session.isDuringPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDay?.name ?? "Training")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(session.startTime.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(session.durationFormatted, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if session.completedExerciseCount > 0 {
                    Text("\(session.completedExerciseCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Übungen")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Empty State
    // ───────────────────────────────────────────
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Noch keine Sessions")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Starte dein erstes Training und beende es, um es hier zu sehen.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Helper
    // ───────────────────────────────────────────
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
