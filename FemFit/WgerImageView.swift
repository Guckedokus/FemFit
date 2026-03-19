// WgerImageView.swift
// FemFit – Übungsbilder aus der Wger Open-Source Datenbank
// Einfügen in Xcode: File > New > File > Swift File > "WgerImageView"

import SwiftUI

// ───────────────────────────────────────────
// MARK: – Image Cache & Service
// ───────────────────────────────────────────

@Observable
class WgerImageService {

    static let shared = WgerImageService()

    // Cache: Übungsname → Bild-URL
    private var cache: [String: URL?] = [:]
    private var inFlight: Set<String> = []

    func imageURL(for name: String) -> URL? {
        cache[name] ?? nil
    }

    func load(for name: String) async {
        guard cache[name] == nil, !inFlight.contains(name) else { return }
        inFlight.insert(name)

        let url = await fetchImageURL(exerciseName: name)
        cache[name] = url
        inFlight.remove(name)
    }

    // ── Wger API: Suche nach Übungsname ──
    private func fetchImageURL(exerciseName: String) async -> URL? {
        guard let encoded = exerciseName
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string:
                "https://wger.de/api/v2/exercise/search/?term=\(encoded)&language=de&format=json")
        else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: searchURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let suggestions = json?["suggestions"] as? [[String: Any]]
            guard let first = suggestions?.first,
                  let data2 = first["data"] as? [String: Any],
                  let exerciseID = data2["id"] as? Int
            else { return nil }

            return await fetchExerciseImage(exerciseID: exerciseID)
        } catch {
            return nil
        }
    }

    // ── Wger API: Bild für Übungs-ID ──
    private func fetchExerciseImage(exerciseID: Int) async -> URL? {
        guard let url = URL(string:
            "https://wger.de/api/v2/exerciseimage/?exercise=\(exerciseID)&format=json")
        else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let results = json?["results"] as? [[String: Any]]
            if let firstImage = results?.first,
               let imageStr = firstImage["image"] as? String {
                return URL(string: imageStr)
            }
            return nil
        } catch {
            return nil
        }
    }
}

// ───────────────────────────────────────────
// MARK: – Wiederverwendbare Bild-Komponente
// ───────────────────────────────────────────

struct WgerImageView: View {

    let exerciseName: String
    let size: CGFloat

    @State private var imageURL: URL? = nil
    @State private var isLoading = true

    private let service = WgerImageService.shared

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                            .clipped()
                    case .failure:
                        placeholderIcon
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        placeholderIcon
                    }
                }
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                placeholderIcon
            }
        }
        .task {
            await service.load(for: exerciseName)
            imageURL = service.imageURL(for: exerciseName)
            isLoading = false
        }
    }

    var placeholderIcon: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: size * 0.5))
            .foregroundColor(.secondary)
            .frame(width: size, height: size)
            .background(Color(uiColor: UIColor.systemGray6))
            .cornerRadius(8)
    }
}
