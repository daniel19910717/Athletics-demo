import XCTest
@testable import AthleticInterview

class ArticleViewModelTests: XCTestCase {

    private var subject: ArticleViewModel!
    private let article = Article(
        id: "1",
        title: "Test Article Title",
        imageUrlString: "https://theathletic.com/some-image.png",
        body: "Test article body.",
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: nil
    )

    override func setUp() {
        super.setUp()

        subject = ArticleViewModel(article: article)
    }

    func testInitialization() {
        XCTAssertEqual(subject.title, article.title)
        XCTAssertEqual(subject.imageUrl, URL(string: article.imageUrlString))
    }
}
