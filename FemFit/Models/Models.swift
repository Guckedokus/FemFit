// Models.swift
// FemFit – alle Datenmodelle (erweitert)

import Foundation
import SwiftData

// ── Trainingsprogramm ──────────────────────
@Model final class WorkoutProgram {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay] = []
    init(name: String) { self.name = name; self.createdAt = .now }
    var sortedDays: [WorkoutDay] { days.sorted { $0.order < $1.order } }
    var completedWorkouts: Int { days.reduce(0) { $0 + $1.completedSessions } }
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
    
    // Heutige abgeschlossene Übungen
    var todayCompletedExercises: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return exercises.filter { exercise in
            let todaySets = exercise.sets.filter { Calendar.current.startOfDay(for: $0.date) == today }
            return !todaySets.isEmpty
        }.count
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
    var normalSets: [WorkoutSet]  { sets.filter { !$0.isDuringPeriod }.sorted { $0.date < $1.date } }
    var periodSets: [WorkoutSet]  { sets.filter {  $0.isDuringPeriod }.sorted { $0.date < $1.date } }
    func lastWeight(period: Bool) -> Double? { (period ? periodSets : normalSets).last?.weight }
    func lastReps(period: Bool)   -> Int?    { (period ? periodSets : normalSets).last?.reps }
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
    var note: String
    var exercise: Exercise?
    init(weight: Double, reps: Int, setNumber: Int, isDuringPeriod: Bool, note: String = "") {
        self.weight = weight; self.reps = reps; self.setNumber = setNumber
        self.date = .now; self.isDuringPeriod = isDuringPeriod; self.note = note
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
    var completedExerciseCount: Int
    
    init(workoutDay: WorkoutDay?, isDuringPeriod: Bool) {
        self.date = Calendar.current.startOfDay(for: .now)
        self.workoutDay = workoutDay
        self.startTime = .now
        self.isDuringPeriod = isDuringPeriod
        self.completedExerciseCount = 0
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

