//
//  Lead.swift
//  Domus Arkai
//

import Foundation

struct Lead: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let agencyID: UUID
    let propertyID: UUID?
    let name: String
    let email: String?
    let phone: String?
    let message: String?
    let source: Source
    let status: Status
    let createdAt: Date

    enum Source: String, Codable, Hashable, Sendable {
        case visitRequest = "visit_request"
        case mortgageCalculator = "mortgage_calculator"
        case renovationEstimate = "renovation_estimate"
        case contactForm = "contact_form"
        case whatsappClick = "whatsapp_click"
        case phoneClick = "phone_click"
        case favorite
    }

    enum Status: String, Codable, Hashable, Sendable {
        case new, contacted, visitScheduled = "visit_scheduled"
        case qualified, lost, converted
    }
}

struct VisitRequest: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let agencyID: UUID
    let propertyID: UUID
    let leadID: UUID
    let preferredDate: Date
    let preferredTimeSlot: TimeSlot
    let notes: String?
    let status: Status
    let createdAt: Date

    enum TimeSlot: String, Codable, Hashable, Sendable, CaseIterable {
        case morning, afternoon, evening

        var label: String {
            switch self {
            case .morning: "Mattina (9:00 — 12:30)"
            case .afternoon: "Pomeriggio (14:00 — 18:00)"
            case .evening: "Sera (18:00 — 20:00)"
            }
        }
    }

    enum Status: String, Codable, Hashable, Sendable {
        case new, confirmed, rescheduled, cancelled, completed
    }
}
