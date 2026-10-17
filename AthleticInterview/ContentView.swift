import SwiftUI

struct ContentView: View {
    @StateObject private var articlesViewModel = ArticlesViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                ArticlesList(viewModel: articlesViewModel)
            }
            .tabItem {
                Label("Articles", systemImage: "list.bullet")
            }
        }
    }
}

#Preview {
    ContentView()
}
