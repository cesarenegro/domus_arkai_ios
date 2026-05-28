//
//  ProfileView.swift
//  Domus Arkai
//
//  Profilo utente: stato auth (Apple Sign In) + Buyer Passport + preferenze app.
//

import SwiftUI
import AuthenticationServices
import Auth
import Helpers
import RoomPlan

struct ProfileView: View {
    @AppStorage("pref_notifications_visits") private var notifyVisits: Bool = true
    @AppStorage("pref_notifications_news") private var notifyNews: Bool = false
    @AppStorage("pref_language") private var language: String = "it"

    @State private var auth = AuthService.shared
    @State private var passportModel = BuyerPassportViewModel()
    @State private var subscription = SubscriptionService.shared
    @State private var notifications = NotificationService.shared
    @State private var themeService = ThemeService.shared

    @State private var showAbout: Bool = false
    @State private var showPassportEdit: Bool = false
    @State private var showMyDossiers: Bool = false
    @State private var showEmailSignIn: Bool = false
    @State private var agencyRole: AgencyRole? = nil
    @State private var hasFetchedRole: Bool = false
    @State private var authErrorMessage: String?
    @State private var showDeleteConfirm1: Bool = false
    @State private var showDeleteConfirm2: Bool = false
    @State private var isDeletingAccount: Bool = false

