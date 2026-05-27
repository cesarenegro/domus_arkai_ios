//
//  AgencyRole.swift
//  Domus Arkai
//
//  Ruolo dell'utente loggato rispetto alla piattaforma multi-agency.
//  Restituito da `public.get_current_user_role()` (RPC Supabase, SECURITY DEFINER).
//
//  Schema confermato da Marco (HUB msg 64cdbf3e, 2026-05-27):
//  - 'super_admin'   → amministratore piattaforma Arkai
//  - 'agency_admin'  → amministratore dell'agenzia affiliata
//  - 'agent'         → agente immobiliare standard
//  - 'viewer'        → ruolo read-only nell'agenzia
//  - NULL            → utente consumer B2C (non in `agency_users`)
//

import Foundation

enum AgencyRole: String, Codable, Sendable, CaseIterable {
    case superAdmin = "super_admin"
    case agencyAdmin = "agency_admin"
    case agent
    case viewer

    /// True se l'utente può scansionare immobili (modalità professionale visibile).
    /// `viewer` esplicitamente escluso (può solo consultare, non creare scansioni).
    var canScanProperties: Bool {
        switch self {
        case .superAdmin, .agencyAdmin, .agent: true
        case .viewer: false
        }
    }

    var displayName: String {
        switch self {
        case .superAdmin: "Super Admin"
        case .agencyAdmin: "Admin agenzia"
        case .agent: "Agente"
        case .viewer: "Consultazione"
        }
    }
}
