// ExercisePickerView.swift
// FemFit – Übungs-Bibliothek Picker
// Einfügen in Xcode: File > New > File > Swift File > "ExercisePickerView"

import SwiftUI
import SwiftData

struct ExercisePickerView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    let day: WorkoutDay

    @State private var searchText       = ""
    @State private var selectedGroup: MuscleGroup? = nil
    @State private var selectedExercises: Set<UUID> = []
    @FocusState private var isSearchFocused: Bool  // NEU: Für Keyboard-Kontrolle

    // Live-Filter: Aktualisiert sich automatisch bei jedem Tastendruck
    var filtered: [LibraryExercise] {
        ExerciseLibrary.search(searchText, group: selectedGroup)
    }
    
    // Zeigt an, ob aktiv gefiltert wird
    var isFiltering: Bool {
        !searchText.isEmpty || selectedGroup != nil
    }
    
    // Anzahl der gefundenen Übungen
    var resultCount: Int {
        filtered.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Suche ──
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Übung suchen...", text: $searchText)
                            .autocorrectionDisabled(true)  // Verhindert Auto-Korrektur
                            .textInputAutocapitalization(.never)  // Keine Auto-Großschreibung
                            .focused($isSearchFocused)  // Keyboard-Steuerung
                            .submitLabel(.search)  // "Suchen" Button auf Keyboard
                        
                        // Clear Button wenn Text eingegeben
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: UIColor.systemGray6))
                    .cornerRadius(10)
                    
                    // Live-Feedback: Zeigt Anzahl der gefundenen Übungen
                    if isFiltering {
                        HStack(spacing: 6) {
                            Image(systemName: resultCount > 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(resultCount > 0 ? Color(hex: "#1D9E75") : .orange)
                            Text(resultCount > 0 
                                ? "\(resultCount) Übung\(resultCount == 1 ? "" : "en") gefunden" 
                                : "Keine Übungen gefunden")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            // Schnell-Clear Button
                            if !searchText.isEmpty || selectedGroup != nil {
                                Button("Filter zurücksetzen") {
                                    withAnimation {
                                        searchText = ""
                                        selectedGroup = nil
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(Color(hex: "#E84393"))
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // ── Muskelgruppen-Filter ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "Alle" Button
                        filterChip(
                            label: "Alle",
                            emoji: "🏋️",
                            isSelected: selectedGroup == nil
                        ) {
                            selectedGroup = nil
                        }

                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            filterChip(
                                label: group.rawValue,
                                emoji: group.emoji,
                                isSelected: selectedGroup == group
                            ) {
                                selectedGroup = selectedGroup == group ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // ── Ausgewählt-Anzeige ──
                if !selectedExercises.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#E84393"))
                        Text("Ausgewählt: \(selectedExercises.count)")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#E84393"))
                        Spacer()
                        Button("Auswahl löschen") {
                            selectedExercises.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }

                Divider()

                // ── Übungs-Liste ──
                List {
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Keine Übungen gefunden")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filtered) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
                .listStyle(.plain)

                // ── Hinzufügen-Button ──
                if !selectedExercises.isEmpty {
                    Button {
                        addSelected()
                        dismiss()
                    } label: {
                        Text("\(selectedExercises.count) Übung\(selectedExercises.count == 1 ? "" : "en") hinzufügen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color(hex: "#E84393"))
                            .cornerRadius(14)
                    }
                    .padding()
                }
            }
            .navigationTitle("Übung wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Eigene") { addCustom() }
                        .foregroundColor(.secondary)
                }
                
                // Keyboard Toolbar (NEU!)
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        // Filter-Shortcuts
                        if isSearchFocused {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MuscleGroup.allCases.prefix(5), id: \.self) { group in
                                        Button {
                                            selectedGroup = selectedGroup == group ? nil : group
                                        } label: {
                                            Text("\(group.emoji) \(group.rawValue)")
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(selectedGroup == group ? Color(hex: "#E84393") : Color(uiColor: .systemGray5))
                                                .foregroundColor(selectedGroup == group ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Fertig Button
                        Button("Fertig") {
                            isSearchFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#E84393"))
                    }
                }
            }
            .onAppear {
                // Auto-Focus auf Suchfeld beim Öffnen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSearchFocused = true
                }
            }
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Filter Chip
    // ───────────────────────────────────────────

    func filterChip(label: String, emoji: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji).font(.system(size: 14))
                Text(label).font(.caption).fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color(hex: "#E84393") : Color(uiColor: UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(20)
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Übungs-Zeile
    // ───────────────────────────────────────────

    func exerciseRow(_ exercise: LibraryExercise) -> some View {
        let isSelected = selectedExercises.contains(exercise.id)

        return Button {
            if isSelected {
                selectedExercises.remove(exercise.id)
            } else {
                selectedExercises.insert(exercise.id)
            }
        } label: {
            HStack(spacing: 14) {
                // Übungsbild von Wger
                WgerImageView(exerciseName: exercise.name, size: 44)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 3) {
                    // Name mit Highlight für Suchbegriff
                    if !searchText.isEmpty {
                        highlightedText(exercise.name, highlight: searchText)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                    } else {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 6) {
                        Text(exercise.muscleGroup.emoji)
                            .font(.caption)
                        Text(exercise.muscleGroup.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer()

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color(hex: "#E84393") : Color(uiColor: UIColor.systemGray4))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected ? Color(hex: "#E84393").opacity(0.05) : Color.clear
        )
    }
    
    // ───────────────────────────────────────────
    // MARK: – Text Highlighting (NEU!)
    // ───────────────────────────────────────────
    
    func highlightedText(_ text: String, highlight: String) -> some View {
        let highlighted = highlightMatches(in: text, query: highlight)
        return Text(highlighted)
    }
    
    func highlightMatches(in text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        guard !query.isEmpty else { return attributedString }
        
        // Case-insensitive Suche
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()
        
        var searchRange = lowerText.startIndex..<lowerText.endIndex
        
        while let range = lowerText.range(of: lowerQuery, range: searchRange) {
            // Konvertiere zu AttributedString Range
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: lowerText.distance(from: lowerText.startIndex, to: range.lowerBound))
            let endIndex = attributedString.index(startIndex, offsetByCharacters: lowerQuery.count)
            
            // Highlight Style
            attributedString[startIndex..<endIndex].foregroundColor = Color(hex: "#E84393")
            attributedString[startIndex..<endIndex].font = .system(.subheadline, weight: .bold)
            
            // Nächster Bereich
            searchRange = range.upperBound..<lowerText.endIndex
        }
        
        return attributedString
    }

    // ───────────────────────────────────────────
    // MARK: – Aktionen
    // ───────────────────────────────────────────

    func addSelected() {
        let toAdd = filtered.filter { selectedExercises.contains($0.id) }
        for (index, lib) in toAdd.enumerated() {
            let ex = Exercise(
                name:       lib.name,
                order:      day.exercises.count + index,
                targetSets: 3,
                targetReps: 10
            )
            ex.day = day
            context.insert(ex)
        }
    }

    func addCustom() {
        // Wird beim nächsten Update gebaut – eigene Übung tippen
        dismiss()
    }

    func colorFor(_ group: MuscleGroup) -> Color {
        switch group {
        case .brust:    return Color(hex: "#E84393")
        case .schulter: return Color(hex: "#7B68EE")
        case .trizeps:  return Color(hex: "#1D9E75")
        case .ruecken:  return Color(hex: "#F4A623")
        case .bizeps:   return Color(hex: "#E84393")
        case .unterarm: return Color(hex: "#4A90D9")  // ← fehlt noch
        case .beine:    return Color(hex: "#4A90D9")
        case .bauch:    return Color(hex: "#E84393")
        case .gluteus:  return Color(hex: "#F4A623")
        }
    }
}
