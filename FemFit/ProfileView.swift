// ProfileView.swift
// FemFit – Profil Screen
import SwiftUI
import SwiftData

struct ProfileView: View {
    var cycleManager = CycleManager.shared
    @AppStorage("userName")    var userName    = ""
    @AppStorage("userAge")     var userAge     = 0
    @AppStorage("userHeight")  var userHeight  = 0
    @AppStorage("userGoal")    var userGoal    = "Muskelaufbau"
    @Query private var allSets:      [WorkoutSet]
    @Query private var measurements: [BodyMeasurement]
    @Query private var unlocked:     [Achievement]

    @State private var editMode = false
    @State private var nameInput   = ""
    @State private var ageInput    = ""
    @State private var heightInput = ""

    let goals = ["Muskelaufbau", "Fettabbau", "Kraftaufbau", "Fitness & Gesundheit", "Wettkampf"]

    var totalWorkouts: Int { Set(allSets.map { Calendar.current.startOfDay(for: $0.date) }).count }
    var totalSets:     Int { allSets.count }
    var latestWeight:  Double? { measurements.last?.weight }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsCards
                    
                    // NEU: Programme-Verwaltung
                    managementSection
                    
                    goalsSection
                    bodySection
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Mein Profil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editMode ? "Fertig" : "Bearbeiten") {
                        if editMode { saveProfile() }
                        else { nameInput = userName; ageInput = userAge > 0 ? "\(userAge)" : ""; heightInput = userHeight > 0 ? "\(userHeight)" : "" }
                        editMode.toggle()
                    }
                    .fontWeight(editMode ? .semibold : .regular)
                }
            }
        }
    }

    // ── Profil Header ──
    var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#E84393").opacity(0.2))
                    .frame(width: 80, height: 80)
                Text(userName.isEmpty ? "?" : String(userName.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#E84393"))
            }

            VStack(alignment: .leading, spacing: 6) {
                if editMode {
                    TextField("Dein Name", text: $nameInput)
                        .font(.title3).fontWeight(.semibold)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(userName.isEmpty ? "Kein Name" : userName)
                        .font(.title3).fontWeight(.bold)
                }

                HStack(spacing: 12) {
                    if editMode {
                        TextField("Alter", text: $ageInput).keyboardType(.numberPad).frame(width: 60).textFieldStyle(.roundedBorder).font(.caption)
                        TextField("Größe cm", text: $heightInput).keyboardType(.numberPad).frame(width: 80).textFieldStyle(.roundedBorder).font(.caption)
                    } else {
                        if userAge > 0    { Label("\(userAge) Jahre", systemImage: "person").font(.caption).foregroundColor(.secondary) }
                        if userHeight > 0 { Label("\(userHeight) cm", systemImage: "ruler").font(.caption).foregroundColor(.secondary) }
                    }
                }

                // Zyklus Status
                HStack(spacing: 6) {
                    Circle().fill(cycleManager.cyclePhaseColor).frame(width: 8, height: 8)
                    Text(cycleManager.cyclePhaseText).font(.caption).foregroundColor(cycleManager.cyclePhaseColor)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // ── Stats ──
    var statsCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalWorkouts)", label: "Workouts",    icon: "dumbbell.fill",      color: Color(hex: "#1D9E75"))
            statCard(value: "\(totalSets)",     label: "Sätze",       icon: "checkmark.circle",   color: Color(hex: "#7B68EE"))
            statCard(value: "\(unlocked.count)",label: "Badges",      icon: "trophy.fill",        color: Color(hex: "#F4A623"))
        }
    }

    func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(14)
        .background(color.opacity(0.1)).cornerRadius(14)
    }
    
    // ── Programme-Verwaltung (NEU!) ──
    var managementSection: some View {
        NavigationLink(destination: ProgramManagementView()) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E84393").opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "folder.badge.gearshape")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#E84393"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Programme verwalten")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Bearbeite oder lösche deine Trainingspläne")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(uiColor: UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // ── Ziel ──
    var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mein Ziel")
                .font(.headline)
            if editMode {
                Picker("Ziel", selection: $userGoal) {
                    ForEach(goals, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
            } else {
                HStack {
                    Image(systemName: "target").foregroundColor(Color(hex: "#E84393"))
                    Text(userGoal).font(.subheadline).fontWeight(.medium)
                    Spacer()
                }
                .padding(14)
                .background(Color(hex: "#E84393").opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // ── Körperdaten ──
    var bodySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Körper")
                .font(.headline)
            if let w = latestWeight {
                HStack {
                    Image(systemName: "scalemass.fill").foregroundColor(Color(hex: "#1D9E75"))
                    Text("Aktuelles Gewicht")
                    Spacer()
                    Text("\(String(format: "%.1f", w)) kg").fontWeight(.semibold)
                }
            } else {
                Text("Noch keine Messungen – trage deine Körpermaße ein!")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func saveProfile() {
        userName   = nameInput
        userAge    = Int(ageInput) ?? userAge
        userHeight = Int(heightInput) ?? userHeight
    }
}
