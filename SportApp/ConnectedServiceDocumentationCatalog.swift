import Foundation

struct ConnectedServiceDocumentation: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let sections: [ServiceDocumentationSection]

    var allFields: [ServiceDocumentationField] {
        sections.flatMap(\.fields)
    }
}

struct ServiceDocumentationSection: Identifiable, Equatable {
    let id: String
    let title: String
    let fields: [ServiceDocumentationField]
}

struct ServiceDocumentationField: Identifiable, Equatable {
    let systemName: String
    let humanName: String
    let description: String
    let supportedTypes: [SupportedTrainingType]

    var id: String { systemName }
}

struct SupportedTrainingType: Identifiable, Equatable, Hashable, Comparable {
    let id: String
    let title: String

    static func < (lhs: SupportedTrainingType, rhs: SupportedTrainingType) -> Bool {
        let titleComparison = lhs.title.localizedStandardCompare(rhs.title)
        if titleComparison == .orderedSame {
            return lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
        }

        return titleComparison == .orderedAscending
    }
}

enum ConnectedServiceDocumentationCatalog {
    static let appleHealth = ConnectedServiceDocumentation(
        id: "appleHealth",
        title: "Apple Health",
        summary: "Поля, которые текущая интеграция SportApp читает из Apple Health для тренировок, карточек, графика и дедупликации.",
        sections: [
            ServiceDocumentationSection(
                id: "identity-time",
                title: "Идентификация и время",
                fields: [
                    appleHealthField(
                        "HKWorkout.uuid",
                        "ID тренировки Apple Health",
                        "Используется как стабильная ссылка на тренировку для дедупликации при повторной синхронизации.",
                        supportedTypeIDs: appleHealthImportedTypeIDs
                    ),
                    appleHealthField(
                        "HKWorkout.workoutActivityType",
                        "Тип тренировки",
                        "Определяет категорию тренировки, из которой приложение строит русское название и фильтры.",
                        supportedTypeIDs: appleHealthImportedTypeIDs
                    ),
                    appleHealthField(
                        "HKWorkout.startDate",
                        "Время начала",
                        "Используется для сортировки, фильтров периода, графика и дедупликации.",
                        supportedTypeIDs: appleHealthImportedTypeIDs
                    ),
                    appleHealthField(
                        "HKWorkout.duration",
                        "Длительность",
                        "Используется в карточках и в расчете усилия через калории в минуту.",
                        supportedTypeIDs: appleHealthImportedTypeIDs
                    )
                ]
            ),
            ServiceDocumentationSection(
                id: "metrics",
                title: "Метрики",
                fields: [
                    appleHealthField(
                        "HKQuantityTypeIdentifier.activeEnergyBurned",
                        "Активные калории",
                        "Используется в карточках и в расчете усилия.",
                        supportedTypeIDs: appleHealthImportedTypeIDs
                    ),
                    appleHealthField(
                        "HKWorkout.totalDistance / distanceWalkingRunning",
                        "Дистанция ходьбы или бега",
                        "Используется как расстояние тренировки в метрах.",
                        supportedTypeIDs: ["running", "walking"]
                    ),
                    appleHealthField(
                        "HKWorkout.totalDistance / distanceCycling",
                        "Дистанция велосипеда",
                        "Используется как расстояние тренировки в метрах.",
                        supportedTypeIDs: ["cycling"]
                    ),
                    appleHealthField(
                        "HKWorkout.totalDistance / distanceSwimming",
                        "Дистанция плавания",
                        "Используется как расстояние плавательной тренировки в метрах.",
                        supportedTypeIDs: ["swimming", "lap_swimming", "open_water_swimming"]
                    )
                ]
            ),
            ServiceDocumentationSection(
                id: "swimming",
                title: "Плавание",
                fields: [
                    appleHealthField(
                        "HKMetadataKeySwimmingLocationType",
                        "Тип места плавания",
                        "Отличает бассейн от открытой воды, если Apple Health передает metadata.",
                        supportedTypeIDs: ["lap_swimming", "open_water_swimming"]
                    ),
                    appleHealthField(
                        "HKMetadataKeyLapLength",
                        "Длина дорожки бассейна",
                        "Используется как fallback-признак бассейна, когда Apple Health не передает HKMetadataKeySwimmingLocationType.",
                        supportedTypeIDs: ["lap_swimming"]
                    )
                ]
            )
        ]
    )

