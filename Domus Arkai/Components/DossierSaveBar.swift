//
//  DossierSaveBar.swift
//  Domus Arkai
//
//  Sticky CTA riusabile "Salva nel mio Dossier" — gestisce stati
//  (idle / saving / success / failure) + label/icon dinamici + caption brand-safe.
//

import SwiftUI

struct DossierSaveBar: View {
    enum State: Equatable {
        case idle
        case saving
        case success
        case failure(String)
    }

    let state: State
    let isEnabled: Bool
    let caption: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: ADSpacing.s2) {
            Button(action: action) {
                HStack(spacing: ADSpacing.s2) {
                    iconView
                    Text(buttonLabel)
                }
            }
            .buttonStyle(.adPrimary)
            .disabled(!isEnabled || state == .saving)
            .opacity((!isEnabled || state == .saving) ? 0.55 : 1.0)

            Text(caption)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textLight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.top, ADSpacing.s3)
        .padding(.bottom, ADSpacing.s5)
        .background(
            ADColor.surface
                .overlay(
                    Rectangle()
                        .fill(ADColor.border.opacity(0.4))
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .saving:
            ProgressView().tint(.white)
        case .success:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .semibold))
        case .idle, .failure:
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var buttonLabel: String {
        switch state {
        case .saving: "Salvataggio…"
        case .success: "Salvato nel Dossier"
        case .idle, .failure: "Salva nel mio Dossier"
        }
    }
}
