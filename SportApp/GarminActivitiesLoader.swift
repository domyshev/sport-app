import Foundation

struct GarminActivitiesLoader {
    enum LoaderError: Error {
        case resourceNotFound
    }

    var bundle: Bundle = .main
    var resourceName: String = "garmin_summarized_activities"

    func load() throws -> [GarminActivity] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoaderError.resourceNotFound
        }

        let data = try Data(contentsOf: url)
        return try Self.decodeActivities(from: data)
    }

    static func decodeActivities(from data: Data) throws -> [GarminActivity] {
        let exports = try JSONDecoder().decode([GarminActivitiesExport].self, from: data)
        return exports.flatMap(\.summarizedActivitiesExport)
    }
}
