import SwiftUI

struct FetchDateRow: View {

    @ObservedObject var viewModel: FetchDateViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text(label(at: timeline.date))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func label(at date: Date) -> String {
        let secondsAgo = Int(abs(viewModel.referenceDate.timeIntervalSince(date)))
        return "Last fetched \(secondsAgo) seconds ago"
    }
}
