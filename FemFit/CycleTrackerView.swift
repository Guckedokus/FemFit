// CycleTrackerView.swift
// FemFit – Zyklus-Tracking Screen
// Einfügen in Xcode: File > New > File > Swift File > "CycleTrackerView"

import SwiftUI

struct CycleTrackerView: View {

    var cycleManager = CycleManager.shared
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Zyklus-Übersicht Ring ──
                    cycleRing

                    // ── Status-Karten ──
                    statusCards

                    // ── Zyklus einstellen ──
                    settingsCard

                    // ── Phasen-Erklärung ──
                    phasesCard

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Mein Zyklus")
        }
    }

    // ───────────────────────────────────────────
    // MARK: – Zyklus-Ring
    // ───────────────────────────────────────────

    var cycleRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(Color(uiColor: UIColor.systemGray5), lineWidth: 18)

                // Periode-Phase (Anfang)
                Circle()
                    .trim(
                        from: 0,
                        to: CGFloat(cycleManager.periodLength) / CGFloat(cycleManager.cycleLength)
                    )
                    .stroke(Color(hex: "#E84393"), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Aktueller Tag
                Circle()
                    .trim(
                        from: CGFloat(cycleManager.currentCycleDay - 1) / CGFloat(cycleManager.cycleLength) - 0.01,
                        to:   CGFloat(cycleManager.currentCycleDay)     / CGFloat(cycleManager.cycleLength) + 0.01
                    )
                    .stroke(Color(hex: "#1D9E75"), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Mitte-Text
                VStack(spacing: 4) {
                    Text("Tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cycleManager.currentCycleDay)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("von \(cycleManager.cycleLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Aktueller Status
            Text(cycleManager.cyclePhaseText)
                .font(.headline)
                .foregroundColor(cycleManager.cyclePhaseColor)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Status-Karten
    // ───────────────────────────────────────────

    var statusCards: some View {
        HStack(spacing: 12) {
            infoTile(
                icon: "calendar",
                label: "Nächste Periode",
                value: "\(cycleManager.daysUntilNextPeriod) Tage",
                color: Color(hex: "#E84393")
            )
            infoTile(
                icon: "moon.fill",
                label: "Perioden-Länge",
                value: "\(cycleManager.periodLength) Tage",
                color: Color(hex: "#7B68EE")
            )
            infoTile(
                icon: "arrow.clockwise",
                label: "Zykluslänge",
                value: "\(cycleManager.cycleLength) Tage",
                color: Color(hex: "#1D9E75")
            )
        }
    }

    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline).fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }

    // ───────────────────────────────────────────
    // MARK: – Einstellungen
    // ───────────────────────────────────────────

    var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zyklus einrichten")
                .font(.headline)

            // Letzter Perioden-Start
            VStack(alignment: .leading, spacing: 6) {
                Text("Letzter Perioden-Start")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack {
                        Text(cycleManager.periodStartDate, style: .date)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#E84393"))
                    }
                    .padding(12)
                    .background(Color(uiColor: UIColor.systemGray6))
                    .cornerRadius(10)
                }

                if showDatePicker {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { cycleManager.periodStartDate },
                            set: { cycleManager.periodStartDate = $0 }
                        ),
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: "#E84393"))
                }
            }

            Divider()

            // Zykluslänge
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Zykluslänge")
                        .font(.subheadline)
                    Spacer()
                    Text("\(cycleManager.cycleLength) Tage")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
                Slider(
                    value: Binding(
                        get: { Double(cycleManager.cycleLength) },
                        set: { cycleManager.cycleLength = Int($0) }
                    ),
                    in: 21...35, step: 1
                )
                .tint(Color(hex: "#1D9E75"))
            }

            Divider()

            // Perioden-Länge
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Perioden-Länge")
                        .font(.subheadline)
                    Spacer()
                    Text("\(cycleManager.periodLength) Tage")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#E84393"))
                }
                Slider(
                    value: Binding(
                        get: { Double(cycleManager.periodLength) },
                        set: { cycleManager.periodLength = Int($0) }
                    ),
                    in: 2...10, step: 1
                )
                .tint(Color(hex: "#E84393"))
            }

            // Aktualisieren-Button
            Button {
                cycleManager.checkAndUpdateCycle()
            } label: {
                Label("Zyklus aktualisieren", systemImage: "arrow.clockwise")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(hex: "#E84393"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ───────────────────────────────────────────
    // MARK: – Phasen-Erklärung
    // ───────────────────────────────────────────

    var phasesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dein Zyklus & Training")
                .font(.headline)

            phaseRow(
                color: Color(hex: "#E84393"),
                phase: "Periode (Tag 1–5)",
                desc: "Leichtere Gewichte normal – Hormonspiegel senkt Kraft. Kein Rückschritt!"
            )
            phaseRow(
                color: Color(hex: "#1D9E75"),
                phase: "Follikelphase (Tag 6–13)",
                desc: "Östrogen steigt – beste Zeit für PR-Versuche und schwere Gewichte!"
            )
            phaseRow(
                color: Color(hex: "#7B68EE"),
                phase: "Ovulation (Tag 14)",
                desc: "Höchste Kraft und Energie. Perfekt für Maximalleistung."
            )
            phaseRow(
                color: Color(hex: "#F4A623"),
                phase: "Lutealphase (Tag 15–28)",
                desc: "Progeste­ron steigt. Gut trainierbar, Regeneration priorisieren."
            )
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    func phaseRow(color: Color, phase: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(phase)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(color)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
