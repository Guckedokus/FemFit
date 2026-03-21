// RestDayView.swift
// FemFit – Ruhetage tracken und planen

import SwiftUI
import SwiftData

struct RestDayView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var sessions: [WorkoutSession]
    
    var lastWorkoutDate: Date? {
        sessions.first { $0.endTime != nil }?.startTime
    }
    
    var daysSinceLastWorkout: Int {
        guard let lastDate = lastWorkoutDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
    }
    
    var isRestDay: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return !sessions.contains { Calendar.current.startOfDay(for: $0.startTime) == today }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // ── Status-Icon ──
                ZStack {
                    Circle()
                        .fill(isRestDay ? Color(hex: "#7B68EE").opacity(0.2) : Color(hex: "#1D9E75").opacity(0.2))
                        .frame(width: 120, height: 120)
                    Image(systemName: isRestDay ? "bed.double.fill" : "figure.run")
                        .font(.system(size: 60))
                        .foregroundColor(isRestDay ? Color(hex: "#7B68EE") : Color(hex: "#1D9E75"))
                }
                .padding(.top, 20)
                
                // ── Status Text ──
                VStack(spacing: 8) {
                    Text(isRestDay ? "Ruhetag" : "Trainingstag")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastDate = lastWorkoutDate {
                        Text("Letztes Training: \(lastDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if daysSinceLastWorkout > 0 {
                            Text("\(daysSinceLastWorkout) Tage Pause")
                                .font(.caption)
                                .foregroundColor(daysSinceLastWorkout > 3 ? .orange : .secondary)
                        }
                    } else {
                        Text("Noch kein Training absolviert")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ── Empfehlungen ──
                recommendationsCard
                
                // ── Rest Day Tips ──
                restDayTips
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Ruhetag-Tracker")
        .navigationBarTitleDisplayMode(.large)
    }
    
    var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Empfehlungen", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(Color(hex: "#F4A623"))
            
            if daysSinceLastWorkout == 0 {
                recommendationRow(icon: "checkmark.circle.fill", text: "Super! Du hast heute schon trainiert.", color: .green)
            } else if daysSinceLastWorkout == 1 {
                recommendationRow(icon: "moon.fill", text: "Ein Ruhetag ist wichtig für die Regeneration.", color: Color(hex: "#7B68EE"))
            } else if daysSinceLastWorkout == 2 {
                recommendationRow(icon: "arrow.clockwise", text: "Morgen wäre ein guter Tag für ein leichtes Training.", color: .blue)
            } else if daysSinceLastWorkout >= 3 {
                recommendationRow(icon: "exclamationmark.triangle.fill", text: "Zeit für ein Comeback! Dein Körper braucht Bewegung.", color: .orange)
            }
            
            Divider()
            
            Text("Optimale Ruhetage: 1-2 Tage zwischen intensiven Sessions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    func recommendationRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    var restDayTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tipps für Ruhetage")
                .font(.headline)
            
            tipCard(
                icon: "figure.walk",
                title: "Aktive Erholung",
                description: "Leichte Bewegung wie Spazieren fördert die Durchblutung.",
                color: Color(hex: "#1D9E75")
            )
            
            tipCard(
                icon: "drop.fill",
                title: "Hydration",
                description: "Trinke ausreichend Wasser für optimale Regeneration.",
                color: Color(hex: "#4A90D9")
            )
            
            tipCard(
                icon: "moon.zzz.fill",
                title: "Ausreichend Schlaf",
                description: "7-9 Stunden Schlaf helfen deinen Muskeln zu wachsen.",
                color: Color(hex: "#7B68EE")
            )
            
            tipCard(
                icon: "fork.knife",
                title: "Protein-reich essen",
                description: "Auch an Ruhetagen braucht dein Körper Proteine.",
                color: Color(hex: "#F4A623")
            )
        }
    }
    
    func tipCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
