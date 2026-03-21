// AchievementsView.swift
// FemFit – Gamification & Achievements
import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var allSets: [WorkoutSet]
    @Query private var measurements: [BodyMeasurement]
    @Query private var unlocked: [Achievement]
    @Query private var sessions: [WorkoutSession]

    var streak: Int  // wird von außen übergeben

    var achievements: [AchievementDef] {
        allAchievementDefinitions
    }

    var unlockedIDs: Set<String> { Set(unlocked.map { $0.id }) }

    var unlockedAchievements: [AchievementDef] { achievements.filter { unlockedIDs.contains($0.id) } }
    var lockedAchievements:   [AchievementDef] { achievements.filter { !unlockedIDs.contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Progress Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(unlockedAchievements.count) / \(achievements.count) freigeschaltet")
                                .font(.headline)
                            ProgressView(value: Double(unlockedAchievements.count), total: Double(achievements.count))
                                .tint(Color(hex: "#F4A623"))
                        }
                        Spacer()
                        Text("🏆")
                            .font(.system(size: 40))
                    }
                    .padding(16)
                    .background(Color(hex: "#F4A623").opacity(0.1))
                    .cornerRadius(16)

                    // Freigeschaltet
                    if !unlockedAchievements.isEmpty {
                        sectionHeader("✅ Freigeschaltet")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(unlockedAchievements) { a in
                                achievementCard(a, unlocked: true)
                            }
                        }
                    }

                    // Gesperrt
                    sectionHeader("🔒 Noch zu erreichen")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(lockedAchievements) { a in
                            achievementCard(a, unlocked: false)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
        .onAppear { checkAndUnlock() }
    }

    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func achievementCard(_ a: AchievementDef, unlocked: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? a.color.opacity(0.2) : Color(uiColor: UIColor.systemGray5))
                    .frame(width: 56, height: 56)
                Image(systemName: a.icon)
                    .font(.system(size: 24))
                    .foregroundColor(unlocked ? a.color : .secondary)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .offset(x: 18, y: 18)
                }
            }
            Text(a.title)
                .font(.caption).fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(unlocked ? .primary : .secondary)
            Text(a.desc)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(unlocked ? a.color.opacity(0.06) : Color(uiColor: UIColor.systemGray6))
        .cornerRadius(14)
    }

    @Environment(\.modelContext) private var context
    func checkAndUnlock() {
        for a in achievements {
            if !unlockedIDs.contains(a.id) && a.check(allSets, measurements, sessions, streak) {
                context.insert(Achievement(id: a.id))
            }
        }
    }
}
