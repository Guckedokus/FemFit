// WorkoutCalendarView.swift
// FemFit – Workout Kalender mit Streak & Wochenplan
import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Query private var allSets: [WorkoutSet]
    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var allSessions: [WorkoutSession]
    
    var cycleManager = CycleManager.shared

    @State private var displayedMonth = Date()
    @State private var showProgramSettings = false

    var activeProgram: WorkoutProgram? { programs.first }
    
    var trainedDays: Set<String> {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return Set(allSets.map { fmt.string(from: $0.date) })
    }

    var periodDays: Set<String> {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return Set(allSets.filter { $0.isDuringPeriod }.map { fmt.string(from: $0.date) })
    }
    
    // NEU: Geplante Tage
    func isPlannedDay(_ date: Date) -> Bool {
        guard let program = activeProgram else { return false }
        let weekday = Weekday.from(date: date)
        return program.scheduledDays[weekday] != nil
    }
    
    // NEU: Welcher Trainingstag ist heute geplant?
    var todaysPlannedWorkout: WorkoutDay? {
        guard let program = activeProgram else { return nil }
        let today = Weekday.from(date: .now)
        return program.workoutDay(for: today)
    }
    
    // NEU: Wurde heute schon trainiert?
    var trainedToday: Bool {
        allSessions.contains { Calendar.current.isDateInToday($0.startTime) }
    }

    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: .now)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        
        // Wenn heute noch nicht trainiert, starte gestern
        if !trainedDays.contains(fmt.string(from: date)) {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        
        while trainedDays.contains(fmt.string(from: date)) {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }

    var longestStreak: Int {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let sorted = trainedDays.sorted()
        var longest = 0; var current = 0; var prevDate: Date? = nil
        for dateStr in sorted {
            guard let date = fmt.date(from: dateStr) else { continue }
            if let prev = prevDate, Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: prev)!) {
                current += 1
            } else { current = 1 }
            longest = max(longest, current)
            prevDate = date
        }
        return longest
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // NEU: Heute geplant Banner
                    if let workout = todaysPlannedWorkout {
                        todaysBanner(workout: workout)
                    }
                    
                    streakBanner
                    
                    // NEU: Wochenplan Übersicht
                    if let program = activeProgram, !program.scheduledDays.isEmpty {
                        weeklyScheduleCard(program: program)
                    }
                    
                    calendarCard
                    statsRow
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Kalender")
            .toolbar {
                if activeProgram != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showProgramSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProgramSettings) {
                if let program = activeProgram {
                    ProgramSettingsView(program: program)
                }
            }
        }
    }
    
    // MARK: – NEU: Heute's Banner
    func todaysBanner(workout: WorkoutDay) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Heute geplant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    HStack(spacing: 8) {
                        Text(workout.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if trainedToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if trainedToday {
                        Text("✅ Bereits absolviert!")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("\(workout.exercises.count) Übungen warten auf dich")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !trainedToday {
                    NavigationLink(destination: WorkoutDayView(day: workout)) {
                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 32))
                            Text("Start")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75"))
                    }
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: trainedToday
                    ? [Color.green.opacity(0.15), Color.green.opacity(0.05)]
                    : [Color(hex: "#4A90D9").opacity(0.15), Color(hex: "#4A90D9").opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(trainedToday ? Color.green.opacity(0.3) : Color(hex: "#4A90D9").opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: – NEU: Wochenplan Übersicht
    func weeklyScheduleCard(program: WorkoutProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dein Wochenplan")
                    .font(.headline)
                Spacer()
                Text("\(program.weeklyFrequency)x pro Woche")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#4A90D9"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#4A90D9").opacity(0.15))
                    .cornerRadius(8)
            }
            
            // Wochentage
            VStack(spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { weekday in
                    if let dayIndex = program.scheduledDays[weekday],
                       let workoutDay = program.sortedDays[safe: dayIndex] {
                        HStack {
                            Text(weekday.shortName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "#4A90D9"))
                                .cornerRadius(6)
                            
                            Text(workoutDay.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Check ob heute und ob absolviert
                            if Calendar.current.isDateInToday(Date()) && Weekday.from(date: .now) == weekday {
                                if trainedToday {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // ── Streak Banner ──
    var streakBanner: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.system(size: 44))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak) Tage Streak")
                    .font(.title2).fontWeight(.bold)
                Text(currentStreak == 0 ? "Trainiere heute um deinen Streak zu starten!" : "Weiter so! Du bist auf dem richtigen Weg 💪")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#F4A623").opacity(0.12))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F4A623").opacity(0.3), lineWidth: 1))
    }

    // ── Kalender ──
    var calendarCard: some View {
        VStack(spacing: 12) {
            // Monats-Navigation
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").foregroundColor(.primary) }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right").foregroundColor(.primary) }
            }

            // Wochentage
            HStack {
                ForEach(["Mo","Di","Mi","Do","Fr","Sa","So"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }

            // Tage Grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                }
            }

            // Legende
            HStack(spacing: 12) {
                legendItem(color: Color(hex: "#1D9E75"), label: "Absolviert")
                legendItem(color: Color(hex: "#4A90D9").opacity(0.3), label: "Geplant")
                legendItem(color: Color(uiColor: UIColor.systemGray5), label: "Frei")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func dayCell(_ day: Date?) -> some View {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let isToday   = day.map { Calendar.current.isDateInToday($0) } ?? false
        let trained   = day.map { trainedDays.contains(fmt.string(from: $0)) } ?? false
        let inPeriod  = day.map { periodDays.contains(fmt.string(from: $0)) } ?? false
        let planned   = day.map { isPlannedDay($0) } ?? false
        let dayNum    = day.map { Calendar.current.component(.day, from: $0) }

        return ZStack {
            if trained {
                Circle().fill(inPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75"))
            } else if planned {
                Circle().stroke(Color(hex: "#4A90D9"), lineWidth: 2)
                    .background(Circle().fill(Color(hex: "#4A90D9").opacity(0.1)))
            } else if isToday {
                Circle().stroke(Color.primary, lineWidth: 1.5)
            }
            if let n = dayNum {
                Text("\(n)")
                    .font(.system(size: 13, weight: isToday || trained ? .semibold : .regular))
                    .foregroundColor(trained ? .white : (planned ? Color(hex: "#4A90D9") : .primary))
            }
        }
        .frame(height: 34)
        .opacity(day == nil ? 0 : 1)
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    // ── Stats ──
    var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(currentStreak)🔥", label: "Aktuell")
            statTile(value: "\(longestStreak)⭐", label: "Rekord")
            statTile(value: "\(trainedDays.count)", label: "Gesamt")
        }
    }

    func statTile(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(14)
        .background(Color(hex: "#F4A623").opacity(0.1)).cornerRadius(14)
    }

    // ── Hilfsfunktionen ──
    var monthTitle: String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"; fmt.locale = Locale(identifier: "de_DE")
        return fmt.string(from: displayedMonth)
    }

    func changeMonth(_ delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }

        let weekday = (cal.component(.weekday, from: first) + 5) % 7  // Mo=0
        var result: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            result.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }
}