    private let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        if auth.isAuthenticated {
                            authenticatedHeader
                            passportSection
                        } else {
                            guestHero
                            signInBlock
                        }
                        notificationsCard
                        appearanceCard
                        languageCard
                        legalCard
                        aboutCard
                        roomScanPOCCard
                        if auth.isAuthenticated {
                            signOutButton
                        }
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if auth.isAuthenticated, passportModel.passport == nil {
                    await passportModel.load()
                }
                // Refresh notifications status + retry persist se utente già loggato
                await notifications.refreshAuthorizationStatus()
                if auth.isAuthenticated {
                    await notifications.persistTokenIfNeeded()
                }
                // Carica ruolo agency per gating "Modalità professionale" v2.0
                if auth.isAuthenticated, !hasFetchedRole {
                    agencyRole = await AgencyAccessService.shared.fetchMyRole()
                    hasFetchedRole = true
                }
            }
            .onChange(of: auth.isAuthenticated) { _, isAuth in
                if isAuth {
                    Task { await passportModel.load() }
                } else {
                    passportModel.passport = nil
                    passportModel.phase = .idle
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutSheet(version: appVersion)
            }
            .sheet(isPresented: $showPassportEdit, onDismiss: {
                Task { await passportModel.load() }
            }) {
                BuyerPassportEditView(model: passportModel)
            }
            .sheet(isPresented: $showMyDossiers) {
                MyDossiersView(presentedAsSheet: true)
            }
            .sheet(isPresented: $showEmailSignIn) {
                EmailPasswordSignInView()
            }
            .alert("Accesso non riuscito", isPresented: authErrorBinding) {
                Button("OK", role: .cancel) { authErrorMessage = nil }
            } message: {
                Text(authErrorMessage ?? "")
            }
        }
    }

    // MARK: - Guest (not authenticated)

    private var guestHero: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Benvenuto in Arkai Domus")
                .font(ADTypography.largeTitle)
                .foregroundStyle(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Accedi per attivare il tuo Buyer Passport, sincronizzare i preferiti e ricevere selezioni di immobili coerenti con il tuo profilo.")
                .font(ADTypography.body)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    private var signInBlock: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Accedi con Apple")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    await handleAppleSignIn(result)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

            Text("L'accesso avviene in modo riservato tramite il tuo ID Apple. Nessuna password da memorizzare.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .fixedSize(horizontal: false, vertical: true)

            // Secondary: accesso professionale email + password (account creati lato Supabase
            // dall'amministratore Arkai per agenzie e super-admin).
            Divider()
                .padding(.vertical, ADSpacing.s2)

            Button {
                showEmailSignIn = true
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Hai un account professionale? Accedi con email")
                        .font(ADTypography.metadata.weight(.medium))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(ADColor.primary)
                .padding(.vertical, ADSpacing.s2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    // MARK: - Authenticated

    private var authenticatedHeader: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            ZStack {
                Circle()
                    .fill(ADColor.primaryLight)
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(ADColor.primary)
            }
            Text(userDisplayName)
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)
            if let email = userEmail, !email.isEmpty {
                Text(email)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var passportSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Il tuo Passaporto")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            BuyerPassportCard(
                passport: passportModel.passport,
                userDisplayName: userDisplayName,
                userEmail: userEmail
            )

            if passportModel.passport == nil, passportModel.phase != .loading {
                Text("Compila il tuo Passaporto per attivare la ricerca personalizzata.")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showPassportEdit = true
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: passportModel.passport == nil ? "plus.circle" : "pencil.circle")
                        .font(.system(size: 14, weight: .semibold))
                    Text(passportModel.passport == nil ? "Compila il Passaporto" : "Aggiorna il Passaporto")
                }
            }
            .buttonStyle(.adSecondary)
        }
    }

    private var myDossiersEntry: some View {
        Button {
            showMyDossiers = true
        } label: {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(ADColor.primarySoft)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ADColor.primaryLight.opacity(0.5)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("I miei Dossier")
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(1)
                    Text("Tutti gli immobili con stime e preventivi salvati")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(ADColor.textLight)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ADSpacing.Card.paddingLarge)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preferences (always visible)

    private var notificationsCard: some View {
        section(title: "Notifiche") {
            VStack(spacing: 0) {
                pushPermissionRow
                Divider().overlay(ADColor.border.opacity(0.6))
                toggleRow(label: "Conferme visite", isOn: $notifyVisits)
                Divider().overlay(ADColor.border.opacity(0.6))
                toggleRow(label: "Novità dall'agenzia", isOn: $notifyNews, isLast: true)
            }
        }
    }

    @ViewBuilder
    private var pushPermissionRow: some View {
        let status = notifications.authorizationStatus
        HStack(spacing: ADSpacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifiche push")
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
                Text(pushStatusCaption(status))
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
                    .lineLimit(1)
            }
            Spacer(minLength: ADSpacing.s2)
            pushStatusAction(status)
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private func pushStatusCaption(_ status: NotificationService.AuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional: "Attive"
        case .denied: "Disattivate dalle impostazioni iOS"
        case .notDetermined: "Tocca per attivare"
        }
    }

    @ViewBuilder
    private func pushStatusAction(_ status: NotificationService.AuthorizationStatus) -> some View {
        switch status {
        case .authorized, .provisional:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ADColor.primarySoft)
        case .denied:
            Button("Apri Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(ADTypography.smallMedium)
            .foregroundStyle(ADColor.primarySoft)
        case .notDetermined:
            Button("Attiva") {
                Task { await notifications.requestAuthorization() }
            }
            .font(ADTypography.smallMedium.weight(.semibold))
            .foregroundStyle(ADColor.primary)
        }
    }

    private var appearanceCard: some View {
        section(title: "Aspetto") {
            VStack(spacing: 0) {
                ForEach(Array(AppTheme.allCases.enumerated()), id: \.element.id) { idx, theme in
                    Button {
                        themeService.theme = theme
                    } label: {
                        HStack(spacing: ADSpacing.s3) {
                            Image(systemName: theme.iconName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(ADColor.primarySoft)
                                .frame(width: 24)
                            Text(theme.label)
                                .font(ADTypography.body)
                                .foregroundStyle(ADColor.text)
                                .lineLimit(1)
                            Spacer(minLength: ADSpacing.s2)
                            if themeService.theme == theme {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(ADColor.primary)
                            }
                        }
                        .padding(.horizontal, ADSpacing.s4)
                        .padding(.vertical, ADSpacing.s3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < AppTheme.allCases.count - 1 {
                        Divider().overlay(ADColor.border.opacity(0.6))
                    }
                }
            }
        }
    }

    private var languageCard: some View {
        section(title: "Lingua") {
            HStack(spacing: ADSpacing.s3) {
                Text(language == "it" ? "Italiano" : "English")
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
                Spacer(minLength: ADSpacing.s2)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ADColor.primarySoft)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
        }
    }

    private var legalCard: some View {
        section(title: "Legale") {
            VStack(spacing: 0) {
                linkRow(label: "Privacy Policy", systemImage: "lock.shield") {
                    if let url = URL(string: "https://arkai.dev/app/PPdomusarkai") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().overlay(ADColor.border.opacity(0.6))
                linkRow(label: "Termini di servizio (EULA)", systemImage: "doc.text", isLast: true) {
                    // EULA standard Apple per app che non hanno EULA proprio.
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private var aboutCard: some View {
        Button {
            showAbout = true
        } label: {
            HStack(spacing: ADSpacing.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Informazioni")
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.primary)
                        .lineLimit(1)
                    Text("v \(appVersion) · powered by Arkai Domus")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: ADSpacing.s2)
                Image(systemName: "chevron.right")
                    .foregroundStyle(ADColor.textLight)
                    .font(.system(size: 14))
            }
            .padding(ADSpacing.Card.paddingLarge)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
        .buttonStyle(.plain)
    }

    // v2.0 Spatial Staging — voce "Modalità professionale" visibile a:
    //  1. utenti autenticati con ruolo agency (canScanProperties == true:
    //     super_admin / agency_admin / agent — viewer escluso)
    //  2. device con sensore LiDAR (iPhone Pro / iPad Pro)
    @ViewBuilder
    private var roomScanPOCCard: some View {
        let hasRole = agencyRole?.canScanProperties ?? false
        // La voce è visibile per chiunque abbia il ruolo (anche senza LiDAR
        // ProfessionalModeView gestisce l'unsupportedHardwareNote internamente)
        if hasRole {
            NavigationLink {
                ProfessionalModeView(agencyRole: agencyRole)
            } label: {
                HStack(spacing: ADSpacing.s3) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ADColor.accentWarm.opacity(0.18))
                            .frame(width: 38, height: 38)
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(ADColor.accentWarm)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: ADSpacing.s2) {
                            Text("Modalità professionale")
                                .font(ADTypography.bodyMedium.weight(.semibold))
                                .foregroundStyle(ADColor.primary)
                                .lineLimit(1)
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(ADColor.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ADColor.accentWarm)
                                .clipShape(Capsule())
                        }
                        Text("Scansione 3D · Le mie scansioni · Spatial Staging")
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: ADSpacing.s2)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ADColor.textLight)
                        .font(.system(size: 14))
                }
                .padding(ADSpacing.Card.paddingLarge)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(ADColor.accentWarm.opacity(0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            }
            .buttonStyle(.plain)
        }
    }

    private var signOutButton: some View {
        VStack(spacing: ADSpacing.s3) {
            Button(role: .destructive) {
                Task { await handleSignOut() }
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Esci")
                }
            }
            .buttonStyle(.adSecondary)

            Button {
                showDeleteConfirm1 = true
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    if isDeletingAccount {
                        ProgressView().tint(ADColor.warning)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(isDeletingAccount ? "Eliminazione in corso…" : "Elimina profilo")
                }
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.warning)
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)

            Text("L'eliminazione cancella definitivamente il tuo profilo, il Buyer Passport, i Dossier e ogni dato associato. L'operazione non è reversibile.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ADSpacing.s3)
        }
        .alert("Elimina il tuo profilo?", isPresented: $showDeleteConfirm1) {
            Button("Annulla", role: .cancel) {}
            Button("Continua", role: .destructive) {
                showDeleteConfirm2 = true
            }
        } message: {
            Text("Questa azione cancellerà definitivamente il tuo account, il Buyer Passport, tutti i Dossier salvati e le analisi Arkai Vision Pro. Non potrai recuperare i dati. Vuoi continuare?")
        }
        .alert("Conferma definitiva", isPresented: $showDeleteConfirm2) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina definitivamente", role: .destructive) {
                Task { await handleDeleteAccount() }
            }
        } message: {
            Text("Tocca \"Elimina definitivamente\" per cancellare il profilo. L'app si disconnetterà automaticamente.")
        }
    }

    // MARK: - Helpers

    private var userDisplayName: String {
        if let user = auth.currentUser {
            if let name = user.userMetadata["full_name"]?.stringValue, !name.isEmpty {
                return name
            }
            if let email = user.email, !email.isEmpty {
                return email.split(separator: "@").first.map(String.init) ?? "Utente"
            }
        }
        return "Ospite"
    }

    private var userEmail: String? {
        auth.currentUser?.email
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        print("🟢 [Auth][Profile] Apple Sign In completion")
        switch result {
        case .success(let authorization):
            do {
                try await auth.signInWithApple(authorization)
                print("✅ [Auth][Profile] signed in — userID=\(auth.currentUser?.id.uuidString ?? "?")")
                await passportModel.load()
            } catch {
                print("🔴 [Auth][Profile] signInWithApple failed — \(error)")
                authErrorMessage = "Impossibile completare l'accesso. Riprova."
            }
        case .failure(let error):
            print("🔴 [Auth][Profile] ASAuthorization error — \(error)")
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue { return }
            authErrorMessage = "Accesso interrotto. Riprova."
        }
    }

    private func handleDeleteAccount() async {
        print("🟡 [Auth][Profile] delete account tap — requesting fresh Apple authorizationCode")
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        // Per la revoca Apple server-side serve un fresh authorization code.
        // Avviamo un nuovo Apple Sign In flow esclusivamente per ottenerlo.
        let authorizationCode = await requestFreshAppleAuthorizationCode()
        if authorizationCode == nil {
            print("⚠️ [Auth][Profile] no fresh code obtained — backend farà fallback su refresh token persistito (warning log lato server)")
        }

        do {
            try await auth.deleteAccount(authorizationCode: authorizationCode)
            passportModel.passport = nil
            passportModel.phase = .idle
            print("✅ [Auth][Profile] account deleted")
        } catch AuthService.AccountDeletionError.notAuthenticated {
            authErrorMessage = "Non sei più autenticato. Esci e riprova."
        } catch {
            print("🔴 [Auth][Profile] deleteAccount failed — \(error)")
            authErrorMessage = error.localizedDescription
        }
    }

    /// Avvia un Apple Sign In flow programmaticamente per ottenere un fresh `authorizationCode`
    /// da passare al server per la revoca Apple. Se l'utente annulla → nil.
    private func requestFreshAppleAuthorizationCode() async -> String? {
        await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = []
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleReauthDelegate { result in
                switch result {
                case .success(let auth):
                    let code = AuthService.extractAuthorizationCode(from: auth)
                    continuation.resume(returning: code)
                case .failure(let error):
                    print("⚠️ [Auth][Profile] re-auth failed — \(error)")
                    continuation.resume(returning: nil)
                }
            }
            // Trattieni il delegate in vita finché non risponde
            objc_setAssociatedObject(controller, &AssociatedDelegateKey.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
        }
    }

    private func handleSignOut() async {
        print("🟡 [Auth][Profile] sign out tap")
        do {
            try await auth.signOut()
            passportModel.passport = nil
            passportModel.phase = .idle
            print("✅ [Auth][Profile] signed out")
        } catch {
            print("🔴 [Auth][Profile] signOut failed — \(error)")
            authErrorMessage = "Disconnessione non riuscita."
        }
    }

    private func toggleRow(label: String, isOn: Binding<Bool>, isLast: Bool = false) -> some View {
        HStack(spacing: ADSpacing.s3) {
            Text(label)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(ADColor.primarySoft)
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private func linkRow(label: String, systemImage: String, isLast: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: systemImage)
                    .foregroundStyle(ADColor.primarySoft)
                    .frame(width: 24)
                Text(label)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .lineLimit(1)
                Spacer(minLength: ADSpacing.s2)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(ADColor.textLight)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
        }
        .buttonStyle(.plain)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(title)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
                .padding(.horizontal, ADSpacing.s2)
            content()
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }

    private var authErrorBinding: Binding<Bool> {
        Binding(
            get: { authErrorMessage != nil },
            set: { if !$0 { authErrorMessage = nil } }
        )
    }
}

private struct AboutSheet: View {
    let version: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        heroBlock
                        dataBlock
                        quotaBlock
                        legalBlock
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Informazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Arkai Domus")
                .font(ADTypography.display)
                .foregroundStyle(.white)
            Rectangle()
                .fill(.white.opacity(0.55))
                .frame(width: 36, height: 1)
            Text("La nuova esperienza immobiliare intelligente.")
                .font(ADTypography.body)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Text("Versione \(version) · © 2026 Arkai Domus")
                .font(ADTypography.metadata)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, ADSpacing.s2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.panel))
    }

    private var dataBlock: some View {
        infoCard(
            title: "I DATI CHE CONSERVIAMO",
            rows: [
                ("person", "Account riservato",
                 "Identificativo Apple, nome ed email forniti al login. Conservati per autenticarti e personalizzare l'esperienza."),
                ("creditcard", "Buyer Passport",
                 "Le preferenze di acquisto che condividi liberamente (budget, zone, tipologie). Visibili solo ai consulenti di Arkai Domus."),
                ("folder", "Il mio Dossier",
                 "Le stime che salvi su un immobile (valutazione di zona, mutuo, ristrutturazione, analisi visiva). Visibili solo a te."),
                ("photo.on.rectangle.angled", "Immagini Arkai Vision Pro",
                 "Le foto che invii per l'analisi visiva. Elaborate esclusivamente per generare la stima della stanza, conservate in forma riservata.")
            ]
        )
    }

    private var quotaBlock: some View {
        infoCard(
            title: "SERVIZIO E LIMITI",
            rows: [
                ("sparkles", "Arkai Vision Pro",
                 "5 analisi visive gratuite al mese per utente loggato. La quota si azzera il primo giorno del mese successivo. Il servizio è offerto gratuitamente dall'agenzia immobiliare che ti ha invitato."),
                ("location.viewfinder", "Valutazione di zona, mutuo e ristrutturazione",
                 "Senza limiti, sempre gratuiti."),
                ("envelope", "Contatto con l'agenzia",
                 "Le richieste di visita o consulenza vengono inoltrate riservatamente all'agenzia titolare dell'immobile.")
            ]
        )
    }

    private var legalBlock: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("DOCUMENTAZIONE")
                .font(ADTypography.metadata.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(ADColor.textMuted)
                .padding(.horizontal, ADSpacing.s2)

            VStack(spacing: 0) {
                legalLink(label: "Privacy Policy", url: "https://arkai.dev/app/PPdomusarkai")
                Divider().overlay(ADColor.border.opacity(0.6))
                legalLink(label: "Termini di servizio (EULA)", url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/", isLast: true)
            }
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }

    private func legalLink(label: String, url: String, isLast: Bool = false) -> some View {
        Button {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        } label: {
            HStack(spacing: ADSpacing.s3) {
                Text(label)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(ADColor.textLight)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
        }
        .buttonStyle(.plain)
    }

    private func infoCard(title: String, rows: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(title)
                .font(ADTypography.metadata.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(ADColor.textMuted)
                .padding(.horizontal, ADSpacing.s2)

            VStack(alignment: .leading, spacing: ADSpacing.s3) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    HStack(alignment: .top, spacing: ADSpacing.s3) {
                        Image(systemName: row.0)
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(ADColor.primarySoft)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.1)
                                .font(ADTypography.bodyMedium.weight(.semibold))
                                .foregroundStyle(ADColor.primary)
                            Text(row.2)
                                .font(ADTypography.small)
                                .foregroundStyle(ADColor.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    if idx < rows.count - 1 {
                        Divider().overlay(ADColor.border.opacity(0.5))
                    }
                }
            }
            .padding(ADSpacing.Card.paddingLarge)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }
}

// MARK: - AppleReauthDelegate (per re-auth Apple ID prima della account deletion)

private enum AssociatedDelegateKey {
    static var key: UInt8 = 0
}

private final class AppleReauthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

#Preview {
    ProfileView()
}
