// Models.swift
// FemFit – alle Datenmodelle (erweitert)

import Foundation
import SwiftData

// ── Trainingsprogramm ──────────────────────
@Model final class WorkoutProgram {
    var name: String
    var createdAt: Date
    var weeklyFrequency: Int = 3  // NEU: Wie oft pro Woche trainieren?
    var scheduledDaysRaw: String? // NEU: JSON mit Wochenplan (z.B. "Mon:0,Wed:1,Fri:2")
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay] = []
    
    init(name: String) { self.name = name; self.createdAt = .now }
    
    var sortedDays: [WorkoutDay] { days.sorted { $0.order < $1.order } }
    var completedWorkouts: Int { days.reduce(0) { $0 + $1.completedSessions } }
    
    // NEU: Geplante Tage der Woche
    var scheduledDays: [Weekday: Int] {
        get {
            guard let raw = scheduledDaysRaw else { return [:] }
            var result: [Weekday: Int] = [:]
            let pairs = raw.split(separator: ",")
            for pair in pairs {
                let parts = pair.split(separator: ":")
                if parts.count == 2,
                   let weekday = Weekday(rawValue: String(parts[0])),
                   let dayIndex = Int(parts[1]) {
                    result[weekday] = dayIndex
                }
            }
            return result
        }
        set {
            scheduledDaysRaw = newValue.map { "\($0.key.rawValue):\($0.value)" }.joined(separator: ",")
        }
    }
    
    // NEU: Trainingstag für bestimmten Wochentag
    func workoutDay(for weekday: Weekday) -> WorkoutDay? {
        guard let dayIndex = scheduledDays[weekday] else { return nil }
        return sortedDays[safe: dayIndex]
    }
}

// NEU: Wochentag-Enum
enum Weekday: String, Codable, CaseIterable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
    
    var displayName: String {
        switch self {
        case .monday: return "Montag"
        case .tuesday: return "Dienstag"
        case .wednesday: return "Mittwoch"
        case .thursday: return "Donnerstag"
        case .friday: return "Freitag"
        case .saturday: return "Samstag"
        case .sunday: return "Sonntag"
        }
    }
    
    var shortName: String {
        switch self {
        case .monday: return "Mo"
        case .tuesday: return "Di"
        case .wednesday: return "Mi"
        case .thursday: return "Do"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        case .sunday: return "So"
        }
    }
    
    static func from(date: Date) -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: date)
        // Calendar.weekday: 1 = Sunday, 2 = Monday, etc.
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

// NEU: Array Extension für safe access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// ── Trainingstag ───────────────────────────
@Model final class WorkoutDay {
    var name: String
    var order: Int
    var program: WorkoutProgram?
    @Relationship(deleteRule: .cascade, inverse: \Exercise.day)
    var exercises: [Exercise] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.workoutDay)
    var sessions: [WorkoutSession] = []
    
    init(name: String, order: Int) { self.name = name; self.order = order }
    var sortedExercises: [Exercise] { exercises.sorted { $0.order < $1.order } }
    var completionPercent: Double {
        guard !exercises.isEmpty else { return 0 }
        let logged = exercises.filter { !$0.sets.isEmpty }.count
        return Double(logged) / Double(exercises.count)
    }
    var completedSessions: Int {
        sessions.filter { $0.endTime != nil }.count
    }
    
    // Aktive Session heute
    var activeSession: WorkoutSession? {
        let today = Calendar.current.startOfDay(for: .now)
        return sessions.first {
            $0.isActive && Calendar.current.startOfDay(for: $0.date) == today
        }
    }
    
    // Heutige abgeschlossene Übungen (optional: ab einem bestimmten Session-Zeitpunkt)
    func completedExercises(since cutoff: Date) -> Int {
        exercises.filter { exercise in
            exercise.sets.contains { $0.date >= cutoff }
        }.count
    }
    
    var todayCompletedExercises: Int {
        // Verwendet den Start der aktiven Session als Cutoff, damit zweite Sessions sauber starten
        let cutoff = activeSession?.startTime ?? Calendar.current.startOfDay(for: .now)
        return completedExercises(since: cutoff)
    }
}

// ── Übung ──────────────────────────────────
@Model final class Exercise {
    var name: String
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var notes: String
    var day: WorkoutDay?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []
    init(name: String, order: Int, targetSets: Int = 3, targetReps: Int = 10, notes: String = "") {
        self.name = name; self.order = order
        self.targetSets = targetSets; self.targetReps = targetReps; self.notes = notes
    }
    
    // Legacy: Alte 2-Phasen-Logik (bleibt für Kompatibilität)
    var normalSets: [WorkoutSet]  { sets.filter { !$0.isDuringPeriod }.sorted { $0.date < $1.date } }
    var periodSets: [WorkoutSet]  { sets.filter {  $0.isDuringPeriod }.sorted { $0.date < $1.date } }
    func lastWeight(period: Bool) -> Double? { (period ? periodSets : normalSets).last?.weight }
    func lastReps(period: Bool)   -> Int?    { (period ? periodSets : normalSets).last?.reps }
    
