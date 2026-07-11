import Foundation

struct TrainingActivityFieldPreferences: Codable, Equatable {
    private var values: [String: [TrainingActivityDisplayField]]

    init(values: [String: [TrainingActivityDisplayField]] = [:]) {
        self.values = values
    }

    func fields(for activityType: String) -> [TrainingActivityDisplayField] {
        values[activityType] ?? TrainingActivityDisplayField.defaultFields
    }

    mutating func setFields(_ fields: [TrainingActivityDisplayField], for activityType: String) {
        values[activityType] = fields
    }

    func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

extension TrainingActivityDisplayField {
    var russianTitle: String {
        switch self {
        case .distance: return "Расстояние"
        case .duration: return "Длительность"
        case .startTime: return "Начало"
        case .calories: return "Калории"
        }
    }
}
