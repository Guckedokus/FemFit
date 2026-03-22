// CycleTrackerView.swift
// FemFit – Zyklus-Tracking Screen
// Einfügen in Xcode: File > New > File > Swift File > "CycleTrackerView"

import SwiftUI

struct CycleTrackerView: View {

    var cycleManager = CycleManager.shared
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var selectedCalendarDay: Int?
    @State private var showDayDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Zyklus-Übersicht Ring ──
                    cycleRing

                    // ── Status-Karten ──
                    statusCards

                    // ── Zyklus einstellen ──
                    settingsCard

                    // ── Kalender-Vorschau ──
                    calendarCard

                    // ── Phasen-Erklärung ──
                    phasesCard

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Mein Zyklus")
            .sheet(isPresented: $showDayDetail) {
                if let dayOffset = selectedCalendarDay {
                    DayDetailSheet(dayOffset: dayOffset, cycleManager: cycleManager)
                        .presentationDetents([.medium])
                }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Zyklus-Ring
    // ───────────────────────────────────────────

    var cycleRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 18)

                // Periode-Phase (Anfang)
                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(cycleManager.periodLength) / CGFloat(cycleManager.cycleLength)
                    )
                    .stroke(Color(hex: "#E84393"), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Aktueller Tag
                Circle()
                    .trim(
                        from: CGFloat(cycleManager.currentCycleDay - 1) / CGFloat(cycleManager.cycleLength) - 0.01,
                        to:   CGFloat(cycleManager.currentCycleDay)     / CGFloat(cycleManager.cycleLength) + 0.01
                    )
                    .stroke(Color(hex: "#1D9E75"), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Mitte-Text
                VStack(spacing: 4) {
                    Text("Tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cycleManager.currentCycleDay)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("von \(cycleManager.cycleLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Aktueller Status
            Text(cycleManager.cyclePhaseText)
                .font(.headline)
                .foregroundColor(cycleManager.cyclePhaseColor)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Status-Karten
    // ───────────────────────────────────────────

    var statusCards: some View {
        HStack(spacing: 12) {
            infoTile(
                icon: "calendar",
                label: "Nächste Periode",
                value: "\(cycleManager.daysUntilNextPeriod) Tage",
                color: Color(hex: "#E84393")
            )
            infoTile(
                icon: "moon.fill",
                label: "Perioden-Länge",
                value: "\(cycleManager.periodLength) Tage",
                color: Color(hex: "#7B68EE")
            )
            infoTile(
                icon: "arrow.clockwise",
                label: "Zykluslänge",
                value: "\(cycleManager.cycleLength) Tage",
                color: Color(hex: "#1D9E75")
            )
        }
    }

    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline).fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }

    // ───────────────────────────────────────────
    // MARK: – Einstellungen
    // ───────────────────────────────────────────

    var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zyklus einrichten")
                .font(.headline)

            // Letzter Perioden-Start
            VStack(alignment: .leading, spacing: 6) {
                Text("Letzter Perioden-Start")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack {
                        Text(cycleManager.periodStartDate, style: .date)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#E84393"))
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                }

                if showDatePicker {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { cycleManager.periodStartDate },
                            set: { cycleManager.periodStartDate = $0 }
                        ),
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: "#E84393"))
                }
            }

            Divider()

            // Zykluslänge
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Zykluslänge")
                        .font(.subheadline)
                    Spacer()
                    Text("\(cycleManager.cycleLength) Tage")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
                Slider(
                    value: Binding(
                        get: { Double(cycleManager.cycleLength) },
                        set: { cycleManager.cycleLength = Int($0) }
                    ),
                    in: 21...35, step: 1
                )
                .tint(Color(hex: "#1D9E75"))
            }

            Divider()

            // Perioden-Länge
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Perioden-Länge")
                        .font(.subheadline)
                    Spacer()
                    Text("\(cycleManager.periodLength) Tage")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#E84393"))
                }
                Slider(
                    value: Binding(
                        get: { Double(cycleManager.periodLength) },
                        set: { cycleManager.periodLength = Int($0) }
                    ),
                    in: 2...10, step: 1
                )
                .tint(Color(hex: "#E84393"))
            }

            // Aktualisieren-Button
            Button {
                cycleManager.checkAndUpdateCycle()
            } label: {
                Label("Zyklus aktualisieren", systemImage: "arrow.clockwise")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(hex: "#E84393"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Kalender-Vorschau
    // ───────────────────────────────────────────

    var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Die nächsten 14 Tage")
                    .font(.headline)
                Spacer()
                Text(cycleManager.currentPhase.emoji)
                    .font(.title2)
            }

            // Wochentags-Header
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // Kalender-Grid: 2 Wochen
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(0..<14, id: \.self) { dayOffset in
                    calendarDayCell(dayOffset: dayOffset)
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Legende & Anstehende Events
            VStack(alignment: .leading, spacing: 8) {
                Text("Anstehende Ereignisse:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if let nextPeriodDays = nextEventDays(.menstruation) {
                    eventRow(
                        icon: "🩸",
                        text: "Periode startet",
                        days: nextPeriodDays,
                        color: Color(hex: "#E84393")
                    )
                }
                
                if let nextOvulationDays = nextEventDays(.ovulation) {
                    eventRow(
                        icon: "🥚",
                        text: "Ovulation",
                        days: nextOvulationDays,
                        color: Color(hex: "#F4A623")
                    )
                }
                
                if let nextFollicularDays = nextEventDays(.follicular) {
                    eventRow(
                        icon: "💪",
                        text: "Power-Phase (Follikel)",
                        days: nextFollicularDays,
                        color: Color(hex: "#1D9E75")
                    )
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    func eventRow(icon: String, text: String, days: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Text(days == 0 ? "Heute!" : "in \(days) Tag\(days == 1 ? "" : "en")")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }

    // Finde nächstes Ereignis einer bestimmten Phase
    func nextEventDays(_ targetPhase: CyclePhase) -> Int? {
        for dayOffset in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let phase = phaseForDate(date)
            
            // Prüfe ob Phase gerade startet (vorheriger Tag hatte andere Phase)
            if dayOffset == 0 && phase == targetPhase {
                return 0
            }
            
            if dayOffset > 0 {
                let previousDate = Calendar.current.date(byAdding: .day, value: dayOffset - 1, to: Date()) ?? Date()
                let previousPhase = phaseForDate(previousDate)
                
                if phase == targetPhase && previousPhase != targetPhase {
                    return dayOffset
                }
            }
        }
        return nil
    }

    func calendarDayCell(dayOffset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let dayNumber = Calendar.current.component(.day, from: date)
        let phase = phaseForDate(date)
        let isToday = dayOffset == 0
        
        return VStack(spacing: 4) {
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundColor(isToday ? .white : .primary)
            
            // Phase-Indikator
            Circle()
                .fill(phase.color)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isToday ? Color(hex: "#1D9E75") : phase.color.opacity(0.15))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(phase.color.opacity(0.4), lineWidth: isToday ? 2 : 0)
        )
        .onTapGesture {
            selectedCalendarDay = dayOffset
            showDayDetail = true
        }
    }

    // Berechne Phase für ein bestimmtes Datum
    func phaseForDate(_ date: Date) -> CyclePhase {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleManager.periodStartDate, to: date).day ?? 0
        let dayInCycle = (daysSinceStart % cycleManager.cycleLength) + 1
        
        if dayInCycle <= cycleManager.periodLength {
            return .menstruation
        } else if dayInCycle <= 13 {
            return .follicular
        } else if dayInCycle <= 16 {
            return .ovulation
        } else {
            return .luteal
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Phasen-Erklärung
    // ───────────────────────────────────────────

    var phasesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dein Zyklus & Training")
                .font(.headline)

            phaseRow(
                color: Color(hex: "#E84393"),
                phase: "Periode (Tag 1–5)",
                desc: "Leichtere Gewichte normal – Hormonspiegel senkt Kraft. Kein Rückschritt!"
            )
            phaseRow(
                color: Color(hex: "#1D9E75"),
                phase: "Follikelphase (Tag 6–13)",
                desc: "Östrogen steigt – beste Zeit für PR-Versuche und schwere Gewichte!"
            )
            phaseRow(
                color: Color(hex: "#7B68EE"),
                phase: "Ovulation (Tag 14)",
                desc: "Höchste Kraft und Energie. Perfekt für Maximalleistung."
            )
            phaseRow(
                color: Color(hex: "#F4A623"),
                phase: "Lutealphase (Tag 15–28)",
                desc: "Progeste­ron steigt. Gut trainierbar, Regeneration priorisieren."
            )
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    func phaseRow(color: Color, phase: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(phase)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(color)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
// ───────────────────────────────────────────
// MARK: – Tag-Detail Sheet
// ───────────────────────────────────────────

struct DayDetailSheet: View {
    let dayOffset: Int
    let cycleManager: CycleManager
    @Environment(\.dismiss) var dismiss
    
    private var date: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }
    
    private var phase: CyclePhase {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleManager.periodStartDate, to: date).day ?? 0
        let dayInCycle = (daysSinceStart % cycleManager.cycleLength) + 1
        
        if dayInCycle <= cycleManager.periodLength {
            return .menstruation
        } else if dayInCycle <= 13 {
            return .follicular
        } else if dayInCycle <= 16 {
            return .ovulation
        } else {
            return .luteal
        }
    }
    
    private var cycleDay: Int {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleManager.periodStartDate, to: date).day ?? 0
        return (daysSinceStart % cycleManager.cycleLength) + 1
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header mit Datum
                    VStack(spacing: 8) {
                        Text(date, style: .date)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tag \(cycleDay) deines Zyklus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Phase-Badge
                    HStack(spacing: 12) {
                        Text(phase.emoji)
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase.rawValue)
                                .font(.headline)
                                .foregroundColor(phase.color)
                            
                            Text(phase.shortDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(phase.color.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Trainings-Empfehlung
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Training an diesem Tag", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)
                        
                        Text(phase.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        HStack {
                            Text("Gewichts-Multiplikator:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(phase.weightMultiplier * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(phase.color)
                        }
                        
                        // Visualisierung des Multiplikators
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(phase.color)
                                    .frame(width: geometry.size.width * phase.weightMultiplier, height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Tipps
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tipps für diesen Tag", systemImage: "lightbulb.fill")
                            .font(.headline)
                        
                        ForEach(tipsForPhase, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(phase.color)
                                    .font(.caption)
                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var tipsForPhase: [String] {
        switch phase {
        case .menstruation:
            return [
                "Reduziere Gewichte um 25%",
                "Fokus auf Technik statt Kraft",
                "Mehr Pausen zwischen Sätzen",
                "Viel Wasser trinken"
            ]
        case .follicular:
            return [
                "Beste Zeit für PR-Versuche!",
                "Schwere Gewichte möglich",
                "Maximale Kraft verfügbar",
                "Nutze diese Power-Phase"
            ]
        case .ovulation:
            return [
                "Peak Performance!",
                "Maximalversuche möglich",
                "Hohe Energie nutzen",
                "Regeneration nicht vergessen"
            ]
        case .luteal:
            return [
                "Gewichte um 15% reduzieren",
                "Fokus auf Regeneration",
                "Mehr Schlaf einplanen",
                "Ernährung anpassen"
            ]
        }
    }
}


