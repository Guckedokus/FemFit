// ProgramManagementView.swift
// FemFit – Zentrale Verwaltung für Trainingsprogramme
// Löschen, Bearbeiten, Neu erstellen

import SwiftUI
import SwiftData

struct ProgramManagementView: View {
    
    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss  // FEHLT!
    
    @Query(sort: \WorkoutProgram.createdAt, order: .reverse) private var programs: [WorkoutProgram]
    
    @State private var showAddProgram = false
    @State private var showTemplates = false
    @State private var showDeleteConfirmation = false
    @State private var programToDelete: WorkoutProgram?
    @State private var newProgramName = ""
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header Info
                infoCard
                
                // Programme Liste
                if programs.isEmpty {
                    emptyState
                } else {
                    programsList
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Programme verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Fertig") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showTemplates = true
                    } label: {
                        Label("Template nutzen", systemImage: "sparkles")
                    }
                    
                    Button {
                        showAddProgram = true
                    } label: {
                        Label("Eigenes Programm", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(accentColor)
                }
            }
        }
        .alert("Neues Programm", isPresented: $showAddProgram) {
            TextField("Name (z.B. Push Pull Legs)", text: $newProgramName)
            Button("Erstellen") { createProgram() }
            Button("Abbrechen", role: .cancel) { newProgramName = "" }
        }
        .alert("Programm löschen?", isPresented: $showDeleteConfirmation) {
            Button("Löschen", role: .destructive) {
                if let program = programToDelete {
                    deleteProgram(program)
                }
            }
            Button("Abbrechen", role: .cancel) {
                programToDelete = nil
            }
        } message: {
            if let program = programToDelete {
                Text("'\(program.name)' wird gelöscht. Alle Trainingstage, Übungen und Sessions gehen verloren.")
            }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerView()
        }
    }
    
    // MARK: – Info Card
    
    var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .font(.title2)
                    .foregroundColor(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Programme verwalten")
                        .font(.headline)
                    Text("Erstelle, bearbeite oder lösche deine Trainingspläne")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Stats
            HStack(spacing: 16) {
                statBadge(value: "\(programs.count)", label: "Programme", icon: "folder")
                statBadge(value: "\(totalDays)", label: "Trainingstage", icon: "calendar")
                statBadge(value: "\(totalExercises)", label: "Übungen", icon: "dumbbell.fill")
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    func statBadge(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(accentColor)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    var totalDays: Int {
        programs.reduce(0) { $0 + $1.days.count }
    }
    
    var totalExercises: Int {
        programs.reduce(0) { total, program in
            total + program.days.reduce(0) { $0 + $1.exercises.count }
        }
    }
    
    // MARK: – Programme Liste
    
    var programsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meine Programme")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ForEach(programs) { program in
                ProgramManagementCard(
                    program: program,
                    onEdit: {
                        // Navigate to edit
                    },
                    onDelete: {
                        programToDelete = program
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }
    
    // MARK: – Empty State
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Keine Programme")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Erstelle dein erstes Trainingsprogramm")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button {
                    showTemplates = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Template nutzen")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(accentColor)
                    .cornerRadius(12)
                }
                
                Button {
                    showAddProgram = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Eigenes Programm")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
    
    // MARK: – Actions
    
    func createProgram() {
        guard !newProgramName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let program = WorkoutProgram(name: newProgramName)
        context.insert(program)
        newProgramName = ""
    }
    
    func deleteProgram(_ program: WorkoutProgram) {
        context.delete(program)
        programToDelete = nil
    }
}

// MARK: – Program Management Card

struct ProgramManagementCard: View {
    
    var cycleManager = CycleManager.shared
    @Bindable var program: WorkoutProgram
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDetails = false
    @State private var showEditSheet = false
    @State private var editedName: String = ""
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showDetails.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(program.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            Label("\(program.days.count) Tage", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label("\(program.completedWorkouts) Sessions", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: showDetails ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(accentColor.opacity(0.7))
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Details (expandable)
            if showDetails {
                VStack(spacing: 12) {
                    Divider()
                    
                    // Days List
                    if program.sortedDays.isEmpty {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.secondary)
                            Text("Noch keine Trainingstage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(program.sortedDays) { day in
                            NavigationLink(destination: WorkoutDayView(day: day)) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(accentColor.opacity(0.7))
                                    Text(day.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(day.exercises.count) Übungen")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(uiColor: .systemGray6).opacity(0.5))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            editedName = program.name
                            showEditSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                Text("Bearbeiten")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                Text("Löschen")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .systemGray6).opacity(0.3))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .animation(.spring(response: 0.3), value: showDetails)
        .sheet(isPresented: $showEditSheet) {
            EditProgramSheet(program: program, isPresented: $showEditSheet)
        }
    }
}

// MARK: – Edit Program Sheet (NEU!)

struct EditProgramSheet: View {
    
    var cycleManager = CycleManager.shared
    @Bindable var program: WorkoutProgram
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    
    @State private var editedName: String = ""
    @State private var showAddDay = false
    @State private var newDayName = ""
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Programm-Name") {
                    TextField("Name", text: $editedName)
                }
                
                Section("Übersicht") {
                    HStack {
                        Text("Trainingstage")
                        Spacer()
                        Text("\(program.days.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Absolvierte Sessions")
                        Spacer()
                        Text("\(program.completedWorkouts)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Trainingstage") {
                    if program.sortedDays.isEmpty {
                        Text("Noch keine Trainingstage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(program.sortedDays) { day in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.name)
                                        .font(.body)
                                    Text("\(day.exercises.count) Übungen")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Navigation zu Trainingstag
                                NavigationLink(destination: WorkoutDayView(day: day)) {
                                    HStack(spacing: 4) {
                                        Text("Öffnen")
                                            .font(.caption)
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title3)
                                    }
                                    .foregroundColor(accentColor)
                                }
                            }
                        }
                        .onDelete(perform: deleteDays)
                    }
                    
                    Button {
                        showAddDay = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Trainingstag hinzufügen")
                        }
                    }
                }
                
                // NEU: Hinweis für Übungen
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Übungen verwalten")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("•")
                                Text("Tippe **\"Öffnen\"** um Übungen zu verwalten")
                            }
                            HStack(spacing: 6) {
                                Text("•")
                                Text("Im Trainingstag: **Swipe links** zum Bearbeiten")
                            }
                            HStack(spacing: 6) {
                                Text("•")
                                Text("Im Trainingstag: **Swipe rechts** zum Löschen")
                            }
                            HStack(spacing: 6) {
                                Text("•")
                                Text("Oder nutze **\"+\"** Button für neue Übungen")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Programm bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        program.name = editedName
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                editedName = program.name
            }
            .alert("Neuer Trainingstag", isPresented: $showAddDay) {
                TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
                Button("Hinzufügen") { addDay() }
                Button("Abbrechen", role: .cancel) { newDayName = "" }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    func addDay() {
        guard !newDayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let day = WorkoutDay(name: newDayName, order: program.days.count)
        day.program = program
        context.insert(day)
        newDayName = ""
    }
    
    func deleteDays(at offsets: IndexSet) {
        for index in offsets {
            let day = program.sortedDays[index]
            context.delete(day)
        }
    }
}

// MARK: – Preview

#Preview {
    ProgramManagementView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutDay.self, Exercise.self])
}
