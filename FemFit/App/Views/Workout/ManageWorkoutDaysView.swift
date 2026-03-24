// ManageWorkoutDaysView.swift
// FemFit – Trainingstage verwalten, bearbeiten & löschen
// Einfügen in Xcode: File > New > File > Swift File > "ManageWorkoutDaysView"

import SwiftUI
import SwiftData

struct ManageWorkoutDaysView: View {
    
    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context
    
    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]
    
    @State private var showAddDay = false
    @State private var editingDay: WorkoutDay? = nil
    @State private var selectedProgram: WorkoutProgram? = nil
    @State private var newDayName = ""
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var activeProgram: WorkoutProgram? {
        programs.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trainingstage")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Verwalte deine Trainingstage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Trainingstage nach Programm
                if let program = activeProgram {
                    programSection(program)
                } else {
                    emptyState
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Trainingstage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedProgram = activeProgram
                    showAddDay = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(accentColor)
                }
                .disabled(activeProgram == nil)
            }
        }
        .alert("Neuer Trainingstag", isPresented: $showAddDay) {
            TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
            Button("Hinzufügen") { addDay() }
            Button("Abbrechen", role: .cancel) { 
                newDayName = ""
                selectedProgram = nil
            }
        } message: {
            Text("Erstelle einen neuen Trainingstag für dein Programm.")
        }
        .sheet(item: $editingDay) { day in
            EditWorkoutDaySheet(day: day)
        }
    }
    
    // MARK: – Programm-Section
    
    func programSection(_ program: WorkoutProgram) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Programm-Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.headline)
                    Text("\(program.days.count) Trainingstage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Trainingstage Liste
            if program.sortedDays.isEmpty {
                emptyDaysList
            } else {
                VStack(spacing: 10) {
                    ForEach(program.sortedDays) { day in
                        ManageWorkoutDayRow(
                            day: day,
                            onEdit: {
                                editingDay = day
                            },
                            onDelete: {
                                deleteDay(day)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: – Empty States
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Kein Programm vorhanden")
                .font(.headline)
            Text("Erstelle zuerst ein Trainingsprogramm im Home-Tab.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    var emptyDaysList: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Noch keine Trainingstage")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button {
                selectedProgram = activeProgram
                showAddDay = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Ersten Tag erstellen")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(accentColor)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: – Actions
    
    func addDay() {
        guard let program = selectedProgram,
              !newDayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let day = WorkoutDay(name: newDayName, order: program.days.count)
        day.program = program
        context.insert(day)
        newDayName = ""
        selectedProgram = nil
    }
    
    func deleteDay(_ day: WorkoutDay) {
        context.delete(day)
    }
}

// MARK: – Workout Day Row für Management

struct ManageWorkoutDayRow: View {
    
    var cycleManager = CycleManager.shared
    let day: WorkoutDay
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var navigateToDay = false
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar.circle.fill")
                    .font(.title3)
                    .foregroundColor(accentColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(day.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label("\(day.exercises.count) Übungen", systemImage: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(day.completedSessions) Sessions", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                
                Button {
                    navigateToDay = true
                } label: {
                    Label("Öffnen", systemImage: "arrow.right.circle")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(accentColor.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white, accentColor.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.08), radius: 6, y: 3)
        .navigationDestination(isPresented: $navigateToDay) {
            WorkoutDayView(day: day)
        }
        .alert("Tag löschen?", isPresented: $showDeleteConfirmation) {
            Button("Löschen", role: .destructive) {
                onDelete()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("'\(day.name)' wird gelöscht. Alle Übungen und Sessions gehen verloren.")
        }
    }
}

// MARK: – Edit Sheet

struct EditWorkoutDaySheet: View {
    
    var cycleManager = CycleManager.shared
    @Bindable var day: WorkoutDay
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var editName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showExerciseView = false
    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseSets = 3
    @State private var newExerciseReps = 10
    
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Trainingstag-Name", text: $editName)
                }
                
                Section("Übersicht") {
                    HStack {
                        Text("Übungen")
                        Spacer()
                        Text("\(day.exercises.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Absolvierte Sessions")
                        Spacer()
                        Text("\(day.completedSessions)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button {
                        showExerciseView = true
                    } label: {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(accentColor)
                            Text("Übungen verwalten")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Training")
                }
                
                Section {
                    // Übungen Liste
                    if day.sortedExercises.isEmpty {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundColor(.secondary)
                            Text("Noch keine Übungen")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(day.sortedExercises) { exercise in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Ziel: \(exercise.targetSets)×\(exercise.targetReps)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteExercises)
                    }
                    
                    // Hinzufügen Button
                    Button {
                        showAddExercise = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Übung hinzufügen")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Übungen (\(day.exercises.count))")
                } footer: {
                    Text("Wische nach links, um eine Übung zu löschen.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Trainingstag löschen")
                        }
                    }
                } footer: {
                    Text("Löscht den Trainingstag mit allen Übungen und Sessions permanent.")
                }
            }
            .navigationTitle("Tag bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showExerciseView) {
                WorkoutDayView(day: day)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        if !editName.trimmingCharacters(in: .whitespaces).isEmpty {
                            day.name = editName
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                editName = day.name
            }
            .alert("Neue Übung", isPresented: $showAddExercise) {
                TextField("Übungsname", text: $newExerciseName)
                Button("Hinzufügen") {
                    addExercise()
                }
                Button("Abbrechen", role: .cancel) {
                    newExerciseName = ""
                }
            } message: {
                Text("Gib den Namen der neuen Übung ein.")
            }
            .alert("Tag löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    context.delete(day)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("'\(day.name)' wird permanent gelöscht. Alle Übungen und Sessions gehen verloren.")
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Actions
    
    private func addExercise() {
        guard !newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let exercise = Exercise(
            name: newExerciseName,
            order: day.exercises.count,
            targetSets: newExerciseSets,
            targetReps: newExerciseReps
        )
        exercise.day = day
        context.insert(exercise)
        
        // Reset
        newExerciseName = ""
        newExerciseSets = 3
        newExerciseReps = 10
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = day.sortedExercises[index]
            context.delete(exercise)
        }
    }
}
