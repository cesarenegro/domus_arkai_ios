//
//  HubService.swift
//  Domus Arkai
//

import Foundation

enum HubServiceError: Error, LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Risposta non valida dal server Supabase."
        case .http(let status, let body):
            return "HTTP \(status): \(body)"
        case .decoding(let error):
            return "Errore di decoding: \(error.localizedDescription)"
        }
    }
}

actor HubService {
    static let shared = HubService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = iso.date(from: raw) ?? isoNoFrac.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Formato data non riconosciuto: \(raw)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func fetchPendingFromPeer(limit: Int = 50) async throws -> [HubMessage] {
        var components = URLComponents(
            url: SupabaseConfig.restURL.appendingPathComponent(HubConfig.coordinationTable),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "sender", value: "eq.\(HubConfig.peerSender)"),
            URLQueryItem(name: "status", value: "eq.\(HubStatus.pending.rawValue)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        return try await perform(request: makeRequest(url: components.url!, method: "GET"))
    }

    func fetchRecent(limit: Int = 50) async throws -> [HubMessage] {
        var components = URLComponents(
            url: SupabaseConfig.restURL.appendingPathComponent(HubConfig.coordinationTable),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        return try await perform(request: makeRequest(url: components.url!, method: "GET"))
    }

    @discardableResult
    func markCompleted(id: UUID) async throws -> HubMessage {
        try await patch(id: id, payload: ["status": HubStatus.completed.rawValue])
    }

    @discardableResult
    func updateStatus(id: UUID, status: HubStatus) async throws -> HubMessage {
        try await patch(id: id, payload: ["status": status.rawValue])
    }

    @discardableResult
    func send(_ draft: HubMessageDraft) async throws -> HubMessage {
        let url = SupabaseConfig.restURL.appendingPathComponent(HubConfig.coordinationTable)
        var request = makeRequest(url: url, method: "POST")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(draft)
        let messages: [HubMessage] = try await perform(request: request)
        guard let first = messages.first else {
            throw HubServiceError.invalidResponse
        }
        return first
    }

    private func patch(id: UUID, payload: [String: String]) async throws -> HubMessage {
        var components = URLComponents(
            url: SupabaseConfig.restURL.appendingPathComponent(HubConfig.coordinationTable),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(id.uuidString.lowercased())")]
        var request = makeRequest(url: components.url!, method: "PATCH")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let messages: [HubMessage] = try await perform(request: request)
        guard let first = messages.first else {
            throw HubServiceError.invalidResponse
        }
        return first
    }

    private func makeRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HubServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HubServiceError.http(status: http.statusCode, body: body)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HubServiceError.decoding(error)
        }
    }
}
