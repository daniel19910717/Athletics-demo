import UIKit

@MainActor
final class ArticlesViewModel: ObservableObject {
    
    var fetchDateViewModel: FetchDateViewModel?

    @Published private(set) var articleModels: [ArticleViewModel] = []
    private let network = AthleticNetworkModel()

    func fetchArticles() async throws {
        articleModels = try await network.fetchArticles().map(ArticleViewModel.init)
        fetchDateViewModel = FetchDateViewModel(referenceDate: Date())
    }
}
