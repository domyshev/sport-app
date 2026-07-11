import Foundation

struct GarminActivitiesExport: Decodable {
    let summarizedActivitiesExport: [GarminActivity]
}

struct GarminActivity: Decodable, Equatable, Identifiable {
    let activityId: Int64
    let name: String
    let activityType: String
    let sportType: String?
    let startTimeLocal: Double
    let startTimeGmt: Double?
    let duration: Double?
    let calories: Double?
    let distance: Double?

    init(
        activityId: Int64,
        name: String,
        activityType: String,
        sportType: String?,
        startTimeLocal: Double,
        startTimeGmt: Double?,
        duration: Double?,
        calories: Double?,
        distance: Double? = nil
    ) {
        self.activityId = activityId
        self.name = name
        self.activityType = activityType
        self.sportType = sportType
        self.startTimeLocal = startTimeLocal
        self.startTimeGmt = startTimeGmt
        self.duration = duration
        self.calories = calories
        self.distance = distance
    }

    private enum CodingKeys: String, CodingKey {
        case activityId, name, activityType, sportType, startTimeLocal, startTimeGmt, duration, calories, distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            activityId: try container.decode(Int64.self, forKey: .activityId),
            name: try container.decode(String.self, forKey: .name),
            activityType: try container.decode(String.self, forKey: .activityType),
            sportType: try container.decodeIfPresent(String.self, forKey: .sportType),
            startTimeLocal: try container.decode(Double.self, forKey: .startTimeLocal),
            startTimeGmt: try container.decodeIfPresent(Double.self, forKey: .startTimeGmt),
            duration: try container.decodeIfPresent(Double.self, forKey: .duration),
            calories: try container.decodeIfPresent(Double.self, forKey: .calories),
            distance: try container.decodeIfPresent(Double.self, forKey: .distance)
        )
    }

    var id: Int64 { activityId }
}
