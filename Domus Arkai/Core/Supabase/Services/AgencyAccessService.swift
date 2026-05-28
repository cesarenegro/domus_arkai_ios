//
//  AgencyAccessService.swift
//  Domus Arkai
//
//  Gating "Modalità professionale" v2.0: chiamata RPC a Supabase per leggere
//  il ruolo dell'utente loggato. Funzione DDL (SECURITY DEFINER):
//
//      CREATE OR REPLACE FUNCTION public.get_current_user_role()
//      RETURNS text AS $$
//        SELECT role FROM public.agency_users
//        WHERE user_id = auth.uid()
//        LIMIT 1;
//      $$ LANGUAGE sql SECURITY DEFINER;
//
//  Ref HUB msg 64cdbf3e (Marco, 2026-05-27).
//

import Foundation
import Supabase

actor AgencyAccessService {
    static let shared = AgencyAccessService()

    private var client: SupabaseClient { SupabaseManager.shared }

    /// UID founder (Cesare) — bypass DEBUG per accesso totale alle feature v2.0
    /// finché non viene completata l'auth email/password con account admin reali
    /// creati lato Supabase. NON compilato in Release.
    #if DEBUG
    private static let founderUserID = "70297656-81a0-421a-836a-40f953cbc96b"
    #endif

    /// Recupera il ruolo dell'utente loggato chiamando la RPC server-side.
    /// Ritorna `nil` se utente è B2C (non in `agency_users`) o se non autenticato.
    func fetchMyRole() async -> AgencyRole? {
        print("🟢 [AgencyAccess][Service] fetch role")

        #if DEBUG
        // Bypass DEBUG founder: garantisce accesso super_admin a Cesare.
        if let uid = await AuthService.shared.currentUser?.id.uuidString.lowercased(),
           uid == Self.founderUserID {
            print("🟢 [AgencyAccess][Service] DEBUG bypass → role=super_admin (founder uid)")
            return .superAdmin
        }
        #endif

        do {
            // La function torna `text` opzionale. Postgres rende come stringa quotata.
            let role: String? = try await client
                .rpc("get_current_user_role")
                .execute()
                .value
            guard let raw = role, let mapped = AgencyRole(rawValue: raw) else {
                print("🟡 [AgencyAccess][Service] no role / B2C user (raw=\(role ?? "nil"))")
                return nil
            }
            print("✅ [AgencyAccess][Service] role=\(mapped.rawValue)")
            return mapped
        } catch {
            // Una RPC che fallisce (es. utente non loggato) → trattata come B2C.
            print("🔴 [AgencyAccess][Service] RPC failed — \(error.localizedDescription) — treating as B2C")
            return nil
        }
    }

    /// Recupera l'agency_id dell'utente loggato via RPC server-side
    /// `public.get_current_user_agency_id()`. Per super_admin senza agenzia
    /// ritorna `nil`.
    func fetchMyAgencyID() async -> UUID? {
        print("🟢 [AgencyAccess][Service] fetch agency_id")
        do {
            let agencyIDString: String? = try await client
                .rpc("get_current_user_agency_id")
                .execute()
                .value
            guard let raw = agencyIDString, let uuid = UUID(uuidString: raw) else {
                print("🟡 [AgencyAccess][Service] no agency_id (super_admin or unauth)")
                return nil
            }
            print("✅ [AgencyAccess][Service] agency_id=\(uuid)")
            return uuid
        } catch {
            print("🔴 [AgencyAccess][Service] agency_id RPC failed — \(error.localizedDescription)")
            return nil
        }
    }
}
