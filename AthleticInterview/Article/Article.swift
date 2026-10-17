import Foundation

struct EntityReference: Codable, Hashable {
    let id: String
}

struct Article: Codable, Identifiable {
    let id: String
    let title: String
    let imageUrlString: String
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let author: EntityReference?
    let league: EntityReference?
    let team: EntityReference?
}
