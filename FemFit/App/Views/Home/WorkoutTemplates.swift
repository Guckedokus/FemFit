// WorkoutTemplates.swift
// FemFit – Vorgefertigte Trainingspläne & Templates

import Foundation
import SwiftData

// ───────────────────────────────────────────
// MARK: – Übungs-Template
// ───────────────────────────────────────────

struct ExerciseTemplate {
    let name: String
    let targetSets: Int
    let targetReps: Int
    let category: ExerciseCategory
    
    enum ExerciseCategory: String {
        case chest = "Brust"
        case back = "Rücken"
        case shoulders = "Schultern"
        case arms = "Arme"
        case legs = "Beine"
        case core = "Bauch"
    }
}

// ───────────────────────────────────────────
// MARK: – Trainingstag-Template
// ───────────────────────────────────────────

struct WorkoutDayTemplate {
    let name: String
    let exercises: [ExerciseTemplate]
}

// ───────────────────────────────────────────
// MARK: – Programm-Template
// ───────────────────────────────────────────

struct ProgramTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let frequency: String // z.B. "3-6x pro Woche"
    let difficulty: Difficulty
    let days: [WorkoutDayTemplate]
    let icon: String
    let color: String // Hex
    
    enum Difficulty: String {
        case beginner = "Anfänger"
        case intermediate = "Fortgeschritten"
        case advanced = "Profi"
    }
}

// ───────────────────────────────────────────
// MARK: – Alle Templates
// ───────────────────────────────────────────

struct WorkoutTemplates {
    
