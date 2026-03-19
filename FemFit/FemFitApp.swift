// FemFitApp.swift
// Einfügen in Xcode: Diese Datei wird automatisch erstellt wenn du das Projekt anlegst.
// Ersetze den Inhalt der automatisch erstellten [AppName]App.swift mit diesem Code.

import SwiftUI
import SwiftData

@main
struct FemFitApp: App {

    

    // SwiftData Container – hier werden alle Daten gespeichert
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutProgram.self,
            WorkoutDay.self,
            Exercise.self,
            WorkoutSet.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData Container konnte nicht erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    CycleManager.shared.checkAndUpdateCycle()
                    CycleManager.shared.requestNotificationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
