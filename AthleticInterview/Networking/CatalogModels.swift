import Foundation

struct League: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let title: String
}

struct Author: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortname: String
    let title: String
}

struct Team: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortname: String
    let league: EntityReference?
}
