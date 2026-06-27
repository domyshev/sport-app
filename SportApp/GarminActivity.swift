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

    var id: Int64 { activityId }
}
