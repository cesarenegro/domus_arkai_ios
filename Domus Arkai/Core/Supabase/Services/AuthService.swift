//
//  AuthService.swift
//  Domus Arkai
//
//  Sign in with Apple via Supabase Auth.
//  IMPORTANTE — Apple ID Compliance:
//   - Al PRIMO sign-in Apple ritorna `fullName` ed `email`. Le richieste successive ritornano
//     SOLO `user`. Dobbiamo salvarli su Supabase user_metadata SUBITO o sono persi per sempre.
//   - L'utente deve poter cancellare l'account dall'app (App Review 5.1.1.v). La chiamata
//     `deleteAccount()` invoca una Edge Function lato server che:
//      1. Esegue revoke del token Apple (`https://appleid.apple.com/auth/revoke`)
//      2. Cancella la riga da `auth.users` (cascade su buyer_passports, user_property_dossiers,
//         visual_boq_estimates, mortgage_estimates, property_valuations, favorites)
//

import Foundation
import Supabase
import AuthenticationServices

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool = false

    private var client: SupabaseClient { SupabaseManager.shared }

    init() {
        Task { await refreshSession() }
    }

    func refreshSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
            print("✅ [Auth] session ok — uid=\(session.user.id)")
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    /// Sign in with Apple.
    /// Cattura `fullName` + `email` SOLO al primo accesso (Apple non li rimanda dopo).
    /// Li salva in Supabase user_metadata.
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let identityTokenData = credential.identityToken,
            let identityToken = String(data: identityTokenData, encoding: .utf8)
        else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Token Apple non disponibile"])
        }

        // Estrai nome+email dalla prima volta (Apple ritorna nil su sign-in successivi)
        let firstSignInName: String? = {
            guard let nameComponents = credential.fullName else { return nil }
            let formatter = PersonNameComponentsFormatter()
            let full = formatter.string(from: nameComponents).trimmingCharacters(in: .whitespaces)
            return full.isEmpty ? nil : full
        }()
        let firstSignInEmail = credential.email

        // 1. Sign-in con Supabase usando l'idToken Apple
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: identityToken)
        )

        // 2. Refresh sessione per ottenere il currentUser
        await refreshSession()

        // 3. Se è il primo sign-in e abbiamo name/email aggiuntivi, aggiorniamo user_metadata
        if let user = currentUser {
            var metadataToUpdate: [String: AnyJSON] = [:]
            if let firstSignInName,
               (user.userMetadata["full_name"]?.stringValue ?? "").isEmpty {
                metadataToUpdate["full_name"] = .string(firstSignInName)
            }
            if let firstSignInEmail,
               (user.email ?? "").isEmpty {
                // Email Supabase di solito è già dentro l'idToken Apple; metadata serve come backup.
                metadataToUpdate["apple_email"] = .string(firstSignInEmail)
            }
            if !metadataToUpdate.isEmpty {
                do {
                    try await client.auth.update(user: UserAttributes(data: metadataToUpdate))
                    print("✅ [Auth] saved Apple first-login metadata: keys=\(metadataToUpdate.keys.sorted())")
                    await refreshSession()
                } catch {
                    print("⚠️ [Auth] saving Apple metadata failed — \(error)")
                }
            }
        }

        // Se l'utente aveva già attivato le notifiche prima del login, il device token Apple
        // era stato ricevuto ma non persistito (mancava user_id). Ritentiamo ora che l'auth è ok.
        await NotificationService.shared.persistTokenIfNeeded()

        // Audit centralizzato accessi (RPC server-side) — best-effort, non blocca il login.
        await logAccess(clientType: "ios_app")
    }

    /// Logga l'accesso lato server via RPC `log_user_access(p_client_type)`.
    /// Server-side: IP anonimizzato /24 + retention 90gg + user_agent salvato.
    /// Best-effort: errori non bloccano il flow di auth.
    private func logAccess(clientType: String) async {
        struct AccessParams: Encodable { let p_client_type: String }
        do {
            try await client.rpc("log_user_access", params: AccessParams(p_client_type: clientType)).execute()
            print("✅ [Auth] access logged — client=\(clientType)")
        } catch {
            print("⚠️ [Auth] access log failed (non-blocking) — \(error)")
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        print("✅ [Auth] signed out")
    }

    // MARK: - Account deletion (Apple App Review 5.1.1.v)

    enum AccountDeletionError: LocalizedError {
        case notAuthenticated
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Non sei autenticato."
            case .serverError(let msg):
                return msg
            }
        }
    }

    struct DeleteAccountResponse: Decodable {
        let success: Bool
        let message: String?
    }

    private struct DeleteAccountBody: Encodable {
        let apple_authorization_code: String?
    }

    /// Cancellazione account: invoca Edge Function `delete-account` che:
    ///  1. Revoca il token Apple ID lato Apple (usando `authorizationCode` fresh se fornito, altrimenti
    ///     fallback sul refresh token salvato in auth.identities, se disponibile)
    ///  2. Esegue DELETE su auth.users (cascade su tutte le tabelle correlate)
    /// Al ritorno, esegue signOut locale e pulisce UserDefaults.
    ///
    /// - Parameter authorizationCode: codice Apple fresco ottenuto da un nuovo `ASAuthorizationAppleIDRequest`
    ///   immediatamente prima della deletion. Fortemente raccomandato per garantire la revoca Apple lato server.
    func deleteAccount(authorizationCode: String? = nil) async throws {
        guard isAuthenticated else { throw AccountDeletionError.notAuthenticated }
        print("🟡 [Auth] deleteAccount() — authorizationCode=\(authorizationCode != nil ? "present" : "nil")")

        do {
            let body = DeleteAccountBody(apple_authorization_code: authorizationCode)
            let response: DeleteAccountResponse = try await client.functions
                .invoke("delete-account", options: .init(body: body))
            guard response.success else {
                throw AccountDeletionError.serverError(response.message ?? "Eliminazione account non riuscita.")
            }
            print("✅ [Auth] account deleted server-side")
        } catch let error as AccountDeletionError {
            throw error
        } catch {
            print("🔴 [Auth] deleteAccount server error — \(error)")
            throw AccountDeletionError.serverError("Eliminazione account non riuscita lato server. Riprova tra qualche istante.")
        }

        // Locale: sign out + clean local data
        try? await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false

        // Pulisci UserDefaults locali (preferiti, quota Vision, ecc.)
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("arkai_") || key.hasPrefix("pref_") {
            defaults.removeObject(forKey: key)
        }
        print("✅ [Auth] local data cleared after account deletion")
    }

    /// Estrae l'authorization code da un `ASAuthorization` Apple risultato di un re-auth flow.
    /// Usato dal `ProfileView.handleDeleteAccount` per ottenere un code fresh prima della delete call.
    static func extractAuthorizationCode(from authorization: ASAuthorization) -> String? {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = credential.authorizationCode,
            let code = String(data: codeData, encoding: .utf8)
        else { return nil }
        return code
    }
}
