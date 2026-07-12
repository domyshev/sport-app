# Документация связанных сервисов: дизайн

## Цель

Добавить в SportApp раздел документации, который открывается по иконке из главного экрана и объясняет, какие данные приложение получает из связанных сервисов.

Первый и пока основной раздел документации называется "Связанные сервисы". Внутри него есть два подраздела:

- "Apple Health"
- "Garmin Connect"

Каждый подраздел показывает список доступных полей. Для каждого поля отображаются:

- системное имя поля;
- человекочитаемое русское имя;
- описание, за что отвечает поле;
- список типов тренировок, для которых поле поддерживается.

## Принятые решения

- Документация открывается по отдельной иконке рядом с шестеренкой настроек на главном экране.
- Экран документации открывается как sheet с `NavigationStack`, чтобы не ломать существующие вкладки "Тренировки" и "График".
- Runtime-импорт Garmin export не участвует в документации. Приложение содержит статический справочник полей, составленный по анализу `from_garmin_official_export`.
- В приложение не попадают значения тренировок, даты конкретных тренировок, ID конкретных тренировок или другие приватные данные из Garmin export.
- Apple Health описывает только поля, которые текущая интеграция SportApp реально читает или использует. Это не справочник всего HealthKit.
- Garmin Connect описывает top-level поля из `summarizedActivitiesExport`, найденные в текущем Garmin export.

## Источники данных для справочника

### Apple Health

Источник правды для Apple Health на этом этапе:

- `SportApp/HealthKitTrainingActivitySource.swift`
- HealthKit SDK, доступный через Xcode в текущем проекте

Текущая интеграция запрашивает и использует:

- `HKObjectType.workoutType()`
- `HKQuantityTypeIdentifier.activeEnergyBurned`
- `HKQuantityTypeIdentifier.distanceWalkingRunning`
- `HKQuantityTypeIdentifier.distanceCycling`
- `HKQuantityTypeIdentifier.distanceSwimming`
- `HKMetadataKeySwimmingLocationType`
- `HKMetadataKeyLapLength`

### Garmin Connect

Источник правды для Garmin Connect на этом этапе:

- `from_garmin_official_export/DI_CONNECT/DI-Connect-Fitness/*_summarizedActivities.json`

По анализу текущего export:

- найден 1 файл `summarizedActivities`;
- найдено 377 активностей;
- найдено 12 типов активностей;
- найдено 132 top-level поля.

Типы активностей Garmin, найденные в export:

- `cycling`
- `elliptical`
- `indoor_cardio`
- `indoor_cycling`
- `lap_swimming`
- `meditation`
- `open_water_swimming`
- `other`
- `running`
- `stand_up_paddleboarding_v2`
- `strength_training`
- `walking`

## UI

### Точка входа

В верхней панели главного экрана рядом с иконкой настроек появляется новая иконка документации.

Требования:

- иконка должна быть визуально совместима с текущими `NeonIconButton`;
- рекомендуемый SF Symbol: `book.closed` или `questionmark.circle`;
- accessibility label: "Документация";
- нажатие открывает sheet "Документация".

### Экран документации

Экран документации строится как `NavigationStack`.

Первый экран:

- заголовок: "Документация";
- секция: "Связанные сервисы";
- две строки навигации:
  - "Apple Health";
  - "Garmin Connect".

Экран сервиса:

- заголовок сервиса;
- короткая вводная строка о том, что именно описывает раздел;
- список полей, сгруппированный по смысловым блокам;
- каждое поле раскрывается через `DisclosureGroup` или отдельную карточку.

### Карточка поля

Карточка поля содержит:

- системное имя: monospace-like визуально через стандартный SwiftUI `.font(.system(.caption, design: .monospaced))`;
- человекочитаемое имя;
- описание;
- chips/строки с поддерживаемыми типами тренировок.

Для длинных списков типов допускается компактное представление:

- "Все поддерживаемые типы";
- или первые несколько типов + счетчик, если поле поддерживает много типов.

## Модель данных документации

Будет создана статическая модель в коде приложения.

Ожидаемые сущности:

- `ConnectedServiceDocumentation`
- `ServiceDocumentationSection`
- `ServiceDocumentationField`
- `SupportedTrainingType`

Минимальные свойства поля:

