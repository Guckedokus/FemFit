// DashboardView.swift
import SwiftUI
import SwiftData

struct DashboardView: View {

    var cycleManager = CycleManager.shared
    @AppStorage("userName") var userName = ""
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]

    @Binding var selectedTab: Int

    var activeProgram: WorkoutProgram? { programs.first }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Guten Morgen"
        case 12..<17: return "Guten Tag"
        case 17..<22: return "Guten Abend"
        default:      return "Hallo"
        }
    }

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                cycleCard
                if let program = activeProgram {
                    nextWorkoutCard(program)
                    statsRow(program)
                }
                quickActions
                Spacer(minLength: 30)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: – Header
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting + (userName.isEmpty ? "" : ", \(userName)") + " 👋")
                    .font(.title2).fontWeight(.bold)
                Text(Date.now, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                withAnimation { cycleManager.isInPeriod.toggle() }
            } label: {
                Text(cycleManager.isInPeriod ? "🌸" : "💪")
                    .font(.system(size: 28))
                    .padding(10)
                    .background(accentColor.opacity(0.15))
                    .cornerRadius(14)
            }
        }
        .padding(.top, 8)
    }

    // MARK: – Zyklus-Karte
    var cycleCard: some View {
        Button { selectedTab = 2 } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(uiColor: UIColor.systemGray5), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(cycleManager.currentCycleDay) / CGFloat(cycleManager.cycleLength))
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(cycleManager.currentCycleDay)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cycleManager.cyclePhaseText)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(accentColor)
                    Text(cycleManager.isInPeriod
                         ? "Leichtere Gewichte sind aktiv"
                         : "Nächste Periode in \(cycleManager.daysUntilNextPeriod) Tagen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(16)
            .background(accentColor.opacity(0.08))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: – Nächstes Training
    func nextWorkoutCard(_ program: WorkoutProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nächstes Training")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Intelligente Auswahl des nächsten Trainings
            if let nextDay = determineNextWorkout(for: program) {
                NavigationLink(destination: WorkoutDayView(day: nextDay)) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(accentColor.opacity(0.2), lineWidth: 5)
                            Circle()
                                .trim(from: 0, to: nextDay.completionPercent)
                                .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(nextDay.completionPercent * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(nextDay.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Zeigt Phase + Anzahl Übungen
                            HStack(spacing: 8) {
                                Text("\(nextDay.exercises.count) Übungen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Text(cycleManager.currentPhase.emoji)
                                        .font(.caption)
                                    Text(cycleManager.currentPhase.shortDescription)
                                        .font(.caption)
                                        .foregroundColor(cycleManager.currentPhase.color)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: UIColor.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            } else {
                // Fallback: Keine Trainingstage
                Text("Keine Trainingstage vorhanden")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(14)
            }
        }
    }
    
    // MARK: – Intelligente Trainingstag-Auswahl (NEU!)
    func determineNextWorkout(for program: WorkoutProgram) -> WorkoutDay? {
        let today = Weekday.from(date: Date())
        
        // 1. Prüfe ob heute ein geplanter Trainingstag ist
        if let todayWorkout = program.workoutDay(for: today) {
            return todayWorkout
        }
        
        // 2. Finde nächsten geplanten Trainingstag in dieser Woche
        let weekdays = Weekday.allCases
        let todayIndex = weekdays.firstIndex(of: today) ?? 0
        
        for offset in 1...7 {
            let nextIndex = (todayIndex + offset) % weekdays.count
            let nextWeekday = weekdays[nextIndex]
            if let workout = program.workoutDay(for: nextWeekday) {
                return workout
            }
        }
        
        // 3. Fallback: Erstes unvollständiges Training
        if let unfinished = program.sortedDays.first(where: { $0.completionPercent < 1.0 }) {
            return unfinished
        }
        
        // 4. Fallback: Erstes Training im Programm
        return program.sortedDays.first
    }

    // MARK: – Stats
    func statsRow(_ program: WorkoutProgram) -> some View {
        HStack(spacing: 12) {
            statTile(value: "\(program.completedWorkouts)", label: "Workouts",      icon: "dumbbell.fill",   color: accentColor)
            statTile(value: "\(program.days.count)",        label: "Trainingstage", icon: "calendar",        color: Color(hex: "#7B68EE"))
            statTile(value: "\(cycleManager.daysUntilNextPeriod)d", label: "bis Periode", icon: "moon.fill", color: Color(hex: "#E84393"))
        }
    }

    func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: – Schnell-Aktionen
    var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellzugriff")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                quickActionButton(icon: "dumbbell.fill",        label: "Training\nstarten",    color: accentColor,           tab: 1)
                quickActionButton(icon: "calendar.circle.fill", label: "Zyklus\nverwalten",    color: Color(hex: "#E84393"), tab: 2)
                quickActionButton(icon: "chart.bar.fill",       label: "Fortschritt\nansehen", color: Color(hex: "#7B68EE"), tab: 4)
            }
        }
    }

    func quickActionButton(icon: String, label: String, color: Color, tab: Int) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(color.opacity(0.08))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
