# Общие поля Garmin-активностей

Этот документ оставляет только поля, которые присутствуют во всех видах активностей внутри Garmin-отчета `summarizedActivitiesExport`.

Проверенные виды активностей:

```text
cycling
elliptical
indoor_cardio
indoor_cycling
lap_swimming
meditation
open_water_swimming
other
running
stand_up_paddleboarding_v2
strength_training
walking
```

Важно: `calories`, `bmrCalories`, `distance`, `avgHr` и `activityTrainingLoad` не попали в таблицу общих полей, потому что они отсутствуют у `meditation`. У всех остальных видов активностей из списка эти поля есть.

## Общие поля

| Поле в Garmin-отчете | Проверенные отчеты | Человекочитаемое название |
|---|---|---|
| `activityId` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | ID активности |
| `activityType` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Тип активности |
| `atpActivity` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак активности из тренировочного плана |
| `autoCalcCalories` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак автоматического расчета калорий |
| `avgFractionalCadence` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Средняя дробная частота движения |
| `beginTimestamp` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Время начала активности |
| `decoDive` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак декомпрессионного погружения |
| `deviceId` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | ID устройства |
| `duration` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Длительность тренировки |
| `elapsedDuration` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Полная прошедшая длительность |
| `elevationCorrected` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак коррекции высоты |
| `eventTypeId` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | ID типа события |
| `favorite` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Добавлено в избранное |
| `lapCount` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Количество кругов/отрезков |
| `manufacturer` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Производитель устройства |
| `maxFractionalCadence` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Максимальная дробная частота движения |
| `name` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Название активности |
| `parent` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак родительской активности |
| `pr` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак личного рекорда |
| `purposeful` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Признак целевой активности |
| `rule` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Правило видимости активности |
| `startTimeGmt` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Время старта в GMT |
| `startTimeLocal` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Локальное время старта |
| `summarizedDiveInfo` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Сводная информация о погружении |
| `timeZoneId` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | ID часового пояса |
| `userProfileId` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | ID профиля пользователя |
| `uuidMsb`, `uuidLsb` | Сводка активностей Garmin Connect; проверены все 12 видов активностей | Части UUID активности |

## Обработанные типы отчетов

| Тип отчета Garmin | Пример |
|---|---|
| Сводка активностей Garmin Connect | `summarizedActivities.json` |
| Дневные wellness-агрегаты | `UDSFile_2025-05-04_2025-08-12.json` |
| Журнал гидратации | `HydrationLogFile_2025-05-01_2025-08-09.json` |
| История тренировочного статуса | `TrainingHistory_20250306_20250614_134226867.json` |
| Острая тренировочная нагрузка | `MetricsAcuteTrainingLoad_20250306_20250614_134226867.json` |
| Акклиматизация к жаре и высоте | `MetricsHeatAltitudeAcclimation_20250306_20250614_134226867.json` |
| VO2 Max / Max MET | `MetricsMaxMetData_20250306_20250614_134226867.json` |
| Прогнозы беговых дистанций | `RunRacePredictions_20250306_20250614_134226867.json` |
| Endurance Score | `EnduranceScore_20250306_20250614_134226867.json` |
| Hill Score | `HillScore_20250306_20250614_134226867.json` |
| Training Readiness | `TrainingReadinessDTO_20250614_20250922_134226867.json` |
| Резервные копии устройств | `DeviceBackups.json` |
| Снаряжение | `gear.json` |
| Личные рекорды | `personalRecord.json` |
| Тренировочные планы | `trainingPlan.json` |
| Тренировки/воркауты | `workout.json` |
| Социальные комментарии | `comments.json` |
| Социальные лайки | `likes.json` |
| Цели пользователя | `UserGoal_2025-03-06_2025-06-14.json` |
| Социальный профиль | `social-profile.json` |
| Профиль пользователя | `user_profile.json` |
| Профиль Suica | `user_profile_suica.json` |
| Напоминания пользователя | `user_reminders.json` |
| Настройки пользователя | `user_settings.json` |
| Биометрика пользователя | `userBioMetrics.json` |
| Профиль биометрических данных | `userBioMetricProfileData.json` |
| Зоны пульса | `heartRateZones.json` |
| Зоны мощности | `powerZones.json` |
| Fitness Age | `fitnessAgeData.json` |
| Последние биометрики | `bioMetrics_latest.json` |
| Сон | `sleepData.json` |
| Golf clubs | `Golf-CLUB.json` |
| Golf club types | `Golf-CLUB_TYPES.json` |
| Пользователь Connect IQ | `user.json` |
| История согласий | `consentHistory.json` |
| Устройства и контент | `devicesandcontent.json` |
| Глобальные события | `events.json` |
| Заказы | `orders.json` |
| Customer data | `customer.json` |
| Архив загруженных FIT-файлов | `UploadedFiles_0-_Part1.zip` |
| Архив основной тренировочной резервной копии | `PrimaryTrainingBackup_Part1.zip` |
| Архив LHA backup | `LhaBackup_Part1.zip` |
| Архив резервных копий устройств | `device-backups-files_Part1.zip` |
