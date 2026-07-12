import Foundation

enum TrainingActivitySource: String, Codable, CaseIterable {
    case appleHealth
    case garminOfficialExport
    case bundledGarminExport

    var priority: Int {
        switch self {
        case .appleHealth:
            return 3
        case .garminOfficialExport:
            return 2
        case .bundledGarminExport:
            return 1
        }
    }
}

struct TrainingActivitySourceReference: Codable, Hashable {
    let source: TrainingActivitySource
    let id: String
}

struct TrainingActivity: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var activityType: String
    var sportType: String?
    var startDate: Date
    var durationSeconds: Double?
    var caloriesKilocalories: Double?
    var distanceMeters: Double?
    var primarySource: TrainingActivitySource
    var sourceReferences: [TrainingActivitySourceReference]

    nonisolated init(
        id: UUID,
        name: String,
        activityType: String,
        sportType: String?,
        startDate: Date,
        durationSeconds: Double?,
        caloriesKilocalories: Double?,
        distanceMeters: Double?,
        primarySource: TrainingActivitySource,
        sourceReferences: [TrainingActivitySourceReference]
    ) {
        self.id = id
        self.name = name
        self.activityType = activityType
        self.sportType = sportType
        self.startDate = startDate
        self.durationSeconds = durationSeconds
        self.caloriesKilocalories = caloriesKilocalories
        self.distanceMeters = distanceMeters
        self.primarySource = primarySource
        self.sourceReferences = sourceReferences
    }

    var startMilliseconds: Double {
        startDate.timeIntervalSince1970 * 1_000
    }

    func hasSourceReference(_ reference: TrainingActivitySourceReference) -> Bool {
        sourceReferences.contains(reference)
    }

    mutating func addSourceReferences(_ references: [TrainingActivitySourceReference]) {
        for reference in references where !sourceReferences.contains(reference) {
            sourceReferences.append(reference)
        }
    }
}

struct TrainingImportSummary: Codable, Equatable {
    var added = 0
    var skippedDuplicates = 0
    var updated = 0
    var errors = 0

    static let empty = TrainingImportSummary()

    mutating func add(_ other: TrainingImportSummary) {
        added += other.added
        skippedDuplicates += other.skippedDuplicates
        updated += other.updated
        errors += other.errors
    }
}

struct TrainingImportResult: Equatable {
    let activities: [TrainingActivity]
    let summary: TrainingImportSummary
}
