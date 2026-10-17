import Foundation

/// Which collection the API can return for a filter combination.
///
/// Team is a subset of its league, so a selected team always wins.
/// League wins over author. Author is only the request when it is the
/// only scope. With no scope, `/articles` is the capped home feed.
enum ArticleScope: Hashable {
    case feed
    case league(String)
    case team(String)
    case author(String)
}

struct ArticleQuery: Equatable {
    var leagueId: String?
    var authorId: String?
    var teamId: String?
    var searchText: String = ""

    var scope: ArticleScope {
        if let teamId {
            return .team(teamId)
        }
        if let leagueId {
            return .league(leagueId)
        }
        if let authorId {
            return .author(authorId)
        }
        return .feed
    }

    func matches(_ article: Article) -> Bool {
        if article.deletedAt != nil {
            return false
        }
        if let leagueId, article.league?.id != leagueId {
            return false
        }
        if let authorId, article.author?.id != authorId {
            return false
        }
        if let teamId, article.team?.id != teamId {
            return false
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearch.isEmpty {
            return true
        }
        return article.title.localizedStandardContains(trimmedSearch)
    }
}

enum ArticleEndpoint {
    static func url(for scope: ArticleScope, base: URL) -> URL {
        let components: [String]
        switch scope {
        case .feed:
            components = ["articles"]
        case .league(let id):
            components = ["leagues", id, "articles"]
        case .team(let id):
            components = ["teams", id, "articles"]
        case .author(let id):
            components = ["authors", id, "articles"]
        }

        return components.reduce(base) { partial, component in
            partial.appendingPathComponent(component)
        }
    }
}
