@preconcurrency import HealthKit
import Foundation
import UIKit
import WhoopScopeDomain

@MainActor
final class HealthKitReader {
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.autoupdatingCurrent

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitReaderError.unavailable }
        let readTypes = Set(
            Self.quantityConfigurations.map { $0.quantityType as HKObjectType }
                + [Self.mindfulType]
        )

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, any Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitReaderError.authorizationDenied)
                }
            }
        }
    }

    func loadPayload(days: Int = 365) async throws -> HealthEnrichmentPayload {
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))!
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        var samples: [HealthMetricSample] = []

        for configuration in Self.quantityConfigurations {
            samples += try await loadDailyQuantity(
                configuration,
                startDate: startDate,
                endDate: endDate
            )
        }
        samples += try await loadMindfulMinutes(startDate: startDate, endDate: endDate)

        return HealthEnrichmentPayload(
            generatedAt: .now,
            deviceName: UIDevice.current.name,
            samples: samples.sorted {
                if $0.date == $1.date { return $0.kind.rawValue < $1.kind.rawValue }
                return $0.date < $1.date
            }
        )
    }

    private func loadDailyQuantity(
        _ configuration: QuantityConfiguration,
        startDate: Date,
        endDate: Date
    ) async throws -> [HealthMetricSample] {
        let calendar = calendar
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[HealthMetricSample], any Error>) in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            let query = HKStatisticsCollectionQuery(
                quantityType: configuration.quantityType,
                quantitySamplePredicate: predicate,
                options: configuration.option,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var result: [HealthMetricSample] = []
                collection?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let quantity: HKQuantity?
                    switch configuration.option {
                    case .cumulativeSum:
                        quantity = statistics.sumQuantity()
                    default:
                        quantity = statistics.averageQuantity()
                    }
                    guard let quantity else { return }
                    result.append(
                        HealthMetricSample(
                            kind: configuration.kind,
                            date: calendar.startOfDay(for: statistics.startDate),
                            value: quantity.doubleValue(for: configuration.healthUnit)
                                * configuration.valueScale,
                            unit: configuration.unitLabel,
                            source: "Apple Health"
                        )
                    )
                }
                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }

    private func loadMindfulMinutes(
        startDate: Date,
        endDate: Date
    ) async throws -> [HealthMetricSample] {
        let calendar = calendar
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[HealthMetricSample], any Error>) in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            let query = HKSampleQuery(
                sampleType: Self.mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let minutesByDay = (samples ?? []).reduce(into: [Date: Double]()) { result, sample in
                    let day = calendar.startOfDay(for: sample.startDate)
                    result[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 60
                }
                continuation.resume(
                    returning: minutesByDay.map { date, minutes in
                        HealthMetricSample(
                            kind: .mindfulMinutes,
                            date: date,
                            value: minutes,
                            unit: "min",
                            source: "Apple Health"
                        )
                    }
                )
            }
            healthStore.execute(query)
        }
    }
}

private extension HealthKitReader {
    struct QuantityConfiguration {
        let kind: HealthMetricKind
        let identifier: HKQuantityTypeIdentifier
        let option: HKStatisticsOptions
        let healthUnit: HKUnit
        let unitLabel: String
        var valueScale: Double = 1

        var quantityType: HKQuantityType {
            HKObjectType.quantityType(forIdentifier: identifier)!
        }
    }

    static let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

    static let quantityConfigurations: [QuantityConfiguration] = [
        .init(kind: .steps, identifier: .stepCount, option: .cumulativeSum, healthUnit: .count(), unitLabel: "count"),
        .init(kind: .walkingRunningDistance, identifier: .distanceWalkingRunning, option: .cumulativeSum, healthUnit: .meter(), unitLabel: "m"),
        .init(kind: .flightsClimbed, identifier: .flightsClimbed, option: .cumulativeSum, healthUnit: .count(), unitLabel: "count"),
        .init(kind: .exerciseMinutes, identifier: .appleExerciseTime, option: .cumulativeSum, healthUnit: .minute(), unitLabel: "min"),
        .init(kind: .standMinutes, identifier: .appleStandTime, option: .cumulativeSum, healthUnit: .minute(), unitLabel: "min"),
        .init(kind: .dietaryWater, identifier: .dietaryWater, option: .cumulativeSum, healthUnit: .literUnit(with: .milli), unitLabel: "mL"),
        .init(kind: .vo2Max, identifier: .vo2Max, option: .discreteAverage, healthUnit: HKUnit(from: "ml/kg*min"), unitLabel: "mL/kg/min"),
        .init(kind: .walkingSpeed, identifier: .walkingSpeed, option: .discreteAverage, healthUnit: .meter().unitDivided(by: .second()), unitLabel: "m/s"),
        .init(kind: .walkingStepLength, identifier: .walkingStepLength, option: .discreteAverage, healthUnit: .meter(), unitLabel: "m"),
        .init(kind: .walkingAsymmetry, identifier: .walkingAsymmetryPercentage, option: .discreteAverage, healthUnit: .percent(), unitLabel: "%", valueScale: 100),
        .init(kind: .walkingDoubleSupport, identifier: .walkingDoubleSupportPercentage, option: .discreteAverage, healthUnit: .percent(), unitLabel: "%", valueScale: 100),
        .init(kind: .bodyFatPercentage, identifier: .bodyFatPercentage, option: .discreteAverage, healthUnit: .percent(), unitLabel: "%", valueScale: 100),
        .init(kind: .leanBodyMass, identifier: .leanBodyMass, option: .discreteAverage, healthUnit: .gramUnit(with: .kilo), unitLabel: "kg"),
        .init(kind: .waistCircumference, identifier: .waistCircumference, option: .discreteAverage, healthUnit: .meter(), unitLabel: "m"),
    ]
}

enum HealthKitReaderError: LocalizedError {
    case unavailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Apple Health is unavailable on this device."
        case .authorizationDenied:
            "Apple Health access was not granted. You can review access in Settings."
        }
    }
}
