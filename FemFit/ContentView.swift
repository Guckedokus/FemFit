// ContentView.swift
// FemFit – Haupt-Navigation
import SwiftUI
import SwiftData

struct ContentView: View {
    var cycleManager = CycleManager.shared
    @AppStorage("onboardingDone") var onboardingDone = false
    @State private var selectedTab = 0

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var body: some View {
        if !onboardingDone {
            OnboardingView()
        } else {
            TabView(selection: $selectedTab) {

                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                NavigationStack {
                    DashboardView(selectedTab: $selectedTab)
                        .navigationTitle("FemFit")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
                .tag(1)

                NavigationStack {
                    ManageWorkoutDaysView()
                }
                .tabItem { Label("Trainingstage", systemImage: "calendar.badge.clock") }
                .tag(2)

                CycleTrackerView()
                    .tabItem { Label("Zyklus", systemImage: "calendar.circle.fill") }
                    .tag(3)

                NavigationStack {
                    WorkoutCalendarView()
                }
                .tabItem { Label("Kalender", systemImage: "calendar") }
                .tag(4)

                NavigationStack {
                    MoreView(selectedTab: $selectedTab)
                }
                .tabItem { Label("Mehr", systemImage: "ellipsis") }
                .tag(5)
            }
            .tint(accentColor)
        }
    }
}

struct MoreView: View {
    @Binding var selectedTab: Int

    var body: some View {
        List {
            Section {
                NavigationLink(destination: ProgressChartView()) {
                    Label("Fortschritt", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: WorkoutCalendarView()) {
                    Label("Kalender", systemImage: "calendar")
                }
            }
            Section {
                NavigationLink(destination: ProfileView()) {
                    Label("Profil", systemImage: "person.fill")
                }
            }
        }
        .navigationTitle("Mehr")
    }
}
