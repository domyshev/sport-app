import Testing
@testable import SportApp

struct ConnectedServiceDocumentationCatalogTests {
    @Test func catalogContainsAppleHealthAndGarminConnect() {
        #expect(ConnectedServiceDocumentationCatalog.services.map(\.id) == ["appleHealth", "garminConnect"])
        #expect(ConnectedServiceDocumentationCatalog.services.map(\.title) == ["Apple Health", "Garmin Connect"])
    }

    @Test func appleHealthCatalogContainsCurrentIntegrationFieldsOnly() {
        let expectedFieldNames = [
            "HKWorkout.uuid",
            "HKWorkout.workoutActivityType",
            "HKWorkout.startDate",
            "HKWorkout.duration",
            "HKQuantityTypeIdentifier.activeEnergyBurned",
            "HKWorkout.totalDistance / distanceWalkingRunning",
            "HKWorkout.totalDistance / distanceCycling",
            "HKWorkout.totalDistance / distanceSwimming",
            "HKMetadataKeySwimmingLocationType",
            "HKMetadataKeyLapLength"
        ]

        #expect(ConnectedServiceDocumentationCatalog.appleHealth.allFields.map(\.systemName) == expectedFieldNames)
    }

    @Test func garminCatalogContainsOneHundredThirtyTwoFields() {
        #expect(ConnectedServiceDocumentationCatalog.garminConnect.allFields.count == 132)
    }

    @Test func garminCatalogContainsAllObservedActivityTypes() {
        let expectedTypeIDs = Set([
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
        ])
        let actualTypeIDs = Set(
            ConnectedServiceDocumentationCatalog.garminConnect.allFields
                .flatMap(\.supportedTypes)
                .map(\.id)
        )

        #expect(actualTypeIDs == expectedTypeIDs)
    }

    @Test func poolLengthSupportsLapSwimming() throws {
        let field = try #require(
            ConnectedServiceDocumentationCatalog.garminConnect.allFields.first { $0.systemName == "poolLength" }
        )

        #expect(field.supportedTypes.map(\.id).contains("lap_swimming"))
    }

    @Test func appleHealthLapLengthSupportsPoolSwimming() throws {
        let field = try #require(
            ConnectedServiceDocumentationCatalog.appleHealth.allFields.first { $0.systemName == "HKMetadataKeyLapLength" }
        )

        #expect(field.supportedTypes.map(\.id).contains("lap_swimming"))
    }

    @Test func garminCatalogContainsExactObservedFieldNames() {
        let expectedFieldNames = Set([
            "activeLengths",
            "activeSets",
            "activityId",
            "activityTrainingLoad",
            "activityType",
            "aerobicTrainingEffect",
            "aerobicTrainingEffectMessage",
            "anaerobicTrainingEffect",
            "anaerobicTrainingEffectMessage",
            "atpActivity",
            "autoCalcCalories",
            "avgBikeCadence",
            "avgDoubleCadence",
            "avgFractionalCadence",
            "avgGradeAdjustedSpeed",
            "avgGroundContactTime",
            "avgHr",
            "avgPower",
            "avgRespirationRate",
            "avgRunCadence",
            "avgSpeed",
            "avgStress",
            "avgStrideLength",
            "avgStrokeCadence",
            "avgStrokeDistance",
            "avgStrokes",
            "avgSwimCadence",
            "avgSwolf",
            "avgVerticalOscillation",
            "avgVerticalRatio",
            "beginTimestamp",
            "bmrCalories",
            "calories",
            "decoDive",
            "description",
            "deviceId",
            "differenceBodyBattery",
            "differenceStress",
            "distance",
            "duration",
            "elapsedDuration",
            "elevationCorrected",
            "elevationGain",
            "elevationLoss",
            "endLatitude",
            "endLongitude",
            "endStress",
            "eventTypeId",
            "favorite",
            "floorsClimbed",
            "floorsDescended",
            "hrTimeInZone_0",
            "hrTimeInZone_1",
            "hrTimeInZone_2",
            "hrTimeInZone_3",
            "hrTimeInZone_4",
            "hrTimeInZone_5",
            "hrTimeInZone_6",
            "intensityFactor",
            "isRunPowerWindDataEnabled",
            "jumpCount",
            "lapCount",
            "locationName",
            "manufacturer",
            "max20MinPower",
            "maxBikeCadence",
            "maxDoubleCadence",
            "maxElevation",
            "maxFractionalCadence",
            "maxHr",
            "maxLatitude",
            "maxLongitude",
            "maxPower",
            "maxRespirationRate",
            "maxRunCadence",
            "maxSpeed",
            "maxStress",
            "maxStrokeCadence",
            "maxSwimCadence",
            "maxTemperature",
            "maxVerticalSpeed",
            "minElevation",
            "minHr",
            "minLatitude",
            "minLongitude",
            "minRespirationRate",
            "minTemperature",
            "moderateIntensityMinutes",
            "movingDuration",
            "name",
            "normPower",
            "parent",
            "poolLength",
            "powerTimeInZone_0",
            "powerTimeInZone_1",
            "powerTimeInZone_2",
            "powerTimeInZone_3",
            "powerTimeInZone_4",
            "powerTimeInZone_5",
            "powerTimeInZone_6",
            "powerTimeInZone_7",
            "pr",
            "purposeful",
            "rule",
            "runPowerWindDataEnabled",
            "splitSummaries",
            "splits",
            "sportType",
            "startLatitude",
            "startLongitude",
            "startStress",
            "startTimeGmt",
            "startTimeLocal",
            "steps",
            "strokes",
            "summarizedDiveInfo",
            "summarizedExerciseSets",
            "surfaceInterval",
            "timeZoneId",
            "totalReps",
            "totalSets",
            "trainingEffectLabel",
            "trainingStressScore",
            "userProfileId",
            "uuidLsb",
            "uuidMsb",
            "vO2MaxValue",
            "vigorousIntensityMinutes",
            "waterEstimated",
            "workoutFeel",
            "workoutId",
            "workoutRpe"
        ])
        let actualFieldNames = Set(ConnectedServiceDocumentationCatalog.garminConnect.allFields.map(\.systemName))

        #expect(actualFieldNames == expectedFieldNames)
    }
}