    // NEU: 4-Phasen-Logik
    func sets(for phase: CyclePhase) -> [WorkoutSet] {
        sets.filter { $0.cyclePhase == phase }.sorted { $0.date < $1.date }
    }
    
    func lastWeight(for phase: CyclePhase) -> Double? {
        sets(for: phase).last?.weight
    }
    
    func lastReps(for phase: CyclePhase) -> Int? {
        sets(for: phase).last?.reps
    }
    
    // NEU: Gewichts-Vorschlag basierend auf Phase
    func suggestedWeight(for phase: CyclePhase) -> Double? {
        // Versuche zuerst Daten aus derselben Phase
        if let lastInPhase = lastWeight(for: phase) {
            return lastInPhase
        }
        
        // Fallback: Nutze Follikelphase als Basis (100%) und skaliere
        if let follicularWeight = lastWeight(for: .follicular) {
            return follicularWeight * phase.weightMultiplier
        }
        
        // Fallback 2: Nutze irgendein Gewicht und skaliere
        if let anyWeight = sets.last?.weight {
            return anyWeight * phase.weightMultiplier
        }
        
        return nil
    }
    
    var todayCompletion: Double {
        let today = Calendar.current.startOfDay(for: .now)
        let todaySets = sets.filter { Calendar.current.startOfDay(for: $0.date) == today }
        guard targetSets > 0 else { return 0 }
        return min(1.0, Double(todaySets.count) / Double(targetSets))
    }
}

// ── Satz ───────────────────────────────────
@Model final class WorkoutSet {
    var weight: Double
    var reps: Int
    var setNumber: Int
    var date: Date
    var isDuringPeriod: Bool
    var cyclePhaseRaw: String?  // NEU: Speichert die Phase (rawValue von CyclePhase)
    var note: String
    var exercise: Exercise?
    
    init(weight: Double, reps: Int, setNumber: Int, isDuringPeriod: Bool, note: String = "", cyclePhase: CyclePhase? = nil) {
        self.weight = weight; self.reps = reps; self.setNumber = setNumber
        self.date = .now; self.isDuringPeriod = isDuringPeriod; self.note = note
        self.cyclePhaseRaw = cyclePhase?.rawValue
    }
    
    // Helper: Phase zurückholen
    var cyclePhase: CyclePhase? {
        get {
            guard let raw = cyclePhaseRaw else { return nil }
            return CyclePhase(rawValue: raw)
        }
        set {
            cyclePhaseRaw = newValue?.rawValue
        }
    }
}

// ── Körpermaße ─────────────────────────────
@Model final class BodyMeasurement {
    var date: Date
    var weight: Double?         // kg
    var bodyFat: Double?        // %
    var muscleMass: Double?     // kg
    var waist: Double?          // cm
    var hips: Double?           // cm
    var chest: Double?          // cm
    var isDuringPeriod: Bool

    init(date: Date = .now, weight: Double? = nil, bodyFat: Double? = nil,
         muscleMass: Double? = nil, waist: Double? = nil, hips: Double? = nil,
         chest: Double? = nil, isDuringPeriod: Bool = false) {
        self.date = date; self.weight = weight; self.bodyFat = bodyFat
        self.muscleMass = muscleMass; self.waist = waist; self.hips = hips
        self.chest = chest; self.isDuringPeriod = isDuringPeriod
    }
}

// ── Achievement / Badge ────────────────────
@Model final class Achievement {
    var id: String
    var unlockedAt: Date
    init(id: String) { self.id = id; self.unlockedAt = .now }
}

// ── Workout Session ────────────────────────
@Model final class WorkoutSession {
    var date: Date
    var workoutDay: WorkoutDay?
    var startTime: Date
    var endTime: Date?
    var isDuringPeriod: Bool
    var cyclePhaseRaw: String?  // NEU: Speichert die Phase
    var completedExerciseCount: Int
    
    init(workoutDay: WorkoutDay?, isDuringPeriod: Bool, cyclePhase: CyclePhase? = nil) {
        self.date = Calendar.current.startOfDay(for: .now)
        self.workoutDay = workoutDay
        self.startTime = .now
        self.isDuringPeriod = isDuringPeriod
        self.cyclePhaseRaw = cyclePhase?.rawValue
        self.completedExerciseCount = 0
    }
    
    // Helper: Phase zurückholen
    var cyclePhase: CyclePhase? {
        get {
            guard let raw = cyclePhaseRaw else { return nil }
            return CyclePhase(rawValue: raw)
        }
        set {
            cyclePhaseRaw = newValue?.rawValue
        }
    }
    
    var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        }
        return Date.now.timeIntervalSince(startTime)
    }
    
    var durationFormatted: String {
        let mins = Int(duration / 60)
        if mins < 60 {
            return "\(mins) Min"
        } else {
            let hours = mins / 60
            let remainingMins = mins % 60
            return "\(hours)h \(remainingMins)m"
        }
    }
    
    var isActive: Bool {
        endTime == nil
    }
}



