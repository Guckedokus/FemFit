// FemFitApp.swift
import SwiftUI
import SwiftData

@main
struct FemFitApp: App {

    init() {
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000, diskPath: "exercise_images")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutProgram.self,
            WorkoutDay.self,
            Exercise.self,
            WorkoutSet.self,
            WorkoutSession.self,  // ← FEHLTE!
            BodyMeasurement.self,
            Achievement.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("CloudKit config failed: \(error)")
            // Fallback ohne CloudKit
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                print("Fallback failed, deleting store: \(error)")
                // Store löschen und neu erstellen
                let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
                try? FileManager.default.removeItem(at: storeURL)
                do {
                    return try ModelContainer(for: schema, configurations: [fallback])
                } catch {
                    fatalError("Could not create ModelContainer after reset: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .onAppear {
                    CycleManager.shared.checkAndUpdateCycle()
                    CycleManager.shared.requestNotificationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
