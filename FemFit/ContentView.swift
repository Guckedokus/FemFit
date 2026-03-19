// ContentView.swift
// FemFit – Haupt-Navigation (Tab Bar)
// Einfügen in Xcode: File > New > File > Swift File > "ContentView"

import SwiftUI
import SwiftData

struct ContentView: View {

    var cycleManager = CycleManager.shared
    @State private var selectedTab = 0

    // Periode-Farbe für die ganze App
    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(0)

            CycleTrackerView()
                .tabItem {
                    Label("Zyklus", systemImage: "calendar.circle.fill")
                }
                .tag(1)

            ProgressChartView()
                .tabItem {
                    Label("Fortschritt", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(accentColor)
    }
}