- `systemName: String`
- `humanName: String`
- `description: String`
- `supportedTypes: [SupportedTrainingType]`

Справочник должен быть read-only.

## Apple Health: поля текущей интеграции

В Apple Health разделе должны быть описаны следующие поля.

| Системное имя | Русское имя | Типы тренировок | Описание |
|---|---|---|---|
| `HKWorkout.uuid` | ID тренировки Apple Health | Все тренировки Apple Health, импортированные приложением | Используется как стабильная ссылка на тренировку для дедупликации при повторной синхронизации. |
| `HKWorkout.workoutActivityType` | Тип тренировки | `cycling`, `running`, `walking`, `strength_training`, `elliptical`, `swimming`, `lap_swimming`, `open_water_swimming`, `other` | Определяет категорию тренировки, из которой приложение строит русское название и фильтры. |
| `HKWorkout.startDate` | Время начала | Все тренировки Apple Health, импортированные приложением | Используется для сортировки, фильтров периода, графика и дедупликации. |
| `HKWorkout.duration` | Длительность | Все тренировки Apple Health, импортированные приложением | Используется в карточках и в расчете усилия через калории в минуту. |
| `HKQuantityTypeIdentifier.activeEnergyBurned` | Активные калории | Все тренировки, для которых Apple Health отдает active energy | Используется в карточках и в расчете усилия. |
| `HKWorkout.totalDistance` / `distanceWalkingRunning` | Дистанция ходьбы или бега | `running`, `walking` | Используется как расстояние тренировки в метрах. |
| `HKWorkout.totalDistance` / `distanceCycling` | Дистанция велосипеда | `cycling` | Используется как расстояние тренировки в метрах. |
| `HKWorkout.totalDistance` / `distanceSwimming` | Дистанция плавания | `swimming`, `lap_swimming`, `open_water_swimming` | Используется как расстояние плавательной тренировки в метрах. |
| `HKMetadataKeySwimmingLocationType` | Тип места плавания | `lap_swimming`, `open_water_swimming` | Отличает бассейн от открытой воды, если Apple Health передает metadata. |
| `HKMetadataKeyLapLength` | Длина дорожки бассейна | `lap_swimming` | Используется как fallback-признак бассейна, когда Apple Health не передает `HKMetadataKeySwimmingLocationType`. |

## Garmin Connect: поля из summarizedActivities

В Garmin Connect разделе должны быть представлены все 132 top-level поля, найденные в `summarizedActivitiesExport`.

Для каждого поля приложение должно показать поддерживаемые типы тренировок на основании анализа export. В справочник попадают только имена полей, описания и типы активностей, но не значения.

### Идентификаторы и время

- `activityId`
- `uuidMsb`
- `uuidLsb`
- `userProfileId`
- `name`
- `activityType`
- `sportType`
- `eventTypeId`
- `rule`
- `timeZoneId`
- `beginTimestamp`
- `startTimeGmt`
- `startTimeLocal`

### Базовые длительности, дистанция и энергия

- `duration`
- `elapsedDuration`
- `movingDuration`
- `distance`
- `calories`
- `bmrCalories`

### Пульс, зоны и нагрузка

- `avgHr`
- `maxHr`
- `minHr`
- `hrTimeInZone_0`
- `hrTimeInZone_1`
- `hrTimeInZone_2`
- `hrTimeInZone_3`
- `hrTimeInZone_4`
- `hrTimeInZone_5`
- `hrTimeInZone_6`
- `activityTrainingLoad`
- `aerobicTrainingEffect`
- `anaerobicTrainingEffect`
- `aerobicTrainingEffectMessage`
- `anaerobicTrainingEffectMessage`
- `trainingEffectLabel`

### Скорость, темп, каденс и движение

- `avgSpeed`
- `maxSpeed`
- `avgFractionalCadence`
- `maxFractionalCadence`
- `avgRunCadence`
- `maxRunCadence`
- `avgDoubleCadence`
- `maxDoubleCadence`
- `avgBikeCadence`
- `maxBikeCadence`
- `avgStrideLength`
- `avgGradeAdjustedSpeed`
- `avgGroundContactTime`
- `avgVerticalOscillation`
- `avgVerticalRatio`
- `maxVerticalSpeed`

### Высота, координаты и место

