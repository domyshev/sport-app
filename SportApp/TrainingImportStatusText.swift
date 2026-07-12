enum TrainingImportStatusText {
    static func garminImport(_ importSummary: TrainingImportSummary) -> String {
        "Garmin import: \(summary(importSummary))"
    }

    static func summary(_ importSummary: TrainingImportSummary) -> String {
        "добавлено \(importSummary.added), обновлено \(importSummary.updated), дублей \(importSummary.skippedDuplicates), ошибок \(importSummary.errors)"
    }
}
