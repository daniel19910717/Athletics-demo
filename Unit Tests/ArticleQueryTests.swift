import XCTest
@testable import AthleticInterview

final class ArticleQueryTests: XCTestCase {

    func testScopePrefersTeamThenLeagueThenAuthorThenFeed() {
        XCTAssertEqual(
            ArticleQuery(leagueId: "l", authorId: "a", teamId: "t").scope,
            .team("t")
        )
        XCTAssertEqual(
            ArticleQuery(leagueId: "l", authorId: "a", teamId: nil).scope,
            .league("l")
        )
        XCTAssertEqual(
            ArticleQuery(leagueId: nil, authorId: "a", teamId: nil).scope,
            .author("a")
        )
        XCTAssertEqual(
            ArticleQuery(leagueId: nil, authorId: nil, teamId: nil, searchText: "packers").scope,
            .feed
        )
    }

    func testMatchRequiresEveryActiveFilterAndTitle() {
        let article = makeArticle(
            id: "1",
            title: "Packers win in overtime",
            league: "l",
            author: "a",
            team: "t"
        )
        let query = ArticleQuery(
            leagueId: "l",
            authorId: "a",
            teamId: "t",
            searchText: "  packers  "
        )

        XCTAssertTrue(query.matches(article))
        XCTAssertFalse(ArticleQuery(leagueId: "other").matches(article))
        XCTAssertFalse(ArticleQuery(authorId: "other").matches(article))
        XCTAssertFalse(ArticleQuery(teamId: "other").matches(article))
        XCTAssertFalse(ArticleQuery(searchText: "lakers").matches(article))
    }

    func testDeletedArticlesAreExcluded() {
        let article = makeArticle(
            id: "1",
            title: "Removed",
            league: "l",
            author: "a",
            team: "t",
            deletedAt: Date()
        )

        XCTAssertFalse(ArticleQuery().matches(article))
    }

    func testEndpointPaths() {
        let base = URL(string: "https://mobile-interview-backend.theathletic.com/")!

        XCTAssertEqual(
            ArticleEndpoint.url(for: .feed, base: base).path,
            "/articles"
        )
        XCTAssertEqual(
            ArticleEndpoint.url(for: .league("league-id"), base: base).path,
            "/leagues/league-id/articles"
        )
        XCTAssertEqual(
            ArticleEndpoint.url(for: .team("team-id"), base: base).path,
            "/teams/team-id/articles"
        )
        XCTAssertEqual(
            ArticleEndpoint.url(for: .author("author-id"), base: base).path,
            "/authors/author-id/articles"
        )
    }
}

@MainActor
final class ArticlesViewModelTests: XCTestCase {

    private var loader: StubArticleLoader!
    private var viewModel: ArticlesViewModel!

    override func setUp() async throws {
        try await super.setUp()
        loader = StubArticleLoader()
        let matching = makeArticle(id: "1", title: "Packers win", league: "L", author: "A", team: "T")
        let sameTeamOtherAuthor = makeArticle(id: "2", title: "Other writer", league: "L", author: "B", team: "T")
        let sameLeagueOtherTeam = makeArticle(id: "3", title: "Other team", league: "L", author: "A", team: "U")
        let authorElsewhere = makeArticle(id: "4", title: "Author elsewhere", league: "M", author: "A", team: "V")
        let extra = makeArticle(id: "5", title: "Fifth story", league: "L", author: "A", team: "T")

        loader.articlesByScope[.team("T")] = [matching, sameTeamOtherAuthor, extra]
        loader.articlesByScope[.league("L")] = [matching, sameTeamOtherAuthor, sameLeagueOtherTeam, extra]
        loader.articlesByScope[.author("A")] = [matching, sameLeagueOtherTeam, authorElsewhere, extra]
        loader.articlesByScope[.feed] = [matching, sameTeamOtherAuthor, sameLeagueOtherTeam, authorElsewhere, extra]
        loader.articlesByScope[.league("OTHER")] = [
            makeArticle(id: "6", title: "Other league", league: "OTHER", author: "A", team: "V")
        ]
        loader.teams = [
            Team(id: "T", name: "Packers", shortname: "GB", league: EntityReference(id: "L")),
            Team(id: "U", name: "Bears", shortname: "CHI", league: EntityReference(id: "L"))
        ]
        loader.leagues = [
            League(id: "L", name: "NFL", shortName: "NFL", title: "NFL")
        ]
        loader.authors = [
            Author(id: "A", name: "Ada Writer", shortname: "A. Writer", title: "Staff")
        ]

        viewModel = ArticlesViewModel(loader: loader, pageSize: 2)
    }