- `elevationGain`
- `elevationLoss`
- `minElevation`
- `maxElevation`
- `startLatitude`
- `startLongitude`
- `endLatitude`
- `endLongitude`
- `maxLatitude`
- `maxLongitude`
- `minLatitude`
- `minLongitude`
- `locationName`
- `elevationCorrected`

### Плавание

- `activeLengths`
- `avgStrokes`
- `strokes`
- `avgStrokeDistance`
- `avgSwimCadence`
- `maxSwimCadence`
- `avgSwolf`
- `poolLength`

### SUP / гребковые активности

- `avgStrokeCadence`
- `maxStrokeCadence`

### Силовые тренировки

- `activeSets`
- `totalSets`
- `totalReps`
- `summarizedExerciseSets`
- `workoutId`

### Мощность и вело-/беговая power-аналитика

- `avgPower`
- `maxPower`
- `normPower`
- `max20MinPower`
- `trainingStressScore`
- `intensityFactor`
- `isRunPowerWindDataEnabled`
- `runPowerWindDataEnabled`
- `powerTimeInZone_0`
- `powerTimeInZone_1`
- `powerTimeInZone_2`
- `powerTimeInZone_3`
- `powerTimeInZone_4`
- `powerTimeInZone_5`
- `powerTimeInZone_6`
- `powerTimeInZone_7`

### Температура, вода, самочувствие и стресс

- `minTemperature`
- `maxTemperature`
- `waterEstimated`
- `workoutFeel`
- `workoutRpe`
- `differenceBodyBattery`
- `avgStress`
- `maxStress`
- `startStress`
- `endStress`
- `differenceStress`
- `avgRespirationRate`
- `maxRespirationRate`
- `minRespirationRate`

### Шаги, этажи, VO2 Max и интенсивность

- `steps`
- `floorsClimbed`
- `floorsDescended`
- `jumpCount`
- `surfaceInterval`
- `vO2MaxValue`
- `moderateIntensityMinutes`
- `vigorousIntensityMinutes`

### Флаги и служебные признаки

- `atpActivity`
- `autoCalcCalories`
- `decoDive`
- `favorite`
- `parent`
- `pr`
- `purposeful`
- `manufacturer`
- `deviceId`
- `lapCount`
- `summarizedDiveInfo`

### Разбиения и дополнительные структуры

- `splitSummaries`
- `splits`
- `description`

## Поддерживаемые типы тренировок в справочнике

Для человекочитаемого отображения типы тренировок должны использовать уже существующие русские названия там, где они есть:

- `cycling` -> "Велик"
- `indoor_cycling` -> "Велик"
- `running` -> "Бег"
- `walking` -> "Ходьба"
- `lap_swimming` -> "Бассейн"
- `open_water_swimming` -> "Плавание Море"
- `swimming` -> "Плавание"
- `strength_training` -> "Силовая"
- `elliptical` -> "Эллипс"
- `stand_up_paddleboarding_v2` -> "SUP"
- `indoor_cardio` -> "Кардио"
- `meditation` -> "Медитация"
- `other` -> "Другое"

## Тестирование

Минимальные тесты:

- каталог документации содержит два сервиса: Apple Health и Garmin Connect;
- Apple Health каталог содержит только поля текущей интеграции;
- Garmin Connect каталог содержит 132 поля;
- Garmin Connect каталог содержит все 12 типов активностей из export;
- поле `poolLength` поддерживает `lap_swimming`;
- поле `HKMetadataKeyLapLength` поддерживает `lap_swimming`;
- экран документации доступен по иконке из главного экрана.

## Не входит в эту итерацию

- поиск по документации;
- редактирование документации пользователем;
- локализация на другие языки;
- полный справочник всего HealthKit;
- чтение приватного Garmin export внутри приложения во время работы;
- добавление новых источников данных кроме Apple Health и Garmin Connect.

## Риски

- Garmin export может изменять набор полей в будущих выгрузках. В этой итерации справочник отражает текущий export и не пытается быть универсальной схемой Garmin.
- HealthKit содержит намного больше типов и полей, чем использует приложение. Документация Apple Health сознательно ограничена текущей интеграцией SportApp.
- Список из 132 Garmin-полей может быть длинным для iPhone. Поэтому поля нужно группировать и раскрывать постепенно, а не показывать одной плоской стеной текста.
