import SwiftUI

struct ArticlesList: View {
    @StateObject private var viewModel: ArticlesViewModel
    @State private var selectedArticle: ArticleViewModel?
    @State private var activeFilter: ArticleFilterKind?
    @State private var searchText = ""

    init(viewModel: ArticlesViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ArticleFilterBar(
                        leagueTitle: viewModel.leagueChipTitle,
                        authorTitle: viewModel.authorChipTitle,
                        teamTitle: viewModel.teamChipTitle,
                        leagueActive: viewModel.selectedLeagueId != nil,
                        authorActive: viewModel.selectedAuthorId != nil,
                        teamActive: viewModel.selectedTeamId != nil,
                        showsReset: viewModel.hasActiveFilters,
                        onLeague: { activeFilter = .league },
                        onAuthor: { activeFilter = .author },
                        onTeam: { activeFilter = .team },
                        onReset: { Task { await viewModel.clearFilters() } }
                    )
                    Divider()
                }
            }
            .navigationTitle("Articles")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedArticle) { model in
                ArticleDetailView(viewModel: model)
            }
            .searchable(text: $searchText, prompt: "Search titles")
            .task(id: searchText) {
                await debounceSearch()
            }
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: $activeFilter) { kind in
                FilterPickerView(
                    title: kind.title,
                    note: kind == .team ? viewModel.teamPickerNote : nil,
                    options: options(for: kind),
                    selection: selection(for: kind),
                    isLoaded: viewModel.isCatalogLoaded,
                    onSelect: { id in
                        Task { await select(id, for: kind) }
                    }
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage, viewModel.articleModels.isEmpty, !viewModel.isLoading {
            ContentUnavailableView {
                Label("Couldn't Load Articles", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.isLoading && viewModel.articleModels.isEmpty {
            ProgressView("Loading articles")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.articleModels.isEmpty {
            ContentUnavailableView(
                "No Articles",
                systemImage: "newspaper",
                description: Text(viewModel.emptyMessage)
            )
        } else {
            articleList
        }
    }

    private var articleList: some View {
        ScrollViewReader { proxy in
            List {
                if let fetchDateViewModel = viewModel.fetchDateViewModel {
                    FetchDateRow(viewModel: fetchDateViewModel)
                        .id(Self.topID)
                }

                ForEach(viewModel.articleModels) { model in
                    Button {
                        selectedArticle = model
                    } label: {
                        ArticleRow(viewModel: model)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(model.title)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                }

                if viewModel.canLoadMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowSeparator(.hidden)
                        .id(viewModel.articleModels.count)
                        .onAppear { viewModel.loadNextPage() }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .overlay(alignment: .bottomTrailing) {
                ReturnToTopButton {
                    withAnimation {
                        proxy.scrollTo(Self.topID, anchor: .top)
                    }
                }
                .padding([.bottom, .trailing], 16)
            }
        }
    }

    private func options(for kind: ArticleFilterKind) -> [FilterOption] {
        switch kind {
        case .league:
            viewModel.leagues.map {
                FilterOption(id: $0.id, title: $0.name, subtitle: $0.shortName)
            }
        case .author:
            viewModel.authors.map {
                FilterOption(
                    id: $0.id,
                    title: $0.name,
                    subtitle: $0.title.isEmpty ? nil : $0.title
                )
            }
        case .team:
            viewModel.teamsForPicker.map {
                FilterOption(id: $0.id, title: $0.name, subtitle: $0.shortname)
            }
        }
    }

    private func selection(for kind: ArticleFilterKind) -> String? {
        switch kind {
        case .league: viewModel.selectedLeagueId
        case .author: viewModel.selectedAuthorId
        case .team: viewModel.selectedTeamId
        }
    }

    private func select(_ id: String?, for kind: ArticleFilterKind) async {
        switch kind {
        case .league: await viewModel.setLeague(id)
        case .author: await viewModel.setAuthor(id)
        case .team: await viewModel.setTeam(id)
        }
    }

    private func debounceSearch() async {
        if searchText == viewModel.searchText { return }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        viewModel.applySearch(searchText)
    }

    private static let topID = "articles-top"
}

#Preview {
    NavigationStack {
        ArticlesList(viewModel: ArticlesViewModel())
    }
}