    func testTeamScopeFiltersLeagueAndAuthorLocally() async {
        await viewModel.setTeam("T")
        await viewModel.setLeague("L")
        await viewModel.setAuthor("A")

        XCTAssertEqual(loader.requestedScopes, [.team("T")])
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["1", "5"])
        XCTAssertFalse(viewModel.canLoadMore)
    }

    func testRemovingAuthorKeepsTheTeamResponse() async {
        await viewModel.setTeam("T")
        await viewModel.setLeague("L")
        await viewModel.setAuthor("A")
        await viewModel.setAuthor(nil)

        XCTAssertEqual(loader.requestedScopes, [.team("T")])
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["1", "2"])
    }

    func testRemovingTeamFetchesTheLeagueAndFiltersTheAuthor() async {
        await viewModel.setTeam("T")
        await viewModel.setLeague("L")
        await viewModel.setAuthor("A")
        await viewModel.setTeam(nil)

        XCTAssertEqual(loader.requestedScopes, [.team("T"), .league("L")])
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["1", "3"])
    }

    func testAuthorOnlyUsesTheAuthorEndpoint() async {
        await viewModel.setAuthor("A")

        XCTAssertEqual(loader.requestedScopes, [.author("A")])
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["1", "3"])
    }

    func testSearchFiltersLoadedTitlesWithoutAnotherRequest() async {
        await viewModel.loadIfNeeded()
        let requestsBeforeSearch = loader.requestedScopes

        viewModel.applySearch("packers")

        XCTAssertEqual(loader.requestedScopes, requestsBeforeSearch)
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["1"])
        XCTAssertFalse(viewModel.canLoadMore)
    }

    func testVisibleArticlesGrowByPage() async {
        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.articleModels.count, 2)
        XCTAssertTrue(viewModel.canLoadMore)

        viewModel.loadNextPage()
        XCTAssertEqual(viewModel.articleModels.count, 4)

        viewModel.loadNextPage()
        XCTAssertEqual(viewModel.articleModels.count, 5)
        XCTAssertFalse(viewModel.canLoadMore)
        XCTAssertEqual(loader.requestedScopes, [.feed])
    }

    func testSelectingAnotherLeagueClearsAnIncompatibleTeam() async {
        await viewModel.loadIfNeeded()
        await viewModel.setTeam("T")
        await viewModel.setLeague("OTHER")

        XCTAssertNil(viewModel.selectedTeamId)
        XCTAssertEqual(viewModel.selectedLeagueId, "OTHER")
        XCTAssertEqual(loader.requestedScopes.last, .league("OTHER"))
        XCTAssertEqual(viewModel.articleModels.map(\.id), ["6"])
    }
}

private final class StubArticleLoader: ArticleLoading {
    var articlesByScope: [ArticleScope: [Article]] = [:]
    private(set) var requestedScopes: [ArticleScope] = []
    var leagues: [League] = []
    var authors: [Author] = []
    var teams: [Team] = []

    func fetchArticles(scope: ArticleScope) async throws -> [Article] {
        requestedScopes.append(scope)
        return articlesByScope[scope] ?? []
    }

    func fetchLeagues() async throws -> [League] { leagues }
    func fetchAuthors() async throws -> [Author] { authors }
    func fetchTeams() async throws -> [Team] { teams }
}

private func makeArticle(
    id: String,
    title: String,
    league: String,
    author: String,
    team: String,
    deletedAt: Date? = nil
) -> Article {
    Article(
        id: id,
        title: title,
        imageUrlString: "https://example.com/\(id).jpg",
        body: "Body \(id)",
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: deletedAt,
        author: EntityReference(id: author),
        league: EntityReference(id: league),
        team: EntityReference(id: team)
    )
}
