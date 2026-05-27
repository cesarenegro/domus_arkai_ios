//
//  RenovationDifficultySheet.swift
//  Domus Arkai
//
//  Bottom sheet per selezionare le complessità logistiche del cantiere
//  (centro storico, ZTL, piano alto, ecc.). Brand-safe: nessuna percentuale,
//  solo etichette descrittive.
//

import SwiftUI

struct RenovationDifficultySheet: View {
    @Bindable var model: RenovationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s3) {
                        intro

                        VStack(spacing: ADSpacing.s2) {
                            noComplexityRow
                            ForEach(model.difficultyFactors) { factor in
                                factorRow(factor)
                            }
                        }

                        if let msg = model.difficultyIntegrationMessage {
                            HStack(alignment: .top, spacing: ADSpacing.s2) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(ADColor.primarySoft)
                                    .font(.system(size: 16))
                                Text(msg)
                                    .font(ADTypography.metadata)
                                    .foregroundStyle(ADColor.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(ADSpacing.s4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ADColor.surfaceSoft)
                            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                            .padding(.top, ADSpacing.s2)
                        }
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, ADSpacing.s8)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Complessità cantiere")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fatto") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                        .font(ADTypography.smallMedium.weight(.semibold))
                }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Seleziona le condizioni logistiche del cantiere")
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Le complessità selezionate verranno integrate nella pianificazione dei costi finali.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Opzione esplicita per dichiarare "nessuna complessità". Quando selezionata, deseleziona tutto.
    private var noComplexityRow: some View {
        let isSelected = model.selectedDifficultyKeys.isEmpty
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                model.selectedDifficultyKeys.removeAll()
            }
        } label: {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? ADColor.primarySoft : ADColor.border)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nessuna complessità")
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.text)
                        .lineLimit(1)
                    Text("Cantiere standard, nessuna condizione logistica particolare.")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(ADSpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? ADColor.primaryLight.opacity(0.4) : ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(isSelected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func factorRow(_ factor: BOQDifficultyFactor) -> some View {
        let isSelected = model.isDifficultySelected(factor)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                model.toggleDifficulty(factor)
            }
        } label: {
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? ADColor.primarySoft : ADColor.border)

                VStack(alignment: .leading, spacing: 2) {
                    Text(factor.label)
                        .font(ADTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(ADColor.text)
                        .lineLimit(2)
                    if !factor.description.isEmpty {
                        Text(factor.description)
                            .font(ADTypography.metadata)
                            .foregroundStyle(ADColor.textMuted)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(ADSpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? ADColor.primaryLight.opacity(0.4) : ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(isSelected ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
        .buttonStyle(.plain)
    }
}
