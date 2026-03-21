// CycleManager.swift
// FemFit – Zyklus-Logik & Push Notifications
// FIXED: @Observable statt ObservableObject

import Foundation
import SwiftUI
import UserNotifications

// ───────────────────────────────────────────
// MARK: – Zyklus-Phasen Enum
// ───────────────────────────────────────────

enum CyclePhase: String, Codable, CaseIterable {
    case menstruation = "Menstruation"
    case follicular   = "Follikelphase"
    case ovulation    = "Ovulation"
    case luteal       = "Lutealphase"
    
    // Emoji für jede Phase
    var emoji: String {
        switch self {
        case .menstruation: return "🩸"
        case .follicular:   return "🌱"
        case .ovulation:    return "🥚"
        case .luteal:       return "🌙"
        }
    }
    
    // Farbe für jede Phase
    var color: Color {
        switch self {
        case .menstruation: return Color(hex: "#E84393")  // Pink
        case .follicular:   return Color(hex: "#1D9E75")  // Grün
        case .ovulation:    return Color(hex: "#F4A623")  // Gold/Orange
        case .luteal:       return Color(hex: "#7B68EE")  // Lila
        }
    }
    
    // Gewichts-Multiplikator (basierend auf wissenschaftlichen Studien)
    var weightMultiplier: Double {
        switch self {
        case .menstruation: return 0.75  // 75% - Reduziert wegen niedriger Hormone
        case .follicular:   return 1.00  // 100% - PEAK PERFORMANCE!
        case .ovulation:    return 0.98  // 98% - Immer noch sehr gut
        case .luteal:       return 0.85  // 85% - Progesteron steigt, Energie sinkt
        }
    }
    
    // Beschreibung
    var description: String {
        switch self {
        case .menstruation: return "Leichte Gewichte – dein Körper braucht Schonung"
        case .follicular:   return "POWER-Phase! Nutze deine maximale Kraft"
        case .ovulation:    return "Höchste Energie – perfekt für schwere Gewichte"
        case .luteal:       return "Moderate Gewichte – Energie nimmt ab"
        }
    }
    
    // Kurzbeschreibung
    var shortDescription: String {
        switch self {
        case .menstruation: return "Schonend"
        case .follicular:   return "Power!"
        case .ovulation:    return "Peak"
        case .luteal:       return "Moderat"
        }
    }
}

// ───────────────────────────────────────────
// MARK: – CycleManager (Herzstück der App)
// ───────────────────────────────────────────

@Observable
class CycleManager {

    static let shared = CycleManager()

    var isInPeriod: Bool {
        get { UserDefaults.standard.bool(forKey: "isInPeriod") }
        set { UserDefaults.standard.set(newValue, forKey: "isInPeriod") }
    }
    
    // NEU: Aktuelle Zyklus-Phase
    var currentPhase: CyclePhase {
        let day = currentCycleDay
        
        // Menstruation: Tag 1-5 (periodLength)
        if day <= periodLength {
            return .menstruation
        }
        // Follikelphase: Tag 6-13
        else if day <= 13 {
            return .follicular
        }
        // Ovulation: Tag 14-16
        else if day <= 16 {
            return .ovulation
        }
        // Lutealphase: Tag 17-28
        else {
            return .luteal
        }
    }
    
    // NEU: Gewichts-Multiplikator für aktuelle Phase
    var currentWeightMultiplier: Double {
        currentPhase.weightMultiplier
    }
    
