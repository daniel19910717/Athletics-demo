import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ArticlesList(viewModel: ArticlesViewModel())
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
