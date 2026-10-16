import Foundation

struct Article: Codable {
    let id: String
    let title: String
    let imageUrlString: String
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
}
