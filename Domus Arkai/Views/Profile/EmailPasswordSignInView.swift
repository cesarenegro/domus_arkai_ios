//
//  EmailPasswordSignInView.swift
//  Domus Arkai
//
//  v2.0 — sheet di login email+password per gli account amministrativi
//  creati lato Supabase (Auth dashboard). NON usato dai clienti finali B2C
//  che continuano con Sign in with Apple come metodo principale.
//

import SwiftUI

struct EmailPasswordSignInView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @FocusState private var focused: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        header
                        formCard
                        if let errorMessage {
                            errorBanner(errorMessage)
                        }
                        submitButton
                        infoNote
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s5)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Accesso professionale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("MODALITÀ PROFESSIONALE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Accedi con le credenziali della tua agenzia")
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Queste credenziali sono fornite da Arkai Domus all'amministratore dell'agenzia. Gli utenti privati continuano a usare \"Accedi con Apple\" nella schermata principale.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            fieldLabel("Email")
            TextField("nome@agenzia.it", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .focused($focused, equals: .email)
                .onSubmit { focused = .password }
                .padding(.horizontal, ADSpacing.s4)
                .frame(height: 48)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focused == .email ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            fieldLabel("Password")
                .padding(.top, ADSpacing.s2)
            SecureField("••••••••", text: $password)
                .submitLabel(.go)
                .focused($focused, equals: .password)
                .onSubmit { Task { await submit() } }
                .padding(.horizontal, ADSpacing.s4)
                .frame(height: 48)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focused == .password ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(ADSpacing.s4)
        .background(ADColor.surfaceSoft.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(2)
            .foregroundStyle(ADColor.textMuted)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ADColor.warning)
                .padding(.top, 2)
            Text(message)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.warning)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.warning.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ADColor.warning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: ADSpacing.s2) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "key.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(isLoading ? "Accesso in corso…" : "Accedi")
                    .font(ADTypography.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(canSubmit ? ADColor.primary : ADColor.textLight)
            .foregroundStyle(ADColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isLoading)
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(ADColor.textLight)
                .padding(.top, 2)
            Text("Hai dimenticato la password o non hai ancora un account professionale? Contatta il referente della tua agenzia o il supporto Arkai Domus.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Submit

    private func submit() async {
        guard canSubmit else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.signInWithEmail(email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EmailPasswordSignInView()
}
