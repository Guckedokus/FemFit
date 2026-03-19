// SettingsView.swift
// FemFit – Einstellungen
// Einfügen in Xcode: File > New > File > Swift File > "SettingsView"

import SwiftUI
import SwiftData

struct SettingsView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    @State private var showDeleteAlert = false

    let hours = Array(5...22)

    var body: some View {
        NavigationStack {
            Form {

                // ── Benachrichtigungen ──
                Section {
                    Toggle("Training-Erinnerung", isOn: Binding(
                        get: { cycleManager.notifyEnabled },
                        set: {
                            cycleManager.notifyEnabled = $0
                            cycleManager.scheduleAllNotifications()
                        }
                    ))
                    .tint(Color(hex: "#E84393"))

                    if cycleManager.notifyEnabled {
                        Picker("Uhrzeit", selection: Binding(
                            get: { cycleManager.notifyHour },
                            set: {
                                cycleManager.notifyHour = $0
                                cycleManager.scheduleAllNotifications()
                            }
                        )) {
                            ForEach(hours, id: \.self) { hour in
                                Text(String(format: "%02d:00 Uhr", hour)).tag(hour)
                            }
                        }
                    }
                } header: {
                    Text("Benachrichtigungen")
                } footer: {
                    Text("Du bekommst täglich eine Erinnerung und einen Hinweis wenn deine Periode beginnt.")
                }

                // ── Zyklus ──
                Section("Zyklus-Einstellungen") {
                    HStack {
                        Text("Zykluslänge")
                        Spacer()
                        Text("\(cycleManager.cycleLength) Tage")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Perioden-Länge")
                        Spacer()
                        Text("\(cycleManager.periodLength) Tage")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("Zyklus anpassen") {
                        CycleTrackerView()
                    }
                }

                // ── App-Info ──
                Section("Über FemFit") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Entwickelt für")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundColor(.secondary)
                    }
                }

                // ── Daten ──
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Alle Trainingsdaten löschen", systemImage: "trash")
                    }
                } header: {
                    Text("Daten")
                } footer: {
                    Text("Löscht alle gespeicherten Trainings und Gewichte. Zyklus-Einstellungen bleiben erhalten.")
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Alle Daten löschen?", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) { deleteAllData() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }

    func deleteAllData() {
        try? context.delete(model: WorkoutSet.self)
        try? context.delete(model: Exercise.self)
        try? context.delete(model: WorkoutDay.self)
        try? context.delete(model: WorkoutProgram.self)
    }
}
