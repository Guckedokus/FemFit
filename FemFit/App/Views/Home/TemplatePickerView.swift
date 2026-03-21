// TemplatePickerView.swift
// FemFit – Template-Auswahl für vorgefertigte Pläne

import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let templates = WorkoutTemplates.allTemplates
    
    @State private var selectedTemplate: ProgramTemplate?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#E84393"))
                        
                        Text("Wähle dein Programm")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Vorgefertigte Pläne von Fitness-Profis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Templates
                    ForEach(templates) { template in
                        TemplateCard(template: template, isSelected: selectedTemplate?.id == template.id) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTemplate = template
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        if selectedTemplate != nil {
                            showConfirmation = true
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedTemplate == nil)
                }
            }
            .alert("Programm erstellen?", isPresented: $showConfirmation) {
                Button("Ja, erstellen!", role: .none) {
                    createProgramFromTemplate()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                if let template = selectedTemplate {
                    Text("Möchtest du '\(template.name)' erstellen?\n\n\(template.days.count) Trainingstage mit allen Übungen werden automatisch hinzugefügt.")
                }
            }
        }
    }
    
    func createProgramFromTemplate() {
        guard let template = selectedTemplate else { return }
        
        // Debug-Ausgabe
        print("📝 Erstelle Programm: \(template.name)")
        
        // Programm erstellen
        WorkoutTemplates.createProgram(from: template, context: context)
        
        // Warte kurz damit Save durchgeht
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

// ───────────────────────────────────────────
// MARK: – Template Card
// ───────────────────────────────────────────

struct TemplateCard: View {
    let template: ProgramTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var color: Color {
        Color(hex: template.color)
    }
    
    var difficultyColor: Color {
        switch template.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: template.icon)
                            .font(.system(size: 28))
                            .foregroundColor(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            // Difficulty Badge
                            Text(template.difficulty.rawValue)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(difficultyColor.opacity(0.2))
                                .foregroundColor(difficultyColor)
                                .cornerRadius(6)
                            
                            // Frequency
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(template.frequency)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection Checkmark
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(color)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
                .padding(16)
                
                // Description
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                Divider()
                
                // Days Preview
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(color)
                        Text("\(template.days.count) Trainingstage:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    ForEach(Array(template.days.enumerated()), id: \.offset) { index, day in
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                            
                            Text(day.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(day.exercises.count) Übungen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: UIColor.systemGray6).opacity(0.5))
            }
            .background(Color(uiColor: UIColor.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 12 : 6, y: isSelected ? 8 : 2)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