    // MARK: – Push/Pull/Legs (PPL)
    static let pushPullLegs = ProgramTemplate(
        name: "Push/Pull/Legs",
        description: "Der beliebteste Split für Kraftaufbau. Perfekt für 3-6x Training pro Woche.",
        frequency: "3-6x/Woche",
        difficulty: .intermediate,
        days: [
            // PUSH DAY
            WorkoutDayTemplate(
                name: "Push (Brust, Schultern, Trizeps)",
                exercises: [
                    ExerciseTemplate(name: "Bankdrücken", targetSets: 4, targetReps: 8, category: .chest),
                    ExerciseTemplate(name: "Schrägbankdrücken", targetSets: 3, targetReps: 10, category: .chest),
                    ExerciseTemplate(name: "Fliegende", targetSets: 3, targetReps: 12, category: .chest),
                    ExerciseTemplate(name: "Schulterdrücken", targetSets: 4, targetReps: 8, category: .shoulders),
                    ExerciseTemplate(name: "Seitheben", targetSets: 3, targetReps: 12, category: .shoulders),
                    ExerciseTemplate(name: "Trizeps Pushdowns", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Dips", targetSets: 3, targetReps: 10, category: .arms),
                ]
            ),
            // PULL DAY
            WorkoutDayTemplate(
                name: "Pull (Rücken, Bizeps)",
                exercises: [
                    ExerciseTemplate(name: "Kreuzheben", targetSets: 4, targetReps: 6, category: .back),
                    ExerciseTemplate(name: "Klimmzüge", targetSets: 4, targetReps: 8, category: .back),
                    ExerciseTemplate(name: "Rudern", targetSets: 4, targetReps: 10, category: .back),
                    ExerciseTemplate(name: "Latzug", targetSets: 3, targetReps: 12, category: .back),
                    ExerciseTemplate(name: "Bizeps Curls", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Hammer Curls", targetSets: 3, targetReps: 12, category: .arms),
                ]
            ),
            // LEG DAY
            WorkoutDayTemplate(
                name: "Legs (Beine, Waden, Bauch)",
                exercises: [
                    ExerciseTemplate(name: "Kniebeugen", targetSets: 4, targetReps: 8, category: .legs),
                    ExerciseTemplate(name: "Beinpresse", targetSets: 3, targetReps: 12, category: .legs),
                    ExerciseTemplate(name: "Beinstrecker", targetSets: 3, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Beinbeuger", targetSets: 3, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Wadenheben", targetSets: 4, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Plank", targetSets: 3, targetReps: 60, category: .core),
                    ExerciseTemplate(name: "Crunches", targetSets: 3, targetReps: 20, category: .core),
                ]
            ),
        ],
        icon: "figure.strengthtraining.traditional",
        color: "#1D9E75"
    )
    
    // MARK: – Upper/Lower Split
    static let upperLowerSplit = ProgramTemplate(
        name: "Upper/Lower Split",
        description: "Oberkörper/Unterkörper Aufteilung. Ideal für 4x Training pro Woche.",
        frequency: "4x/Woche",
        difficulty: .intermediate,
        days: [
            // UPPER DAY
            WorkoutDayTemplate(
                name: "Upper (Oberkörper)",
                exercises: [
                    ExerciseTemplate(name: "Bankdrücken", targetSets: 4, targetReps: 8, category: .chest),
                    ExerciseTemplate(name: "Rudern", targetSets: 4, targetReps: 10, category: .back),
                    ExerciseTemplate(name: "Schulterdrücken", targetSets: 3, targetReps: 10, category: .shoulders),
                    ExerciseTemplate(name: "Latzug", targetSets: 3, targetReps: 12, category: .back),
                    ExerciseTemplate(name: "Bizeps Curls", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Trizeps Pushdowns", targetSets: 3, targetReps: 12, category: .arms),
                ]
            ),
            // LOWER DAY
            WorkoutDayTemplate(
                name: "Lower (Unterkörper)",
                exercises: [
                    ExerciseTemplate(name: "Kniebeugen", targetSets: 4, targetReps: 8, category: .legs),
                    ExerciseTemplate(name: "Kreuzheben", targetSets: 3, targetReps: 8, category: .legs),
                    ExerciseTemplate(name: "Beinpresse", targetSets: 3, targetReps: 12, category: .legs),
                    ExerciseTemplate(name: "Beinbeuger", targetSets: 3, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Wadenheben", targetSets: 4, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Plank", targetSets: 3, targetReps: 60, category: .core),
                ]
            ),
        ],
        icon: "figure.run",
        color: "#4A90D9"
    )
    
    // MARK: – Full Body
    static let fullBody = ProgramTemplate(
        name: "Full Body",
        description: "Ganzkörper-Training. Perfekt für Anfänger, 3x pro Woche.",
        frequency: "3x/Woche",
        difficulty: .beginner,
        days: [
            WorkoutDayTemplate(
                name: "Full Body A",
                exercises: [
                    ExerciseTemplate(name: "Kniebeugen", targetSets: 3, targetReps: 10, category: .legs),
                    ExerciseTemplate(name: "Bankdrücken", targetSets: 3, targetReps: 10, category: .chest),
                    ExerciseTemplate(name: "Rudern", targetSets: 3, targetReps: 12, category: .back),
                    ExerciseTemplate(name: "Schulterdrücken", targetSets: 3, targetReps: 10, category: .shoulders),
                    ExerciseTemplate(name: "Plank", targetSets: 3, targetReps: 45, category: .core),
                ]
            ),
            WorkoutDayTemplate(
                name: "Full Body B",
                exercises: [
                    ExerciseTemplate(name: "Kreuzheben", targetSets: 3, targetReps: 8, category: .legs),
                    ExerciseTemplate(name: "Schrägbankdrücken", targetSets: 3, targetReps: 10, category: .chest),
                    ExerciseTemplate(name: "Latzug", targetSets: 3, targetReps: 12, category: .back),
                    ExerciseTemplate(name: "Bizeps Curls", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Trizeps Pushdowns", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Crunches", targetSets: 3, targetReps: 20, category: .core),
                ]
            ),
        ],
        icon: "star.fill",
        color: "#F4A623"
    )
    
    // MARK: – Bro-Split
    static let broSplit = ProgramTemplate(
        name: "Bro-Split (Klassisch)",
        description: "Ein Muskel pro Tag. Für Fortgeschrittene, 5x pro Woche.",
        frequency: "5x/Woche",
        difficulty: .advanced,
        days: [
            // CHEST DAY
            WorkoutDayTemplate(
                name: "Chest Day (Brust)",
                exercises: [
                    ExerciseTemplate(name: "Bankdrücken", targetSets: 4, targetReps: 8, category: .chest),
                    ExerciseTemplate(name: "Schrägbankdrücken", targetSets: 4, targetReps: 10, category: .chest),
                    ExerciseTemplate(name: "Fliegende", targetSets: 3, targetReps: 12, category: .chest),
                    ExerciseTemplate(name: "Dips", targetSets: 3, targetReps: 10, category: .chest),
                    ExerciseTemplate(name: "Cable Crossover", targetSets: 3, targetReps: 15, category: .chest),
                ]
            ),
            // BACK DAY
            WorkoutDayTemplate(
                name: "Back Day (Rücken)",
                exercises: [
                    ExerciseTemplate(name: "Kreuzheben", targetSets: 4, targetReps: 6, category: .back),
                    ExerciseTemplate(name: "Klimmzüge", targetSets: 4, targetReps: 8, category: .back),
                    ExerciseTemplate(name: "Rudern", targetSets: 4, targetReps: 10, category: .back),
                    ExerciseTemplate(name: "Latzug", targetSets: 3, targetReps: 12, category: .back),
                    ExerciseTemplate(name: "Shrugs", targetSets: 3, targetReps: 15, category: .back),
                ]
            ),
            // SHOULDER DAY
            WorkoutDayTemplate(
                name: "Shoulder Day (Schultern)",
                exercises: [
                    ExerciseTemplate(name: "Schulterdrücken", targetSets: 4, targetReps: 8, category: .shoulders),
                    ExerciseTemplate(name: "Seitheben", targetSets: 4, targetReps: 12, category: .shoulders),
                    ExerciseTemplate(name: "Frontheben", targetSets: 3, targetReps: 12, category: .shoulders),
                    ExerciseTemplate(name: "Reverse Flys", targetSets: 3, targetReps: 15, category: .shoulders),
                    ExerciseTemplate(name: "Face Pulls", targetSets: 3, targetReps: 15, category: .shoulders),
                ]
            ),
            // ARM DAY
            WorkoutDayTemplate(
                name: "Arm Day (Arme)",
                exercises: [
                    ExerciseTemplate(name: "Bizeps Curls", targetSets: 4, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Hammer Curls", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Trizeps Pushdowns", targetSets: 4, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Skull Crushers", targetSets: 3, targetReps: 12, category: .arms),
                    ExerciseTemplate(name: "Concentration Curls", targetSets: 3, targetReps: 15, category: .arms),
                ]
            ),
            // LEG DAY
            WorkoutDayTemplate(
                name: "Leg Day (Beine)",
                exercises: [
                    ExerciseTemplate(name: "Kniebeugen", targetSets: 4, targetReps: 8, category: .legs),
                    ExerciseTemplate(name: "Beinpresse", targetSets: 4, targetReps: 12, category: .legs),
                    ExerciseTemplate(name: "Beinstrecker", targetSets: 3, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Beinbeuger", targetSets: 3, targetReps: 15, category: .legs),
                    ExerciseTemplate(name: "Wadenheben", targetSets: 4, targetReps: 20, category: .legs),
                    ExerciseTemplate(name: "Plank", targetSets: 3, targetReps: 60, category: .core),
                ]
            ),
        ],
        icon: "flame.fill",
        color: "#E84393"
    )
    
    // MARK: – Alle Templates
    static let allTemplates: [ProgramTemplate] = [
        fullBody,           // 1. Anfänger-freundlich
        pushPullLegs,       // 2. Beliebtester
        upperLowerSplit,    // 3. Klassiker
        broSplit,           // 4. Für Fortgeschrittene
    ]
    
    // MARK: – Template zu SwiftData konvertieren
    static func createProgram(from template: ProgramTemplate, context: ModelContext) {
        print("🏋️ Starte Template-Import: \(template.name)")
        
        let program = WorkoutProgram(name: template.name)
        context.insert(program)
        print("✅ Programm erstellt: \(program.name)")
        
        for (index, dayTemplate) in template.days.enumerated() {
            let day = WorkoutDay(name: dayTemplate.name, order: index)
            day.program = program
            context.insert(day)
            print("✅ Tag \(index + 1) erstellt: \(day.name)")
            
            for (exerciseIndex, exerciseTemplate) in dayTemplate.exercises.enumerated() {
                let exercise = Exercise(
                    name: exerciseTemplate.name,
                    order: exerciseIndex,
                    targetSets: exerciseTemplate.targetSets,
                    targetReps: exerciseTemplate.targetReps,
                    notes: ""
                )
                exercise.day = day
                context.insert(exercise)
            }
            print("  ✅ \(dayTemplate.exercises.count) Übungen hinzugefügt")
        }
        
        do {
            try context.save()
            print("💾 Erfolgreich gespeichert!")
            print("📊 Statistik:")
            print("   - Programm: \(program.name)")
            print("   - Trainingstage: \(template.days.count)")
            print("   - Gesamt-Übungen: \(template.days.reduce(0) { $0 + $1.exercises.count })")
        } catch {
            print("❌ Fehler beim Speichern: \(error)")
            print("❌ Error Details: \(error.localizedDescription)")
        }
    }
}
