import Foundation

final class AthleticNetworkModel {
    private let baseUrl = URL(string: "https://mobile-interview-backend.theathletic.com/")!

    func fetchArticles() async throws -> [Article] {
        try await fetch(request: URLRequest(url: baseUrl.appendingPathComponent("articles")))
    }

    private func fetch<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }
}
