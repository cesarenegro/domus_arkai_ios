//
//  HubMessage.swift
//  Domus Arkai
//

import Foundation

struct HubMessage: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    let title: String
    let body: String
    let status: HubStatus
    let sender: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case body
        case status
        case sender
    }
}

enum HubStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case read
    case completed
}

struct HubMessageDraft: Codable, Sendable {
    let sender: String
    let status: HubStatus
    let title: String
    let body: String

    init(title: String, body: String, sender: String = HubConfig.selfSender, status: HubStatus = .pending) {
        self.sender = sender
        self.status = status
        self.title = title
        self.body = body
    }
}
