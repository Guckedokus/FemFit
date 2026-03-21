// CyclePhaseInfoView.swift
// FemFit – 4 Zyklusphasen erklärt & visualisiert
// Einfügen in Xcode: File > New > File > Swift File > "CyclePhaseInfoView"

import SwiftUI

struct CyclePhaseInfoView: View {
    
    var cycleManager = CycleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header mit aktuellem Status
                    currentPhaseCard
                    
                    // Zyklus-Rad Visualisierung
                    cycleWheel
                    
                    // Erklärung
                    Text("Dein Zyklus besteht aus 4 Phasen")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    Text("Jede Phase hat unterschiedliche Hormone und beeinflusst deine Trainingsleistung anders.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Die 4 Phasen erklärt
                    VStack(spacing: 16) {
                        PhaseCard(phase: .menstruation)
                        PhaseCard(phase: .follicular)
                        PhaseCard(phase: .ovulation)
                        PhaseCard(phase: .luteal)
                    }
                    
                    // Wissenschaftlicher Hintergrund
                    scientificNote
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("4 Zyklusphasen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: – Current Phase Card
    
    var currentPhaseCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Deine aktuelle Phase")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    HStack(spacing: 8) {
                        Text(cycleManager.currentPhase.emoji)
                            .font(.title)
                        Text(cycleManager.currentPhase.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Tag \(cycleManager.currentCycleDay) von \(cycleManager.cycleLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Gewichts-Multiplikator
                VStack(spacing: 4) {
                    Text("\(Int(cycleManager.currentPhase.weightMultiplier * 100))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(cycleManager.currentPhase.color)
                    Text("Gewichte")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(cycleManager.currentPhase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    cycleManager.currentPhase.color.opacity(0.15),
                    cycleManager.currentPhase.color.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cycleManager.currentPhase.color.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: – Cycle Wheel
    
    var cycleWheel: some View {
        ZStack {
            // Hintergrund-Kreis
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 220, height: 220)
            
            // 4 Phasen-Segmente
            ForEach(Array(CyclePhase.allCases.enumerated()), id: \.offset) { index, phase in
                let startAngle = Angle(degrees: Double(index) * 90 - 90)
                let endAngle = Angle(degrees: Double(index + 1) * 90 - 90)
                
                Circle()
                    .trim(from: CGFloat(index) * 0.25, to: CGFloat(index + 1) * 0.25)
                    .stroke(
                        phase.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .butt)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .opacity(cycleManager.currentPhase == phase ? 1.0 : 0.4)
            }
            
            // Fortschritts-Indikator
            Circle()
                .fill(cycleManager.currentPhase.color)
                .frame(width: 20, height: 20)
                .offset(y: -110)
                .rotationEffect(.degrees(Double(cycleManager.currentCycleDay) / Double(cycleManager.cycleLength) * 360))
            
            // Mitte
            VStack(spacing: 4) {
                Text(cycleManager.currentPhase.emoji)
                    .font(.system(size: 40))
                Text("Tag \(cycleManager.currentCycleDay)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(cycleManager.currentPhase.color)
            }
        }
        .frame(height: 240)
    }
    
    // MARK: – Scientific Note
    
    var scientificNote: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("Wissenschaftlicher Hintergrund")
                    .font(.headline)
            }
            
            Text("Dein Menstruationszyklus wird durch die Hormone Östrogen und Progesteron gesteuert. Diese beeinflussen:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "bolt.fill", text: "Energielevel", color: .orange)
                InfoRow(icon: "figure.strengthtraining.traditional", text: "Muskelkraft", color: .green)
                InfoRow(icon: "heart.fill", text: "Regeneration", color: .red)
                InfoRow(icon: "brain", text: "Motivation", color: .purple)
            }
            
            Text("FemFit passt deine Gewichte automatisch an deine Hormone an – für optimale Ergebnisse ohne Überlastung!")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: – Phase Card

struct PhaseCard: View {
    let phase: CyclePhase
    
    var dayRange: String {
        switch phase {
        case .menstruation: return "Tag 1-5"
        case .follicular:   return "Tag 6-13"
        case .ovulation:    return "Tag 14-16"
        case .luteal:       return "Tag 17-28"
        }
    }
    
    var hormoneInfo: String {
        switch phase {
        case .menstruation: return "Östrogen & Progesteron niedrig"
        case .follicular:   return "Östrogen steigt stark"
        case .ovulation:    return "Östrogen-Peak, LH-Anstieg"
        case .luteal:       return "Progesteron hoch"
        }
    }
    
    var trainingTip: String {
        switch phase {
        case .menstruation: return "Leichtes Training, viel Regeneration"
        case .follicular:   return "Schwere Gewichte! Nutze diese Phase!"
        case .ovulation:    return "Immer noch top Performance"
        case .luteal:       return "Moderates Training, mehr Cardio"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(phase.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.rawValue)
                        .font(.headline)
                    Text(dayRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Gewichts-Badge
                VStack(spacing: 2) {
                    Text("\(Int(phase.weightMultiplier * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(phase.color)
                    Text("Kraft")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(phase.color.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(16)
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(
                    icon: "waveform.path.ecg",
                    title: "Hormone",
                    value: hormoneInfo,
                    color: phase.color
                )
                
                DetailRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Training",
                    value: trainingTip,
                    color: phase.color
                )
                
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(phase.color)
                    Text(phase.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color.white, phase.color.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(phase.color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: – Helper Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: – Preview

#Preview {
    CyclePhaseInfoView()
}
