import Combine
import Foundation

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published private(set) var articleModels: [ArticleViewModel] = []
    @Published private(set) var leagues: [League] = []
    @Published private(set) var authors: [Author] = []
    @Published private(set) var teams: [Team] = []
    @Published private(set) var selectedLeagueId: String?
    @Published private(set) var selectedAuthorId: String?
    @Published private(set) var selectedTeamId: String?
    @Published private(set) var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isCatalogLoaded = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var canLoadMore = false
    @Published private(set) var fetchDateViewModel: FetchDateViewModel?

    private let loader: any ArticleLoading
    private let pageSize: Int
    private var cache: [ArticleScope: [Article]] = [:]
    private var fetchedAt: [ArticleScope: Date] = [:]
    private var filteredArticles: [Article] = []
    private var visibleCount = 0
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?
    private var filtersTask: Task<Void, Never>?

    init(loader: any ArticleLoading = AthleticNetworkModel(), pageSize: Int = 30) {
        self.loader = loader
        self.pageSize = pageSize
    }

    var hasActiveFilters: Bool {
        selectedLeagueId != nil || selectedAuthorId != nil || selectedTeamId != nil
    }

    var leagueChipTitle: String {
        leagues.first { $0.id == selectedLeagueId }?.shortName ?? "League"
    }

    var authorChipTitle: String {
        authors.first { $0.id == selectedAuthorId }?.shortname ?? "Author"
    }

    var teamChipTitle: String {
        teams.first { $0.id == selectedTeamId }?.shortname ?? "Team"
    }

    var teamsForPicker: [Team] {
        guard let selectedLeagueId else { return teams }
        return teams.filter { $0.league?.id == selectedLeagueId }
    }

    var teamPickerNote: String? {
        guard let selectedLeagueId,
              let name = leagues.first(where: { $0.id == selectedLeagueId })?.name
        else { return nil }
        return "Showing teams in \(name)"
    }

    var emptyMessage: String {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return "No titles match “\(trimmed)” in the loaded articles."
        }
        if hasActiveFilters {
            return "Nothing matches these filters."
        }
        return "There are no articles to show."
    }

    func loadIfNeeded() async {
        async let filters: Void = loadFiltersIfNeeded()
        if cache[currentQuery.scope] == nil {
            await reload()
        }
        await filters
    }

    func setLeague(_ id: String?) async {
        let previousLeague = selectedLeagueId
        let previousTeam = selectedTeamId
        selectedLeagueId = id
        reconcileTeamWithLeague()
        guard previousLeague != selectedLeagueId || previousTeam != selectedTeamId else { return }
        await reload()
    }

    func setAuthor(_ id: String?) async {
        guard selectedAuthorId != id else { return }
        selectedAuthorId = id
        await reload()
    }

    func setTeam(_ id: String?) async {
        guard selectedTeamId != id else { return }
        selectedTeamId = id
        await reload()
    }

    func clearFilters() async {
        guard hasActiveFilters else { return }
        selectedLeagueId = nil
        selectedAuthorId = nil
        selectedTeamId = nil
        await reload()
    }

    func retry() async {
        await reload()
    }

    func applySearch(_ text: String) {
        searchText = text
        let query = currentQuery
        guard let articles = cache[query.scope] else { return }
        publish(articles, scope: query.scope, query: query, updateFetchDate: false)
    }

    func loadNextPage() {
        guard visibleCount < filteredArticles.count else {
            canLoadMore = false
            return
        }

        let newCount = min(visibleCount + pageSize, filteredArticles.count)
        let next = filteredArticles[visibleCount..<newCount].map(ArticleViewModel.init)
        visibleCount = newCount
        articleModels.append(contentsOf: next)
        canLoadMore = visibleCount < filteredArticles.count
    }

    private var currentQuery: ArticleQuery {
        ArticleQuery(
            leagueId: selectedLeagueId,
            authorId: selectedAuthorId,
            teamId: selectedTeamId,
            searchText: searchText
        )
    }

    private func reload() async {
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        let query = currentQuery
        let scope = query.scope

        if let cached = cache[scope] {
            publish(cached, scope: scope, query: query, updateFetchDate: true)
            return
        }

        articleModels = []
        filteredArticles = []
        visibleCount = 0
        canLoadMore = false
        isLoading = true
        errorMessage = nil

        let task = Task { await self.performNetworkLoad(scope: scope, generation: generation) }
        loadTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func performNetworkLoad(scope: ArticleScope, generation: Int) async {
        do {
            let articles = try await loader.fetchArticles(scope: scope)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            cache[scope] = articles
            fetchedAt[scope] = Date()
            let query = currentQuery
            guard query.scope == scope else { return }
            publish(articles, scope: scope, query: query, updateFetchDate: true)
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            isLoading = false
            errorMessage = "Check your connection and try again."
        }
    }

    private func publish(
        _ articles: [Article],
        scope: ArticleScope,
        query: ArticleQuery,
        updateFetchDate: Bool
    ) {
        filteredArticles = articles.filter(query.matches)
        visibleCount = min(pageSize, filteredArticles.count)
        articleModels = filteredArticles.prefix(visibleCount).map(ArticleViewModel.init)
        canLoadMore = visibleCount < filteredArticles.count
        isLoading = false
        errorMessage = nil
        if updateFetchDate, let date = fetchedAt[scope] {
            fetchDateViewModel = FetchDateViewModel(referenceDate: date)
        }
    }

    private func reconcileTeamWithLeague() {
        guard let selectedTeamId, let selectedLeagueId else { return }
        guard let team = teams.first(where: { $0.id == selectedTeamId }) else { return }
        if team.league?.id != selectedLeagueId {
            self.selectedTeamId = nil
        }
    }

    private func loadFiltersIfNeeded() async {
        if filtersTask == nil {
            filtersTask = Task { await self.fetchCatalog() }
        }
        await filtersTask?.value
    }

    private func fetchCatalog() async {
        let leaguesTask = Task { try? await self.loader.fetchLeagues() }
        let authorsTask = Task { try? await self.loader.fetchAuthors() }
        let teamsTask = Task { try? await self.loader.fetchTeams() }
        let loadedLeagues = await leaguesTask.value
        let loadedAuthors = await authorsTask.value
        let loadedTeams = await teamsTask.value

        if let loadedLeagues {
            leagues = loadedLeagues.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        if let loadedAuthors {
            authors = loadedAuthors.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        if let loadedTeams {
            teams = loadedTeams.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        isCatalogLoaded = true
    }
}