    static let garminConnect = ConnectedServiceDocumentation(
        id: "garminConnect",
        title: "Garmin Connect",
        summary: "Top-level поля из Garmin summarizedActivities export. В справочник попадают только названия полей, описания и типы активностей, без значений тренировок.",
        sections: [
            garminSection(
                "identity-time",
                "Идентификаторы и время",
                [
                    "activityId",
                    "uuidMsb",
                    "uuidLsb",
                    "userProfileId",
                    "name",
                    "activityType",
                    "sportType",
                    "eventTypeId",
                    "rule",
                    "timeZoneId",
                    "beginTimestamp",
                    "startTimeGmt",
                    "startTimeLocal"
                ]
            ),
            garminSection(
                "duration-distance-energy",
                "Длительность, дистанция и энергия",
                [
                    "duration",
                    "elapsedDuration",
                    "movingDuration",
                    "distance",
                    "calories",
                    "bmrCalories"
                ]
            ),
            garminSection(
                "heart-load",
                "Пульс, зоны и нагрузка",
                [
                    "avgHr",
                    "maxHr",
                    "minHr",
                    "hrTimeInZone_0",
                    "hrTimeInZone_1",
                    "hrTimeInZone_2",
                    "hrTimeInZone_3",
                    "hrTimeInZone_4",
                    "hrTimeInZone_5",
                    "hrTimeInZone_6",
                    "activityTrainingLoad",
                    "aerobicTrainingEffect",
                    "anaerobicTrainingEffect",
                    "aerobicTrainingEffectMessage",
                    "anaerobicTrainingEffectMessage",
                    "trainingEffectLabel"
                ]
            ),
            garminSection(
                "speed-cadence-motion",
                "Скорость, темп, каденс и движение",
                [
                    "avgSpeed",
                    "maxSpeed",
                    "avgFractionalCadence",
                    "maxFractionalCadence",
                    "avgRunCadence",
                    "maxRunCadence",
                    "avgDoubleCadence",
                    "maxDoubleCadence",
                    "avgBikeCadence",
                    "maxBikeCadence",
                    "avgStrideLength",
                    "avgGradeAdjustedSpeed",
                    "avgGroundContactTime",
                    "avgVerticalOscillation",
                    "avgVerticalRatio",
                    "maxVerticalSpeed"
                ]
            ),
            garminSection(
                "elevation-location",
                "Высота, координаты и место",
                [
                    "elevationGain",
                    "elevationLoss",
                    "minElevation",
                    "maxElevation",
                    "startLatitude",
                    "startLongitude",
                    "endLatitude",
                    "endLongitude",
                    "maxLatitude",
                    "maxLongitude",
                    "minLatitude",
                    "minLongitude",
                    "locationName",
                    "elevationCorrected"
                ]
            ),
            garminSection(
                "swimming",
                "Плавание",
                [
                    "activeLengths",
                    "avgStrokes",
                    "strokes",
                    "avgStrokeDistance",
                    "avgSwimCadence",
                    "maxSwimCadence",
                    "avgSwolf",
                    "poolLength"
                ]
            ),
            garminSection(
                "paddle",
                "SUP и гребковые активности",
                [
                    "avgStrokeCadence",
                    "maxStrokeCadence"
                ]
            ),
            garminSection(
                "strength",
                "Силовые тренировки",
                [
                    "activeSets",
                    "totalSets",
                    "totalReps",
                    "summarizedExerciseSets",
                    "workoutId"
                ]
            ),
            garminSection(
                "power",
                "Мощность",
                [
                    "avgPower",
                    "maxPower",
                    "normPower",
                    "max20MinPower",
                    "trainingStressScore",
                    "intensityFactor",
                    "isRunPowerWindDataEnabled",
                    "runPowerWindDataEnabled",
                    "powerTimeInZone_0",
                    "powerTimeInZone_1",
                    "powerTimeInZone_2",
                    "powerTimeInZone_3",
                    "powerTimeInZone_4",
                    "powerTimeInZone_5",
                    "powerTimeInZone_6",
                    "powerTimeInZone_7"
                ]
            ),
            garminSection(
                "wellness",
                "Температура, вода, самочувствие и стресс",
                [
                    "minTemperature",
                    "maxTemperature",
                    "waterEstimated",
                    "workoutFeel",
                    "workoutRpe",
                    "differenceBodyBattery",
                    "avgStress",
                    "maxStress",
                    "startStress",
                    "endStress",
                    "differenceStress",
                    "avgRespirationRate",
                    "maxRespirationRate",
                    "minRespirationRate"
                ]
            ),
            garminSection(
                "steps-intensity",
                "Шаги, этажи, VO2 Max и интенсивность",
                [
                    "steps",
                    "floorsClimbed",
                    "floorsDescended",
                    "jumpCount",
                    "surfaceInterval",
                    "vO2MaxValue",
                    "moderateIntensityMinutes",
                    "vigorousIntensityMinutes"
                ]
            ),
            garminSection(
                "flags-service",
                "Флаги и служебные признаки",
                [
                    "atpActivity",
                    "autoCalcCalories",
                    "decoDive",
                    "favorite",
                    "parent",
                    "pr",
                    "purposeful",
                    "manufacturer",
                    "deviceId",
                    "lapCount",
                    "summarizedDiveInfo"
                ]
            ),
            garminSection(
                "splits-structures",
                "Разбиения и дополнительные структуры",
                [
                    "splitSummaries",
                    "splits",
                    "description"
                ]
            )
        ]
    )

