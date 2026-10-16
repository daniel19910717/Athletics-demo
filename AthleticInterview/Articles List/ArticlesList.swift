import SwiftUI

struct ArticlesList: View {
    @StateObject private var viewModel: ArticlesViewModel
    
    init(viewModel: ArticlesViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            if let fetchDateViewModel = viewModel.fetchDateViewModel {
                FetchDateRow(viewModel: fetchDateViewModel)
            }

            ForEach(viewModel.articleModels) { model in
                ArticleRow(viewModel: model)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(
                .init(top: 0, leading: 0, bottom: 8, trailing: 0)
            )
        }
        .listStyle(.plain)
        .onAppear {
            Task {
                try await viewModel.fetchArticles()
            }
        }
        .navigationTitle("Articles")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottomTrailing) {
            ReturnToTopButton()
                .padding([.bottom, .trailing], 16)
        }
    }
}

#Preview {
    ArticlesList(viewModel: ArticlesViewModel())
}
