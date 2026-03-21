// HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var showAddProgram = false
    @State private var newProgramName = ""
    @State private var showAddDay     = false
    @State private var newDayName     = ""
    @State private var selectedProgram: WorkoutProgram?
    @State private var showTemplates = false

    var activeProgram: WorkoutProgram? { programs.first }
    
    var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.endTime != nil }
    }
    
    var thisWeekSessions: Int {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: .now) ?? .now
        return completedSessions.filter { $0.startTime >= weekAgo }.count
    }
    
    var activeSession: WorkoutSession? {
        allSessions.first { $0.endTime == nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    VStack(spacing: 20) {
                        // Aktive Session Banner - Größer & auffälliger
                        if let session = activeSession {
                            activeSessionBannerEnhanced(session)
                        }
                        
                        // Motivations-Card (NEU!)
                        motivationCard
                        
                        statsRow
                        if let program = activeProgram {
                            todaySection(program)
                            quickAccessRow
                        } else {
                            emptyState
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#FDF6F8"))
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showTemplates = true
                        } label: {
                            Label("Template nutzen", systemImage: "sparkles")
                        }
                        
                        Button {
                            showAddProgram = true
                        } label: {
                            Label("Eigenes Programm", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Neues Programm", isPresented: $showAddProgram) {
                TextField("Name (z.B. Push Pull Legs)", text: $newProgramName)
                Button("Erstellen") { createProgram() }
                Button("Abbrechen", role: .cancel) { newProgramName = "" }
            }
            .alert("Neuer Trainingstag", isPresented: $showAddDay) {
                TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
                Button("Hinzufügen") { addDay() }
                Button("Abbrechen", role: .cancel) { newDayName = "" }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatePickerView()
            }
        }
    }

    // MARK: – Header
    var headerSection: some View {
        ZStack {
            Color(hex: "#2D1B2E")
            Circle()
                .fill(Color(hex: "#4A1B4C").opacity(0.4))
                .frame(width: 160)
                .offset(x: 120, y: -60)
            Circle()
                .fill(Color(hex: "#3A1040").opacity(0.3))
                .frame(width: 100)
                .offset(x: -120, y: 60)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                            .font(.system(size: 11))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: "#C9A0D4"))
                        Text(greetingText)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text(greetingName)
                            .font(.system(size: 26).italic())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { cycleManager.isInPeriod },
                        set: { cycleManager.isInPeriod = $0 }
                    ))
                    .tint(Color(hex: "#E84393"))
                    .labelsHidden()
                    .padding(.top, 4)
                }
                .padding(.top, 10) // Reduziert von 60

                HStack(spacing: 16) {
                    cycleRing.frame(width: 90, height: 90)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aktuell")
                            .font(.system(size: 11))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: "#C9A0D4"))
                        Text(cycleManager.isInPeriod ? "Periode" : cyclePhaseName)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Text(cycleManager.cyclePhaseText)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#E879A0"))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 4) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i == 0 ? Color(hex: "#E879A0") : Color(hex: "#4A1B4C"))
                                    .frame(width: 20, height: 4)
                            }
                        }
                        .padding(.top, 2)
                        Text("Tag \(cycleManager.currentCycleDay) von \(cycleManager.cycleLength)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#C9A0D4"))
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 280) // Fixe Höhe
        .padding(.top, 1) // Damit SafeArea berücksichtigt wird
    }

    var cycleRing: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#4A1B4C"), lineWidth: 7)
            Circle()
                .trim(from: 0, to: cycleProgress)
                .stroke(Color(hex: "#E879A0"),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color(hex: "#3A1040"))
                .padding(12)
            VStack(spacing: 0) {
                Text("Tag")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                Text("\(cycleManager.currentCycleDay)")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#E879A0"))
            }
        }
    }

    var cycleProgress: Double {
        Double(cycleManager.currentCycleDay) / Double(cycleManager.cycleLength)
    }

    var cyclePhaseName: String {
        if cycleManager.daysUntilNextPeriod <= 3 { return "PMS-Phase" }
        if cycleManager.currentCycleDay <= 13    { return "Follikelphase" }
        return "Lutealphase"
    }

    var greetingName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "Nicole"
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Guten Morgen,"
        case 12..<18: return "Guten Tag,"
        case 18..<22: return "Guten Abend,"
        default: return "Gute Nacht,"
        }
    }
    
    // MARK: – Enhanced Active Session Banner (NEU!)
    func activeSessionBannerEnhanced(_ session: WorkoutSession) -> some View {
        VStack(spacing: 0) {
            // Oberer Teil - Animation
            HStack {
                // Pulsierender Kreis
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1D9E75").opacity(0.2))
                        .frame(width: 50, height: 50)
                    Circle()
                        .fill(Color(hex: "#1D9E75"))
                        .frame(width: 12, height: 12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("TRAINING LÄUFT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1)
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: "#1D9E75"))
                    
                    if let day = session.workoutDay {
                        Text(day.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                // Große Zeit-Anzeige
                VStack(spacing: 2) {
                    Text(session.durationFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1D9E75"))
                    Text("Minuten")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            
            // Unterer Teil - Quick Actions
            HStack(spacing: 12) {
                // Zum Training springen
                if let day = session.workoutDay {
                    NavigationLink(destination: WorkoutDayView(day: day)) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Weiter trainieren")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#1D9E75"))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#1D9E75").opacity(0.15), Color(hex: "#1D9E75").opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#1D9E75").opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color(hex: "#1D9E75").opacity(0.2), radius: 10, y: 5)
    }
    
    // MARK: – Motivations-Card (NEU!)
    var motivationCard: some View {
        let totalSessions = completedSessions.count
        let message: String
        let icon: String
        let color: Color
        
        if totalSessions == 0 {
            message = "Starte dein erstes Training! 🚀"
            icon = "star.fill"
            color = Color(hex: "#F4A623")
        } else if totalSessions < 5 {
            message = "Du bist auf einem guten Weg! Bleib dran! 💪"
            icon = "flame.fill"
            color = Color(hex: "#E84393")
        } else if thisWeekSessions >= 3 {
            message = "Wow! Schon \(thisWeekSessions)x diese Woche trainiert! 🔥"
            icon = "trophy.fill"
            color = Color(hex: "#F4A623")
        } else if cycleManager.isInPeriod {
            message = "Angepasster Modus - perfekt für deinen Zyklus! 🌸"
            icon = "heart.fill"
            color = Color(hex: "#E84393")
        } else {
            message = "Zeit für eine neue Session! Los geht's! ⚡"
            icon = "bolt.fill"
            color = Color(hex: "#1D9E75")
        }
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: – Old Active Session Banner (behalten für Fallback)
    func activeSessionBanner(_ session: WorkoutSession) -> some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "#1D9E75"))
                        .frame(width: 10, height: 10)
                    Text("Training läuft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
                Spacer()
                Text(session.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let day = session.workoutDay {
                HStack {
                    Text(day.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#1D9E75").opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: – Stats
    var statsRow: some View {
        HStack(spacing: 10) {
            StatCardEnhanced(
                value: "\(completedSessions.count)",
                label: "Sessions",
                sublabel: "abgeschlossen",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#1D9E75")
            )
            StatCardEnhanced(
                value: "\(thisWeekSessions)",
                label: "Diese Woche",
                sublabel: "Sessions",
                icon: "calendar",
                color: Color(hex: "#4A90D9")
            )
            StatCardEnhanced(
                value: "\(cycleManager.daysUntilNextPeriod)",
                label: "Bis Periode",
                sublabel: "Tage",
                icon: cycleManager.isInPeriod ? "heart.fill" : "clock.fill",
                color: cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#7B68EE")
            )
        }
    }

    // MARK: – Programm
    func todaySection(_ program: WorkoutProgram) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mein Programm")
                    .font(.system(size: 11))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "#A06080"))
                Spacer()
                Button {
                    selectedProgram = program
                    showAddDay = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(hex: "#E879A0"))
                }
            }
            ForEach(program.sortedDays) { day in
                NavigationLink(destination: WorkoutDayView(day: day)) {
                    WorkoutDayCard(day: day)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Schnellzugriff
    var quickAccessRow: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: ProgressChartView()) {
                QuickAccessCard(icon: "chart.bar.fill", title: "Fortschritt", subtitle: "ansehen")
            }
            .buttonStyle(.plain)
            NavigationLink(destination: CycleTrackerView()) {
                QuickAccessCard(icon: "arrow.clockwise.circle.fill", title: "Zyklus", subtitle: "verwalten")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: – Leerer Zustand
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#C9A0D4"))
            Text("Noch kein Programm")
                .font(.title3)
                .foregroundColor(Color(hex: "#2D1B2E"))
            Text("Erstelle dein erstes Trainingsprogramm und fang an zu tracken.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#A06080"))
                .multilineTextAlignment(.center)
            
            // Zwei Optionen
            VStack(spacing: 12) {
                // Template nutzen (Empfohlen!)
                Button {
                    showTemplates = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Template nutzen")
                                .fontWeight(.bold)
                            Text("Vorgefertigt & professionell")
                                .font(.caption)
                        }
                        Spacer()
                        Text("Empfohlen!")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F4A623"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#E84393"), Color(hex: "#E84393").opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                
                // Eigenes Programm
                Button {
                    showAddProgram = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Eigenes Programm erstellen")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(hex: "#E84393"))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#E84393"), lineWidth: 2)
                    )
                }
            }
        }
        .padding(.top, 40)
    }

    // MARK: – Aktionen
    func createProgram() {
        guard !newProgramName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        context.insert(WorkoutProgram(name: newProgramName))
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

// MARK: – Stat Card Enhanced (NEU!)
struct StatCardEnhanced: View {
    let value: String
    let label: String
    let sublabel: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon oben
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            // Wert
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            // Labels
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(sublabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            LinearGradient(
                colors: [color.opacity(0.1), color.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: – Stat Card (Alt - behalten)
struct StatCard: View {
    let value: String
    let label: String
    let sublabel: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(Color(hex: "#2D1B2E"))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "#A06080"))
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#C9A0B8"))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#F0D4E0"), lineWidth: 0.5))
    }
}

// MARK: – Quick Access Card
struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#FBEAF0"))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#E84393"))
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2D1B2E"))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#A06080"))
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#F0D4E0"), lineWidth: 0.5))
    }
}

// MARK: – WorkoutDayCard
struct WorkoutDayCard: View {
    @Bindable var cycleManager = CycleManager.shared
    let day: WorkoutDay

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    // Heutige Sessions
    var todaySessions: Int {
        day.sessions.filter { Calendar.current.isDateInToday($0.startTime) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Fortschritts-Ring - größer
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: day.completionPercent)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(day.completionPercent * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 6) {
                    Text(day.name)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#2D1B2E"))
                    
                    HStack(spacing: 12) {
                        Label("\(day.exercises.count)", systemImage: "dumbbell.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(day.completedSessions)", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Heutige Sessions-Anzeige
                    if todaySessions > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("Heute \(todaySessions)x trainiert!")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(accentColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(accentColor.opacity(0.7))
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color.white, accentColor.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.1), radius: 8, y: 4)
    }
}
