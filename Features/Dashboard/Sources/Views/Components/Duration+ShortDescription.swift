import Foundation

extension Duration {
    var shortDescription: String {
        let totalSeconds = components.seconds
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        return "\(hours)h \(minutes)m"
    }

    var workoutDescription: String {
        let totalMinutes = max(components.seconds / 60, 1)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) min"
        }
        if minutes == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(minutes) min"
    }
}
