import Foundation
import Testing
@testable import SportApp

struct TrainingActivityStoreTests {
    @Test func localStorePersistsMergedActivities() throws {
        let fileURL = temporaryStoreURL()
        let store = LocalTrainingActivityStore(fileURL: fileURL)
        let incoming = training(
            id: uuid(1),
            source: .appleHealth,
            sourceID: "health-1",
            start: "2026-06-08T10:00:00Z"
        )

        let summary = try store.merge([incoming])
        let loaded = try store.loadActivities()

        #expect(summary.added == 1)
        #expect(loaded == [incoming])
    }

    @Test func localStoreCanClearPersistedActivities() throws {
        let fileURL = temporaryStoreURL()
        let store = LocalTrainingActivityStore(fileURL: fileURL)
        let incoming = training(
            id: uuid(1),
            source: .appleHealth,
            sourceID: "health-1",
            start: "2026-06-08T10:00:00Z"
        )

        try store.saveActivities([incoming])
        try store.clearActivities()

        #expect(try store.loadActivities().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func localStoreClearanceRequiresServiceCode() {
        #expect(TrainingDataClearance.canClear(with: "111"))
        #expect(TrainingDataClearance.canClear(with: " 111 "))
        #expect(!TrainingDataClearance.canClear(with: ""))
        #expect(!TrainingDataClearance.canClear(with: "112"))
    }

    @Test func importStatusTextIncludesAddedUpdatedDuplicatesAndErrors() {
        let summary = TrainingImportSummary(
            added: 3,
            skippedDuplicates: 5,
            updated: 2,
            errors: 1
        )

        #expect(TrainingImportStatusText.garminImport(summary) == "Garmin import: добавлено 3, обновлено 2, дублей 5, ошибок 1")
    }

    @Test func garminImporterConvertsMillisecondsAndCentimetersToNormalizedUnits() throws {
        let activities = try GarminOfficialExportImporter().importActivities(
            from: Data(Self.garminJSON.utf8),
            source: .garminOfficialExport
        )

        #expect(activities.count == 1)
        #expect(activities[0].sourceReferences == [.init(source: .garminOfficialExport, id: "42")])
        #expect(activities[0].durationSeconds == 600)
        #expect(activities[0].distanceMeters == 1_500)
        #expect(activities[0].caloriesKilocalories == 120)
    }

    @Test func garminImporterReadsNestedFolderJSONFiles() throws {
        let rootURL = temporaryDirectoryURL()
        let nestedURL = rootURL.appending(path: "DI-Connect-Fitness/SummarizedActivities", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nestedURL, withIntermediateDirectories: true)
        try Data(Self.garminJSON.utf8).write(to: nestedURL.appending(path: "activities.json"))

        let activities = try GarminOfficialExportImporter().importFolder(at: rootURL)

        #expect(activities.count == 1)
        #expect(activities[0].sourceReferences == [.init(source: .garminOfficialExport, id: "42")])
    }

    @Test func garminImporterReadsDeflatedZipJSONFiles() throws {
        let zipURL = temporaryDirectoryURL().appending(path: "garmin-export.zip")
        try Data(base64Encoded: Self.deflatedGarminZipBase64)!.write(to: zipURL)

        let activities = try GarminOfficialExportImporter().importZip(at: zipURL)

        #expect(activities.count == 1)
        #expect(activities[0].name == "Zip Ride")
        #expect(activities[0].durationSeconds == 600)
        #expect(activities[0].distanceMeters == 1_500)
    }

    @Test func exactSourceIdentifierDuplicateIsSkipped() {
        let existing = training(
            id: uuid(1),
            source: .garminOfficialExport,
            sourceID: "garmin-1",
            start: "2026-06-08T10:00:00Z",
            distanceMeters: 1_000
        )
        let incoming = training(
            id: uuid(2),
            source: .garminOfficialExport,
            sourceID: "garmin-1",
            start: "2026-06-08T10:00:00Z",
            distanceMeters: 1_100
        )

        let result = TrainingActivityDeduplicator().merge(existing: [existing], incoming: [incoming])

        #expect(result.activities.count == 1)
        #expect(result.activities[0].id == existing.id)
        #expect(result.summary.added == 0)
        #expect(result.summary.skippedDuplicates == 1)
    }

    @Test func healthKitPrimaryDuplicateKeepsGarminReferenceAndCalories() {
        let garmin = training(
            id: uuid(1),
            source: .garminOfficialExport,
            sourceID: "garmin-1",
            start: "2026-06-08T10:00:00Z",
            durationSeconds: 3_600,
            caloriesKilocalories: 500,
            distanceMeters: 20_000
        )
        let health = training(
            id: uuid(2),
            source: .appleHealth,
            sourceID: "health-1",
            start: "2026-06-08T10:01:00Z",
            durationSeconds: 3_590,
            caloriesKilocalories: 480,
            distanceMeters: 20_100
        )

        let result = TrainingActivityDeduplicator().merge(existing: [garmin], incoming: [health])

        #expect(result.activities.count == 1)
        #expect(result.activities[0].id == garmin.id)
        #expect(result.activities[0].primarySource == .appleHealth)
        #expect(result.activities[0].caloriesKilocalories == 500)
        #expect(result.activities[0].distanceMeters == 20_100)
        #expect(result.activities[0].sourceReferences.contains(.init(source: .appleHealth, id: "health-1")))
        #expect(result.activities[0].sourceReferences.contains(.init(source: .garminOfficialExport, id: "garmin-1")))
        #expect(result.summary.updated == 1)
    }

