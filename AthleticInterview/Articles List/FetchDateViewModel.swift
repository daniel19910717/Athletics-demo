import Combine
import SwiftUI

final class FetchDateViewModel: ObservableObject {
    var text: String

    private let fetchDate: Date
    private var timer: AnyCancellable?

    init(referenceDate: Date) {
        let secondsAgo = Int(abs(referenceDate.timeIntervalSinceNow))
        text = "Last fetched \(secondsAgo) seconds ago"
        fetchDate = referenceDate

        timer = Timer.publish(
            every: 1,
            on: .main,
            in: .default
        )
        .autoconnect()
        .sink { [weak self] date in
            let secondsAgo = Int(abs(referenceDate.timeIntervalSince(date)))
            self?.text = "Last fetched \(secondsAgo) seconds ago"
        }
    }
}