    var cycleLength: Int {
        get { let v = UserDefaults.standard.integer(forKey: "cycleLength"); return v == 0 ? 28 : v }
        set { UserDefaults.standard.set(newValue, forKey: "cycleLength") }
    }
    var periodLength: Int {
        get { let v = UserDefaults.standard.integer(forKey: "periodLength"); return v == 0 ? 5 : v }
        set { UserDefaults.standard.set(newValue, forKey: "periodLength") }
    }
    var notifyEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "notifyEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyEnabled") }
    }
    var notifyHour: Int {
        get { let v = UserDefaults.standard.integer(forKey: "notifyHour"); return v == 0 ? 8 : v }
        set { UserDefaults.standard.set(newValue, forKey: "notifyHour") }
    }
    private var periodStartTS: Double {
        get { let v = UserDefaults.standard.double(forKey: "periodStartTS"); return v == 0 ? Date.now.timeIntervalSince1970 : v }
        set { UserDefaults.standard.set(newValue, forKey: "periodStartTS") }
    }

    // Letzter Perioden-Starttermin
    var periodStartDate: Date {
        get { Date(timeIntervalSince1970: periodStartTS) }
        set {
            periodStartTS = newValue.timeIntervalSince1970
            checkAndUpdateCycle()
            scheduleAllNotifications()
        }
    }

    // Nächster Perioden-Start
    var nextPeriodDate: Date {
        Calendar.current.date(byAdding: .day, value: cycleLength, to: periodStartDate) ?? .now
    }

    // Wie viele Tage bis zur nächsten Periode
    var daysUntilNextPeriod: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: nextPeriodDate).day ?? 0)
    }

    // Welcher Tag im Zyklus ist heute (1-28)
    var currentCycleDay: Int {
        let days = Calendar.current.dateComponents([.day], from: periodStartDate, to: .now).day ?? 0
        return (days % cycleLength) + 1
    }

    // Zyklus-Phase als Text
    var cyclePhaseText: String {
        currentPhase.description
    }

    var cyclePhaseColor: Color {
        currentPhase.color
    }
    
    // Legacy-Support: Alte Funktion bleibt für Kompatibilität
    var cyclePhaseTextOld: String {
        if isInPeriod { return "Periode – leichtere Gewichte aktiv" }
        if daysUntilNextPeriod <= 3 { return "PMS-Phase – demnächst Periode" }
        if currentCycleDay <= 13 { return "Follikelphase – beste Kraftwerte" }
        return "Lutealphase – gut zum Trainieren"
    }

    // ── Zyklus prüfen und ggf. Modus wechseln ──

    func checkAndUpdateCycle() {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: periodStartDate, to: .now).day ?? 0
        let dayInCycle = daysSinceStart % cycleLength
        let shouldBeInPeriod = dayInCycle < periodLength
        if isInPeriod != shouldBeInPeriod {
            withAnimation { isInPeriod = shouldBeInPeriod }
        }
    }

    // Nächsten Perioden-Start vorausberechnen und speichern
    func advanceToNextCycle() {
        periodStartDate = nextPeriodDate
    }
}

// ───────────────────────────────────────────
// MARK: – Push Notifications
// ───────────────────────────────────────────

extension CycleManager {
    
    // Berechne Streak basierend auf Sessions
    func calculateStreak(sessions: [WorkoutSession]) -> Int {
        let completedSessions = sessions.filter { $0.endTime != nil }
        guard !completedSessions.isEmpty else { return 0 }
        
        var streak = 0
        var date = Calendar.current.startOfDay(for: .now)
        let sessionDates = Set(completedSessions.map { Calendar.current.startOfDay(for: $0.startTime) })
        
        while sessionDates.contains(date) {
            streak += 1
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
        }
        
        return streak
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { self.scheduleAllNotifications() }
        }
    }

    func scheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard notifyEnabled else { return }
        schedulePeriodWarning()
        scheduleWorkoutReminder()
    }

    // Benachrichtigung 1 Tag vor der Periode
    private func schedulePeriodWarning() {
        guard let warningDate = Calendar.current.date(byAdding: .day, value: -1, to: nextPeriodDate) else { return }
        guard warningDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Periode startet morgen 🌸"
        content.body  = "Deine Perioden-Gewichte werden automatisch aktiviert. Du schaffst das!"
        content.sound = .default

        var dc = Calendar.current.dateComponents([.year, .month, .day], from: warningDate)
        dc.hour = notifyHour
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let request = UNNotificationRequest(identifier: "period-warning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Tägliche Trainings-Erinnerung
    func scheduleWorkoutReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Zeit für dein Training! 💪"
        content.body  = isInPeriod
            ? "Periode-Tag – leichte Gewichte, trotzdem stark!"
            : "Heute ist ein guter Tag um stärker zu werden."
        content.sound = .default

        var dc = DateComponents()
        dc.hour   = notifyHour
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: "workout-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// ───────────────────────────────────────────
// MARK: – Hilfserweiterung für Hex-Farben
// ───────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
