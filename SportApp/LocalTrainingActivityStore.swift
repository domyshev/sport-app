import Foundation

struct LocalTrainingActivityStore {
    let fileURL: URL
    var deduplicator = TrainingActivityDeduplicator()

    init(fileURL: URL = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func loadActivities() throws -> [TrainingActivity] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try Self.decoder.decode([TrainingActivity].self, from: data)
    }

    func saveActivities(_ activities: [TrainingActivity]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(activities)
        try data.write(to: fileURL, options: [.atomic])
    }

    func clearActivities() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        try FileManager.default.removeItem(at: fileURL)
    }

    func merge(_ incoming: [TrainingActivity]) throws -> TrainingImportSummary {
        let existing = try loadActivities()
        let result = deduplicator.merge(existing: existing, incoming: incoming)
        try saveActivities(result.activities)
        return result.summary
    }

    private static func defaultFileURL() -> URL {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return supportURL
            .appending(path: "SportApp", directoryHint: .isDirectory)
            .appending(path: "training_activities.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

enum TrainingDataClearance {
    static let serviceCode = "111"

    static func canClear(with code: String) -> Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines) == serviceCode
    }
}
