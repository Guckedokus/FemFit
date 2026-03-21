// AchievementDefinitions.swift
// FemFit – Zentrale Achievement-Definitionen

import SwiftUI
import SwiftData

// ───────────────────────────────────────────
// MARK: – Achievement Definition Struktur
// ───────────────────────────────────────────

struct AchievementDef: Identifiable {
    let id: String
    let title: String
    let desc: String
    let icon: String
    let color: Color
    let check: ([WorkoutSet], [BodyMeasurement], [WorkoutSession], Int) -> Bool
}

// ───────────────────────────────────────────
// MARK: – Alle Achievement-Definitionen
// ───────────────────────────────────────────

let allAchievementDefinitions: [AchievementDef] = [
    // Erste Schritte
    .init(id: "first_set", 
          title: "Erster Satz!", 
          desc: "Du hast deinen ersten Satz geloggt", 
          icon: "figure.strengthtraining.traditional", 
          color: Color(hex: "#1D9E75"),
          check: { sets, _, _, _ in !sets.isEmpty }),
    
    .init(id: "first_session", 
          title: "Erste Session!", 
          desc: "Dein erstes Training abgeschlossen", 
          icon: "checkmark.circle.fill", 
          color: Color(hex: "#1D9E75"),
          check: { _, _, sessions, _ in sessions.filter { $0.endTime != nil }.count >= 1 }),
    
    // Session-Meilensteine
    .init(id: "10_sessions", 
          title: "10 Sessions", 
          desc: "10 Trainings abgeschlossen", 
          icon: "dumbbell.fill", 
          color: Color(hex: "#F4A623"),
          check: { _, _, sessions, _ in sessions.filter { $0.endTime != nil }.count >= 10 }),
    
    .init(id: "30_sessions", 
          title: "30 Sessions", 
          desc: "30 Trainings – du bist dabei!", 
          icon: "trophy.fill", 
          color: Color(hex: "#F4A623"),
          check: { _, _, sessions, _ in sessions.filter { $0.endTime != nil }.count >= 30 }),
    
    .init(id: "50_sessions", 
          title: "50 Sessions", 
          desc: "50 Trainings – Legende!", 
          icon: "crown.fill", 
          color: Color(hex: "#F4A623"),
          check: { _, _, sessions, _ in sessions.filter { $0.endTime != nil }.count >= 50 }),
    
    // Streak-Achievements
    .init(id: "streak_7", 
          title: "7 Tage Streak", 
          desc: "7 Tage in Folge trainiert", 
          icon: "flame.fill", 
          color: Color(hex: "#E84393"),
          check: { _, _, _, streak in streak >= 7 }),
    
    .init(id: "streak_30", 
          title: "30 Tage Streak", 
          desc: "30 Tage in Folge – unglaublich!", 
          icon: "flame.fill", 
          color: Color(hex: "#E84393"),
          check: { _, _, _, streak in streak >= 30 }),
    
    // Perioden-Achievements
    .init(id: "period_train", 
          title: "Periode-Kriegerin", 
          desc: "Während der Periode trainiert", 
          icon: "heart.fill", 
          color: Color(hex: "#E84393"),
          check: { sets, _, _, _ in sets.contains { $0.isDuringPeriod } }),
    
    .init(id: "period_session", 
          title: "Periode-Power", 
          desc: "Session während Periode abgeschlossen", 
          icon: "moon.fill", 
          color: Color(hex: "#E84393"),
          check: { _, _, sessions, _ in sessions.contains { $0.isDuringPeriod && $0.endTime != nil } }),
    
    // Körpermessung
    .init(id: "first_measure", 
          title: "Selbstvermessung", 
          desc: "Erste Körpermessung eingetragen", 
          icon: "scalemass.fill", 
          color: Color(hex: "#4A90D9"),
          check: { _, meas, _, _ in !meas.isEmpty }),
    
    // Satz-Meilensteine
    .init(id: "100_sets", 
          title: "100 Sätze", 
          desc: "100 Sätze absolviert – Respect!", 
          icon: "star.fill", 
          color: Color(hex: "#F4A623"),
          check: { sets, _, _, _ in sets.count >= 100 }),
    
    // Session-Dauer
    .init(id: "quick_workout", 
          title: "Schnelles Workout", 
          desc: "Session unter 20 Min abgeschlossen", 
          icon: "timer", 
          color: Color(hex: "#4A90D9"),
          check: { _, _, sessions, _ in 
              sessions.contains { ($0.endTime?.timeIntervalSince($0.startTime) ?? 0) < 1200 }
          }),
    
    .init(id: "long_workout", 
          title: "Marathon-Session", 
          desc: "Training über 90 Min", 
          icon: "bolt.fill", 
          color: Color(hex: "#F4A623"),
          check: { _, _, sessions, _ in 
              sessions.contains { ($0.endTime?.timeIntervalSince($0.startTime) ?? 0) > 5400 }
          }),
    
    // Tageszeit
    .init(id: "night_owl", 
          title: "Nachteule", 
          desc: "Nach 21 Uhr trainiert", 
          icon: "moon.stars.fill", 
          color: Color(hex: "#7B68EE"),
          check: { sets, _, _, _ in 
              sets.contains { Calendar.current.component(.hour, from: $0.date) >= 21 }
          }),
    
    .init(id: "early_bird", 
          title: "Frühaufsteher", 
          desc: "Vor 7 Uhr trainiert", 
          icon: "sunrise.fill", 
          color: Color(hex: "#F4A623"),
          check: { sets, _, _, _ in 
              sets.contains { Calendar.current.component(.hour, from: $0.date) < 7 }
          }),
    
    // Wochenende
    .init(id: "weekend_warrior", 
          title: "Weekend Warrior", 
          desc: "Am Wochenende trainiert", 
          icon: "calendar", 
          color: Color(hex: "#7B68EE"),
          check: { _, _, sessions, _ in 
              sessions.contains { 
                  let weekday = Calendar.current.component(.weekday, from: $0.startTime)
                  return weekday == 1 || weekday == 7
              }
          }),
]
