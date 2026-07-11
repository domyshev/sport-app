import Testing
@testable import SportApp

struct TrainingActivityFieldPreferencesTests {
    @Test func storesCustomFieldsForOneActivityTypeWithoutChangingOthers() throws {
        var preferences = TrainingActivityFieldPreferences()

        preferences.setFields([.duration, .startTime], for: "cycling")

        #expect(preferences.fields(for: "cycling") == [.duration, .startTime])
        #expect(preferences.fields(for: "running") == TrainingActivityDisplayField.defaultFields)
    }

    @Test func roundTripsThroughJSON() throws {
        var preferences = TrainingActivityFieldPreferences()
        preferences.setFields([.distance, .calories], for: "lap_swimming")

        let data = try preferences.encode()
        let decoded = try TrainingActivityFieldPreferences.decode(from: data)

        #expect(decoded.fields(for: "lap_swimming") == [.distance, .calories])
    }
}
