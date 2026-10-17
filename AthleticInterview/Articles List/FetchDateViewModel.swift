import Combine
import Foundation

final class FetchDateViewModel: ObservableObject {
    let referenceDate: Date

    var text: String {
        let secondsAgo = Int(abs(referenceDate.timeIntervalSinceNow))
        return "Last fetched \(secondsAgo) seconds ago"
    }

    init(referenceDate: Date) {
        self.referenceDate = referenceDate
    }
}
