import Foundation

struct ArticleViewModel: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let imageUrl: URL?

    init(article: Article) {
        id = article.id
        title = article.title
        body = article.body
        imageUrl = URL(string: article.imageUrlString)
    }

    static func == (lhs: ArticleViewModel, rhs: ArticleViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