    static let services = [appleHealth, garminConnect]

    nonisolated private static let appleHealthImportedTypeIDs = [
        "cycling",
        "running",
        "walking",
        "strength_training",
        "elliptical",
        "swimming",
        "lap_swimming",
        "open_water_swimming",
        "other"
    ]

    nonisolated private static let allGarminTypeIDs = [
        "cycling",
        "elliptical",
        "indoor_cardio",
        "indoor_cycling",
        "lap_swimming",
        "meditation",
        "open_water_swimming",
        "other",
        "running",
        "stand_up_paddleboarding_v2",
        "strength_training",
        "walking"
    ]

    nonisolated private static let typeTitles = [
        "cycling": "Велик",
        "indoor_cycling": "Велик",
        "running": "Бег",
        "walking": "Ходьба",
        "lap_swimming": "Бассейн",
        "open_water_swimming": "Плавание Море",
        "swimming": "Плавание",
        "strength_training": "Силовая",
        "elliptical": "Эллипс",
        "stand_up_paddleboarding_v2": "SUP",
        "indoor_cardio": "Кардио",
        "meditation": "Медитация",
        "other": "Другое"
    ]

    nonisolated private static let garminSupportOverrides = [
        "activeLengths": ["lap_swimming"],
        "activeSets": ["strength_training"],
        "avgBikeCadence": ["indoor_cycling"],
        "avgDoubleCadence": ["elliptical", "other", "running", "walking"],
        "avgGradeAdjustedSpeed": ["running"],
        "avgGroundContactTime": ["running"],
        "avgPower": ["indoor_cycling", "running"],
        "avgRespirationRate": ["meditation"],
        "avgRunCadence": ["elliptical", "other", "running", "walking"],
        "avgStress": ["meditation"],
        "avgStrideLength": ["elliptical", "other", "running", "walking"],
        "avgStrokeCadence": ["stand_up_paddleboarding_v2"],
        "avgStrokeDistance": ["lap_swimming", "open_water_swimming"],
        "avgStrokes": ["lap_swimming"],
        "avgSwimCadence": ["lap_swimming", "open_water_swimming"],
        "avgSwolf": ["lap_swimming", "open_water_swimming"],
        "avgVerticalOscillation": ["running"],
        "avgVerticalRatio": ["running"],
        "description": ["lap_swimming"],
        "differenceBodyBattery": ["cycling", "open_water_swimming", "running", "strength_training"],
        "differenceStress": ["meditation"],
        "elevationGain": ["cycling", "other", "running", "walking"],
        "elevationLoss": ["cycling", "other", "running", "walking"],
        "endLatitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "endLongitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "endStress": ["meditation"],
        "floorsClimbed": ["meditation"],
        "floorsDescended": ["meditation"],
        "intensityFactor": ["indoor_cycling"],
        "isRunPowerWindDataEnabled": ["running"],
        "jumpCount": ["meditation"],
        "locationName": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "max20MinPower": ["indoor_cycling"],
        "maxBikeCadence": ["indoor_cycling"],
        "maxDoubleCadence": ["elliptical", "other", "running", "walking"],
        "maxElevation": ["cycling", "other", "running", "walking"],
        "maxPower": ["indoor_cycling", "running"],
        "maxRespirationRate": ["meditation"],
        "maxRunCadence": ["elliptical", "other", "running", "walking"],
        "maxSpeed": ["cycling", "lap_swimming", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "maxStress": ["meditation"],
        "maxStrokeCadence": ["stand_up_paddleboarding_v2"],
        "maxSwimCadence": ["open_water_swimming"],
        "maxTemperature": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "meditation", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "strength_training", "walking"],
        "maxVerticalSpeed": ["cycling", "other", "running", "walking"],
        "minElevation": ["cycling", "other", "running", "walking"],
        "minLatitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "minLongitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "minRespirationRate": ["meditation"],
        "minTemperature": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "meditation", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "strength_training", "walking"],
        "moderateIntensityMinutes": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "lap_swimming", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "strength_training", "walking"],
        "normPower": ["indoor_cycling", "running"],
        "poolLength": ["lap_swimming"],
        "powerTimeInZone_0": ["indoor_cycling", "running"],
        "powerTimeInZone_1": ["indoor_cycling", "running"],
        "powerTimeInZone_2": ["indoor_cycling", "running"],
        "powerTimeInZone_3": ["indoor_cycling", "running"],
        "powerTimeInZone_4": ["indoor_cycling", "running"],
        "powerTimeInZone_5": ["indoor_cycling", "running"],
        "powerTimeInZone_6": ["indoor_cycling"],
        "powerTimeInZone_7": ["indoor_cycling"],
        "runPowerWindDataEnabled": ["running"],
        "splitSummaries": ["running", "strength_training"],
        "splits": ["running", "strength_training"],
        "sportType": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "lap_swimming", "meditation", "open_water_swimming", "other", "running", "strength_training", "walking"],
        "startLatitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "startLongitude": ["cycling", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "walking"],
        "startStress": ["meditation"],
        "steps": ["elliptical", "indoor_cardio", "meditation", "other", "running", "strength_training", "walking"],
        "strokes": ["indoor_cycling", "lap_swimming", "open_water_swimming", "stand_up_paddleboarding_v2"],
        "summarizedExerciseSets": ["strength_training"],
        "surfaceInterval": ["meditation"],
        "totalReps": ["strength_training"],
        "totalSets": ["strength_training"],
        "trainingStressScore": ["indoor_cycling"],
        "vO2MaxValue": ["running", "walking"],
        "vigorousIntensityMinutes": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "lap_swimming", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "strength_training", "walking"],
        "waterEstimated": ["cycling", "elliptical", "indoor_cardio", "indoor_cycling", "meditation", "open_water_swimming", "other", "running", "stand_up_paddleboarding_v2", "strength_training", "walking"],
        "workoutFeel": ["cycling", "open_water_swimming", "running"],
        "workoutId": ["strength_training"],
        "workoutRpe": ["cycling", "open_water_swimming", "running"]
    ]

    nonisolated private static func garminSection(_ id: String, _ title: String, _ fieldNames: [String]) -> ServiceDocumentationSection {
        ServiceDocumentationSection(
            id: id,
            title: title,
            fields: fieldNames.map(garminField)
        )
    }

    nonisolated private static func appleHealthField(
        _ systemName: String,
        _ humanName: String,
        _ description: String,
        supportedTypeIDs: [String]
    ) -> ServiceDocumentationField {
        ServiceDocumentationField(
            systemName: systemName,
            humanName: humanName,
            description: description,
            supportedTypes: supportedTypes(for: supportedTypeIDs)
        )
    }

    nonisolated private static func garminField(_ systemName: String) -> ServiceDocumentationField {
        ServiceDocumentationField(
            systemName: systemName,
            humanName: garminHumanName(for: systemName),
            description: garminDescription(for: systemName),
            supportedTypes: supportedTypes(for: garminSupportOverrides[systemName] ?? allGarminTypeIDs)
        )
    }

    nonisolated private static func supportedTypes(for ids: [String]) -> [SupportedTrainingType] {
        ids.map { id in
            SupportedTrainingType(id: id, title: typeTitles[id] ?? id)
        }
        .sorted()
    }

    nonisolated private static func garminHumanName(for systemName: String) -> String {
        if let zone = zoneNumber(systemName, prefix: "hrTimeInZone_") {
            return "Время пульса в зоне \(zone)"
        }

        if let zone = zoneNumber(systemName, prefix: "powerTimeInZone_") {
            return "Время мощности в зоне \(zone)"
        }

        switch systemName {
        case "activityId": return "ID тренировки Garmin"
        case "uuidMsb": return "UUID, старшие биты"
        case "uuidLsb": return "UUID, младшие биты"
        case "userProfileId": return "ID профиля Garmin"
        case "name": return "Название тренировки"
        case "activityType": return "Тип активности"
        case "sportType": return "Тип спорта"
        case "eventTypeId": return "Тип события"
        case "rule": return "Правило активности"
        case "timeZoneId": return "Часовой пояс"
        case "beginTimestamp": return "Начало в timestamp"
        case "startTimeGmt": return "Время начала GMT"
        case "startTimeLocal": return "Локальное время начала"
        case "duration": return "Длительность"
        case "elapsedDuration": return "Прошедшее время"
        case "movingDuration": return "Время в движении"
        case "distance": return "Дистанция"
        case "calories": return "Калории"
        case "bmrCalories": return "Базовые калории"
        case "avgHr": return "Средний пульс"
        case "maxHr": return "Максимальный пульс"
        case "minHr": return "Минимальный пульс"
        case "activityTrainingLoad": return "Тренировочная нагрузка"
        case "aerobicTrainingEffect": return "Аэробный эффект"
        case "anaerobicTrainingEffect": return "Анаэробный эффект"
        case "aerobicTrainingEffectMessage": return "Сообщение аэробного эффекта"
        case "anaerobicTrainingEffectMessage": return "Сообщение анаэробного эффекта"
        case "trainingEffectLabel": return "Метка тренировочного эффекта"
        case "avgSpeed": return "Средняя скорость"
        case "maxSpeed": return "Максимальная скорость"
        case "avgFractionalCadence": return "Средний дробный каденс"
        case "maxFractionalCadence": return "Максимальный дробный каденс"
        case "avgRunCadence": return "Средний беговой каденс"
        case "maxRunCadence": return "Максимальный беговой каденс"
        case "avgDoubleCadence": return "Средний двойной каденс"
        case "maxDoubleCadence": return "Максимальный двойной каденс"
        case "avgBikeCadence": return "Средний велокаденс"
        case "maxBikeCadence": return "Максимальный велокаденс"
        case "avgStrideLength": return "Средняя длина шага"
        case "avgGradeAdjustedSpeed": return "Средняя GAP-скорость"
        case "avgGroundContactTime": return "Среднее время контакта с землей"
        case "avgVerticalOscillation": return "Средние вертикальные колебания"
        case "avgVerticalRatio": return "Средний вертикальный коэффициент"
        case "maxVerticalSpeed": return "Максимальная вертикальная скорость"
        case "elevationGain": return "Набор высоты"
        case "elevationLoss": return "Потеря высоты"
        case "minElevation": return "Минимальная высота"
        case "maxElevation": return "Максимальная высота"
        case "startLatitude": return "Стартовая широта"
        case "startLongitude": return "Стартовая долгота"
        case "endLatitude": return "Финишная широта"
        case "endLongitude": return "Финишная долгота"
        case "maxLatitude": return "Максимальная широта"
        case "maxLongitude": return "Максимальная долгота"
        case "minLatitude": return "Минимальная широта"
        case "minLongitude": return "Минимальная долгота"
        case "locationName": return "Название места"
        case "elevationCorrected": return "Высота скорректирована"
        case "activeLengths": return "Активные отрезки бассейна"
        case "avgStrokes": return "Среднее число гребков"
        case "strokes": return "Гребки"
        case "avgStrokeDistance": return "Средняя дистанция гребка"
        case "avgSwimCadence": return "Средний плавательный каденс"
        case "maxSwimCadence": return "Максимальный плавательный каденс"
        case "avgSwolf": return "Средний SWOLF"
        case "poolLength": return "Длина бассейна"
        case "avgStrokeCadence": return "Средний гребковый каденс"
        case "maxStrokeCadence": return "Максимальный гребковый каденс"
        case "activeSets": return "Активные подходы"
        case "totalSets": return "Всего подходов"
        case "totalReps": return "Всего повторений"
        case "summarizedExerciseSets": return "Сводка упражнений"
        case "workoutId": return "ID силовой тренировки"
        case "avgPower": return "Средняя мощность"
        case "maxPower": return "Максимальная мощность"
        case "normPower": return "Нормализованная мощность"
        case "max20MinPower": return "Максимальная мощность за 20 минут"
        case "trainingStressScore": return "Training Stress Score"
        case "intensityFactor": return "Intensity Factor"
        case "isRunPowerWindDataEnabled": return "Run Power Wind включен"
        case "runPowerWindDataEnabled": return "Данные Run Power Wind"
        case "minTemperature": return "Минимальная температура"
        case "maxTemperature": return "Максимальная температура"
        case "waterEstimated": return "Оценка воды"
        case "workoutFeel": return "Ощущение тренировки"
        case "workoutRpe": return "Субъективная нагрузка RPE"
        case "differenceBodyBattery": return "Изменение Body Battery"
        case "avgStress": return "Средний стресс"
        case "maxStress": return "Максимальный стресс"
        case "startStress": return "Стресс в начале"
        case "endStress": return "Стресс в конце"
        case "differenceStress": return "Изменение стресса"
        case "avgRespirationRate": return "Средняя частота дыхания"
        case "maxRespirationRate": return "Максимальная частота дыхания"
        case "minRespirationRate": return "Минимальная частота дыхания"
        case "steps": return "Шаги"
        case "floorsClimbed": return "Этажи вверх"
        case "floorsDescended": return "Этажи вниз"
        case "jumpCount": return "Прыжки"
        case "surfaceInterval": return "Поверхностный интервал"
        case "vO2MaxValue": return "VO2 Max"
        case "moderateIntensityMinutes": return "Минуты умеренной интенсивности"
        case "vigorousIntensityMinutes": return "Минуты высокой интенсивности"
        case "atpActivity": return "ATP-активность"
        case "autoCalcCalories": return "Авторасчет калорий"
        case "decoDive": return "Декомпрессионное погружение"
        case "favorite": return "Избранное"
        case "parent": return "Родительская запись"
        case "pr": return "Личный рекорд"
        case "purposeful": return "Целенаправленная активность"
        case "manufacturer": return "Производитель устройства"
        case "deviceId": return "ID устройства"
        case "lapCount": return "Количество кругов"
        case "summarizedDiveInfo": return "Сводка погружения"
        case "splitSummaries": return "Сводки разбиений"
        case "splits": return "Разбиения"
        case "description": return "Описание тренировки"
        default: return systemName
        }
    }

    nonisolated private static func garminDescription(for systemName: String) -> String {
        if let zone = zoneNumber(systemName, prefix: "hrTimeInZone_") {
            return "Время, проведенное в пульсовой зоне \(zone), если Garmin отдал это поле для активности."
        }

        if let zone = zoneNumber(systemName, prefix: "powerTimeInZone_") {
            return "Время, проведенное в зоне мощности \(zone), если Garmin отдал power-аналитику для активности."
        }

        switch systemName {
        case "activityId", "uuidMsb", "uuidLsb", "userProfileId":
            return "Идентификатор или часть идентификатора, который Garmin использует для связи и дедупликации записей."
        case "name":
            return "Название тренировки в Garmin Connect."
        case "activityType", "sportType", "eventTypeId", "rule":
            return "Классификация тренировки в Garmin Connect: тип активности, спорта или служебное правило."
        case "timeZoneId", "beginTimestamp", "startTimeGmt", "startTimeLocal":
            return "Временное поле, которое помогает правильно разместить тренировку на календаре."
        case "duration", "elapsedDuration", "movingDuration":
            return "Длительность тренировки или ее часть: общее, прошедшее или активное время."
        case "distance":
            return "Дистанция тренировки в единицах Garmin export, которую приложение нормализует перед отображением."
        case "calories", "bmrCalories":
            return "Энергетическая метрика тренировки: активные или базовые калории."
        case "avgHr", "maxHr", "minHr":
            return "Пульсовая метрика тренировки: среднее, максимальное или минимальное значение."
        case "activityTrainingLoad", "aerobicTrainingEffect", "anaerobicTrainingEffect", "aerobicTrainingEffectMessage", "anaerobicTrainingEffectMessage", "trainingEffectLabel":
            return "Показатель нагрузки или тренировочного эффекта, рассчитанный Garmin."
        case "avgSpeed", "maxSpeed", "avgFractionalCadence", "maxFractionalCadence", "avgRunCadence", "maxRunCadence", "avgDoubleCadence", "maxDoubleCadence", "avgBikeCadence", "maxBikeCadence", "avgStrideLength", "avgGradeAdjustedSpeed", "avgGroundContactTime", "avgVerticalOscillation", "avgVerticalRatio", "maxVerticalSpeed":
            return "Метрика движения: скорость, каденс, длина шага или беговая динамика."
        case "elevationGain", "elevationLoss", "minElevation", "maxElevation", "elevationCorrected":
            return "Высотная метрика тренировки: набор, потеря, минимум, максимум или признак коррекции."
        case "startLatitude", "startLongitude", "endLatitude", "endLongitude", "maxLatitude", "maxLongitude", "minLatitude", "minLongitude", "locationName":
            return "Географическое поле тренировки. В справочнике хранится только имя поля, не координаты."
        case "activeLengths", "avgStrokes", "strokes", "avgStrokeDistance", "avgSwimCadence", "maxSwimCadence", "avgSwolf", "poolLength":
            return "Плавательная метрика: отрезки, гребки, каденс, SWOLF или длина бассейна."
        case "avgStrokeCadence", "maxStrokeCadence":
            return "Гребковый каденс для SUP или похожих гребковых активностей."
        case "activeSets", "totalSets", "totalReps", "summarizedExerciseSets", "workoutId":
            return "Поле силовой тренировки: подходы, повторения, упражнения или связанный workout id."
        case "avgPower", "maxPower", "normPower", "max20MinPower", "trainingStressScore", "intensityFactor", "isRunPowerWindDataEnabled", "runPowerWindDataEnabled":
            return "Power-аналитика тренировки: мощность, TSS, IF или признаки беговой мощности с ветром."
        case "minTemperature", "maxTemperature", "waterEstimated", "workoutFeel", "workoutRpe", "differenceBodyBattery", "avgStress", "maxStress", "startStress", "endStress", "differenceStress", "avgRespirationRate", "maxRespirationRate", "minRespirationRate":
            return "Поле состояния организма или окружения: температура, вода, самочувствие, стресс, Body Battery или дыхание."
        case "steps", "floorsClimbed", "floorsDescended", "jumpCount", "surfaceInterval", "vO2MaxValue", "moderateIntensityMinutes", "vigorousIntensityMinutes":
            return "Дополнительная активность: шаги, этажи, прыжки, VO2 Max или минуты интенсивности."
        case "atpActivity", "autoCalcCalories", "decoDive", "favorite", "parent", "pr", "purposeful", "manufacturer", "deviceId", "lapCount", "summarizedDiveInfo":
            return "Служебный признак Garmin, флаг активности, устройство или дополнительная сводка."
        case "splitSummaries", "splits", "description":
            return "Дополнительная структура Garmin export: разбиения тренировки, их сводки или описание."
        default:
            return "Поле Garmin summarizedActivities export, найденное в текущей выгрузке."
        }
    }

    nonisolated private static func zoneNumber(_ systemName: String, prefix: String) -> String? {
        guard systemName.hasPrefix(prefix) else { return nil }
        return String(systemName.dropFirst(prefix.count))
    }
}
