import Foundation

public struct TrendMetricSummary: Equatable, Sendable {
    public let currentAverage: Double?
    public let previousAverage: Double?
    public let currentSampleCount: Int
    public let previousSampleCount: Int

    public init(
        currentAverage: Double?,
        previousAverage: Double?,
        currentSampleCount: Int,
        previousSampleCount: Int
    ) {
        self.currentAverage = currentAverage
        self.previousAverage = previousAverage
        self.currentSampleCount = currentSampleCount
        self.previousSampleCount = previousSampleCount
    }

    public var change: Double? {
        guard let currentAverage, let previousAverage else { return nil }
        return currentAverage - previousAverage
    }
}
