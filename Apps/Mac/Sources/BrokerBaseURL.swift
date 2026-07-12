import Foundation

enum BrokerBaseURL {
    static let value: URL = {
        guard
            let value = Bundle.main.object(
                forInfoDictionaryKey: "WHOOPSCOPE_BROKER_URL"
            ) as? String,
            let url = URL(string: value)
        else {
            fatalError("WHOOPSCOPE_BROKER_URL is missing from Info.plist")
        }
        return url
    }()
}

