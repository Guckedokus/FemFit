// Models.swift
// FemFit – alle Datenmodelle
// Einfügen in Xcode: File > New > File > Swift File > "Models"

import Foundation
import SwiftData

// ───────────────────────────────────────────
// MARK: – Trainingsprogramm
// ───────────────────────────────────────────

@Model
final class WorkoutProgram {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.program)
    var days: [WorkoutDay] = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }

    var sortedDays: [WorkoutDay] {
        days.sorted { $0.order < $1.order }
    }

    var completedWorkouts: Int {
        days.reduce(0) { $0 + $1.completedSessions }
    }
}

// ───────────────────────────────────────────
// MARK: – Trainingstag (z.B. Push / Pull / Legs)
// ───────────────────────────────────────────

@Model
final class WorkoutDay {
    var name: String
    var order: Int
    var program: WorkoutProgram?

    @Relationship(deleteRule: .cascade, inverse: \Exercise.day)
    var exercises: [Exercise] = []

    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }

    var sortedExercises: [Exercise] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Wie viel % der Übungen haben bereits Einträge
    var completionPercent: Double {
        guard !exercises.isEmpty else { return 0 }
        let logged = exercises.filter { !$0.sets.isEmpty }.count
        return Double(logged) / Double(exercises.count)
    }

    /// Wie viele abgeschlossene Sessions gibt es für diesen Tag
    var completedSessions: Int {
        let allDates = exercises.flatMap { $0.sets }.map { Calendar.current.startOfDay(for: $0.date) }
        return Set(allDates).count
    }
}

// ───────────────────────────────────────────
// MARK: – Übung (z.B. Bankdrücken)
// ───────────────────────────────────────────

@Model
final class Exercise {
    var name: String
    var order: Int
    var targetSets: Int   // Ziel-Sätze (z.B. 4)
    var targetReps: Int   // Ziel-Wiederholungen (z.B. 8)

    var day: WorkoutDay?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []

    init(name: String, order: Int, targetSets: Int = 3, targetReps: Int = 10) {
        self.name = name
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
    }

    // Nur normale Sätze (außerhalb Periode)
    var normalSets: [WorkoutSet] {
        sets.filter { !$0.isDuringPeriod }.sorted { $0.date < $1.date }
    }

    // Nur Perioden-Sätze
    var periodSets: [WorkoutSet] {
        sets.filter { $0.isDuringPeriod }.sorted { $0.date < $1.date }
    }

    /// Letztes eingetragenes Gewicht (je nach Modus)
    func lastWeight(period: Bool) -> Double? {
        let relevant = period ? periodSets : normalSets
        return relevant.last?.weight
    }

    /// Letzte Wiederholungsanzahl (je nach Modus)
    func lastReps(period: Bool) -> Int? {
        let relevant = period ? periodSets : normalSets
        return relevant.last?.reps
    }

    /// Fortschritt in % für diesen Trainingstag
    var todayCompletion: Double {
        let today = Calendar.current.startOfDay(for: .now)
        let todaySets = sets.filter { Calendar.current.startOfDay(for: $0.date) == today }
        guard targetSets > 0 else { return 0 }
        return min(1.0, Double(todaySets.count) / Double(targetSets))
    }
}

// ───────────────────────────────────────────
// MARK: – Einzelner Satz (Gewicht + Wdh)
// ───────────────────────────────────────────

@Model
final class WorkoutSet {
    var weight: Double      // in kg
    var reps: Int           // Wiederholungen
    var setNumber: Int      // 1. Satz, 2. Satz usw.
    var date: Date
    var isDuringPeriod: Bool   // Wichtigste Unterscheidung!
    var note: String

    var exercise: Exercise?

    init(weight: Double, reps: Int, setNumber: Int, isDuringPeriod: Bool, note: String = "") {
        self.weight = weight
        self.reps = reps
        self.setNumber = setNumber
        self.date = .now
        self.isDuringPeriod = isDuringPeriod
        self.note = note
    }
}
