// WorkoutFinishView.swift
// FemFit – Workout Abschluss-Zusammenfassung

import SwiftUI
import SwiftData

struct WorkoutFinishView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allSets: [WorkoutSet]
    @Query private var measurements: [BodyMeasurement]
    @Query private var allSessions: [WorkoutSession]
    @Query private var unlocked: [Achievement]
    
    var cycleManager = CycleManager.shared
    
    let session: WorkoutSession
    let day: WorkoutDay
    let onFinish: () -> Void
    
    @State private var newAchievements: [String] = []
    
    var currentStreak: Int {
        cycleManager.calculateStreak(sessions: allSessions)
    }
    
    var accentColor: Color {
        session.isDuringPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // ── Erfolgs-Icon ──
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, 20)
                    
                    // ── Titel ──
                    VStack(spacing: 8) {
                        Text("Gut gemacht!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Du hast dein Training abgeschlossen")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // ── Zusammenfassung ──
                    VStack(spacing: 12) {
                        summaryRow(
                            icon: "clock.fill",
                            label: "Dauer",
                            value: session.durationFormatted,
                            color: .blue
                        )
                        
                        summaryRow(
                            icon: "checkmark.square.fill",
                            label: "Übungen",
                            value: "\(day.todayCompletedExercises) von \(day.sortedExercises.count)",
                            color: .green
                        )
                        
                        summaryRow(
                            icon: session.isDuringPeriod ? "heart.fill" : "bolt.fill",
                            label: "Modus",
                            value: session.isDuringPeriod ? "Angepasst 🌸" : "Voll-Power 💪",
                            color: accentColor
                        )
                        
                        if let totalSets = calculateTotalSets() {
                            summaryRow(
                                icon: "list.bullet",
                                label: "Sätze insgesamt",
                                value: "\(totalSets)",
                                color: .orange
                            )
                        }
                        
                        if currentStreak > 0 {
                            summaryRow(
                                icon: "flame.fill",
                                label: "Aktueller Streak",
                                value: "\(currentStreak) \(currentStreak == 1 ? "Tag" : "Tage") 🔥",
                                color: Color(hex: "#E84393")
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: UIColor.systemGray6))
                    .cornerRadius(16)
                    
                    // ── Motivations-Text ──
                    VStack(spacing: 8) {
                        if session.isDuringPeriod {
                            Text("💪 Perfekt an deinen Zyklus angepasst!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            Text("Dein Körper dankt dir für das smarte Training!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("💪 Voll-Power gegeben - super Leistung!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            Text("Bleib dran und du wirst immer stärker!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal)
                    
                    // ── Neue Achievements ──
                    if !newAchievements.isEmpty {
                        achievementsSection
                    }
                    
                    // ── Buttons ──
                    VStack(spacing: 12) {
                        Button {
                            onFinish()
                        } label: {
                            Text("Training beenden")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Weiter trainieren")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Training abschließen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            checkForNewAchievements()
        }
    }
    
    // ───────────────────────────────────────────
    // MARK: – Achievements Section
    // ───────────────────────────────────────────
    
    var achievementsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color(hex: "#F4A623"))
                Text("Neue Achievements!")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F4A623"))
            }
            
            ForEach(newAchievements, id: \.self) { achievementId in
                if let achievement = allAchievementDefinitions.first(where: { $0.id == achievementId }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(achievement.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: achievement.icon)
                                .foregroundColor(achievement.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(achievement.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(achievement.desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(achievement.color.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // ───────────────────────────────────────────
    // MARK: – Achievement Checking
    // ───────────────────────────────────────────
    
    func checkForNewAchievements() {
        let unlockedIDs = Set(unlocked.map { $0.id })
        let completedSessions = allSessions.filter { $0.endTime != nil }
        let streak = currentStreak
        
        for achievement in allAchievementDefinitions {
            if !unlockedIDs.contains(achievement.id) && 
               achievement.check(allSets, measurements, completedSessions, streak) {
                // Neues Achievement freigeschaltet!
                context.insert(Achievement(id: achievement.id))
                newAchievements.append(achievement.id)
            }
        }
        
        try? context.save()
    }
    
    // ───────────────────────────────────────────
    // MARK: – Helper Functions
    // ───────────────────────────────────────────
    
    func summaryRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
    
    func calculateTotalSets() -> Int? {
        let cutoff = session.startTime
        let sessionSets = day.sortedExercises.flatMap { exercise in
            exercise.sets.filter { $0.date >= cutoff }
        }
        return sessionSets.isEmpty ? nil : sessionSets.count
    }
}