    @Test func garminImportFillsMissingFieldsOnHealthKitDuplicate() {
        let health = training(
            id: uuid(1),
            source: .appleHealth,
            sourceID: "health-1",
            start: "2026-06-08T10:00:00Z",
            durationSeconds: 3_600,
            caloriesKilocalories: nil,
            distanceMeters: nil
        )
        let garmin = training(
            id: uuid(2),
            source: .garminOfficialExport,
            sourceID: "garmin-1",
            start: "2026-06-08T10:01:00Z",
            durationSeconds: 3_610,
            caloriesKilocalories: 500,
            distanceMeters: 20_000
        )

        let result = TrainingActivityDeduplicator().merge(existing: [health], incoming: [garmin])

        #expect(result.activities.count == 1)
        #expect(result.activities[0].primarySource == .appleHealth)
        #expect(result.activities[0].durationSeconds == 3_600)
        #expect(result.activities[0].caloriesKilocalories == 500)
        #expect(result.activities[0].distanceMeters == 20_000)
        #expect(result.summary.updated == 1)
    }

    @Test func garminOpenWaterDuplicateEnrichesHealthKitSwimming() {
        let health = training(
            id: uuid(1),
            source: .appleHealth,
            sourceID: "health-swim",
            start: "2026-06-11T08:00:00Z",
            activityType: "swimming",
            durationSeconds: 2_400,
            caloriesKilocalories: 468,
            distanceMeters: 2_000
        )
        let garmin = training(
            id: uuid(2),
            source: .garminOfficialExport,
            sourceID: "garmin-swim",
            start: "2026-06-11T08:01:00Z",
            activityType: "open_water_swimming",
            durationSeconds: 2_410,
            caloriesKilocalories: 544,
            distanceMeters: 2_000
        )

        let result = TrainingActivityDeduplicator().merge(existing: [health], incoming: [garmin])

        #expect(result.activities.count == 1)
        #expect(result.activities[0].primarySource == .appleHealth)
        #expect(result.activities[0].activityType == "open_water_swimming")
        #expect(result.activities[0].caloriesKilocalories == 544)
        #expect(result.activities[0].distanceMeters == 2_000)
        #expect(result.activities[0].sourceReferences.contains(.init(source: .appleHealth, id: "health-swim")))
        #expect(result.activities[0].sourceReferences.contains(.init(source: .garminOfficialExport, id: "garmin-swim")))
        #expect(result.summary.updated == 1)
    }

    @Test func distinctActivitiesAreAdded() {
        let existing = training(
            id: uuid(1),
            source: .appleHealth,
            sourceID: "health-1",
            start: "2026-06-08T10:00:00Z",
            activityType: "cycling"
        )
        let incoming = training(
            id: uuid(2),
            source: .garminOfficialExport,
            sourceID: "garmin-2",
            start: "2026-06-08T13:00:00Z",
            activityType: "running"
        )

        let result = TrainingActivityDeduplicator().merge(existing: [existing], incoming: [incoming])

        #expect(result.activities.map(\.id) == [existing.id, incoming.id])
        #expect(result.summary.added == 1)
    }

    private func training(
        id: UUID,
        source: TrainingActivitySource,
        sourceID: String,
        start: String,
        activityType: String = "cycling",
        durationSeconds: Double? = 3_600,
        caloriesKilocalories: Double? = 500,
        distanceMeters: Double? = 20_000
    ) -> TrainingActivity {
        TrainingActivity(
            id: id,
            name: "Training",
            activityType: activityType,
            sportType: nil,
            startDate: Self.isoDateFormatter.date(from: start)!,
            durationSeconds: durationSeconds,
            caloriesKilocalories: caloriesKilocalories,
            distanceMeters: distanceMeters,
            primarySource: source,
            sourceReferences: [.init(source: source, id: sourceID)]
        )
    }

    private func uuid(_ value: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", value))")!
    }

    private func temporaryStoreURL() -> URL {
        temporaryDirectoryURL().appending(path: "training-store.json")
    }

    private func temporaryDirectoryURL() -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(path: "SportAppTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static let garminJSON = """
    [
      {
        "summarizedActivitiesExport": [
          {
            "activityId": 42,
            "name": "Garmin Ride",
            "activityType": "cycling",
            "sportType": "CYCLING",
            "startTimeLocal": 1780704000000,
            "startTimeGmt": 1780704000000,
            "duration": 600000,
            "calories": 120,
            "distance": 150000
          }
        ]
      }
    ]
    """

    private static let deflatedGarminZipBase64 = """
    UEsDBBQAAAAIAOpg7FyiiompowAAAPYAAAA3AAAAREktQ29ubmVjdC1GaXRuZXNzL1N1bW1hcml6ZWRBY3Rpdml0aWVzL2FjdGl2aXRpZXMuanNvbm2PsQrCMBCGX6VkdmhFjbhJkVIoDuKipUNIghw0SUlSMZa+u5dIwcGbct/38x9pJ+JGpZiFtxRH7uEJHqQ7vQZjPTlk7UTYl4Za4E7pKiOaKYlvcochu4CQBNmSuoYhOR54D/oRlYtdCy9vZVOfq8Q9Qw5KNoazHmVB9znNN3ma30Cl/B8tRss8GI1qtzAsMhY/EOPrFAJs0TzeLrYxNHdz9wFQSwECFAMUAAAACADqYOxcooqJqaMAAAD2AAAANwAAAAAAAAAAAAAAgAEAAAAAREktQ29ubmVjdC1GaXRuZXNzL1N1bW1hcml6ZWRBY3Rpdml0aWVzL2FjdGl2aXRpZXMuanNvblBLBQYAAAAAAQABAGUAAAD4AAAAAAA=
    """

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
