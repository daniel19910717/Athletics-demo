import Foundation

protocol ArticleLoading {
    func fetchArticles(scope: ArticleScope) async throws -> [Article]
    func fetchLeagues() async throws -> [League]
    func fetchAuthors() async throws -> [Author]
    func fetchTeams() async throws -> [Team]
}

final class AthleticNetworkModel: ArticleLoading {
    private let baseUrl = URL(string: "https://mobile-interview-backend.theathletic.com/")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchArticles(scope: ArticleScope) async throws -> [Article] {
        try await fetch(ArticleEndpoint.url(for: scope, base: baseUrl))
    }

    func fetchLeagues() async throws -> [League] {
        try await fetch(baseUrl.appendingPathComponent("leagues"))
    }

    func fetchAuthors() async throws -> [Author] {
        try await fetch(baseUrl.appendingPathComponent("authors"))
    }

    func fetchTeams() async throws -> [Team] {
        try await fetch(baseUrl.appendingPathComponent("teams"))
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
