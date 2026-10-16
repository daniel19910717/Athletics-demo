import Foundation

struct ArticleViewModel: Identifiable {

    let id: String
    let title: String
    let imageUrl: URL?
    
    init(article: Article) {
        id = article.id
        title = article.title
        imageUrl = URL(string: article.imageUrlString)
    }
}
