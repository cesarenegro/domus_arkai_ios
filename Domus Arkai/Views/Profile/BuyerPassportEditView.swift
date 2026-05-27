//
//  BuyerPassportEditView.swift
//  Domus Arkai
//
//  Form per compilare/aggiornare il Buyer Passport.
//  Linguaggio brand-safe: mai "score" o "algoritmo" — usiamo "parametro di eccellenza".
//

import SwiftUI

struct BuyerPassportEditView: View {
    @Bindable var model: BuyerPassportViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        intro
                        financialSection
                        preferencesSection
                        propertyMinSection
                        disclaimer
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)

                saveBar
            }
            .navigationTitle("Il tuo Passaporto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if case .idle = model.phase { await model.load() }
            }
            .alert("Errore", isPresented: errorBinding) {
                Button("OK", role: .cancel) { model.phase = .loaded }
            } message: {
                Text(currentErrorMessage)
            }
        }
    }

    // MARK: - Sections

    private var intro: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Il tuo profilo di acquisto")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("Più informazioni condividi con noi, più la nostra ricerca diventa precisa per te. Le tue indicazioni restano riservate e visibili solo ai consulenti di Arkai Domus.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var financialSection: some View {
        formCard(title: "Disponibilità finanziaria") {
            VStack(spacing: ADSpacing.s3) {
                currencyField(title: "Budget massimo", value: $model.maxBudget, placeholder: "es. 800.000")
                Divider().overlay(ADColor.border.opacity(0.5))
                currencyField(title: "Liquidità disponibile", value: $model.liquidity, placeholder: "es. 250.000")
                Divider().overlay(ADColor.border.opacity(0.5))
                percentField(title: "Mutuo previsto", value: $model.mortgageNeededPct)
            }
        }
    }

    private var preferencesSection: some View {
        formCard(title: "Le tue preferenze") {
            VStack(alignment: .leading, spacing: ADSpacing.s3) {
                VStack(alignment: .leading, spacing: ADSpacing.s2) {
                    Text("Zone di interesse")
                        .font(ADTypography.smallMedium.weight(.semibold))
                        .foregroundStyle(ADColor.textMuted)
                    TextField("Brera, Porta Romana, …", text: $model.preferredAreasInput, axis: .vertical)
                        .font(ADTypography.body)
                        .foregroundStyle(ADColor.text)
                        .padding(ADSpacing.s3)
                        .background(ADColor.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: ADRadius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: ADRadius.input)
                                .stroke(ADColor.border, lineWidth: 1)
                        )
                    Text("Separa le zone con una virgola.")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textLight)
                }

                VStack(alignment: .leading, spacing: ADSpacing.s2) {
                    Text("Tipologie preferite")
                        .font(ADTypography.smallMedium.weight(.semibold))
                        .foregroundStyle(ADColor.textMuted)
                    FlexibleCategoryRow(
                        categories: BuyerPassportViewModel.availableCategories,
                        selection: $model.preferredCategories
                    )
                }
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s4)
        }
    }

    private var propertyMinSection: some View {
        formCard(title: "Caratteristiche minime") {
            VStack(spacing: 0) {
                stepperRow(
                    label: "Camere",
                    value: $model.minBedrooms,
                    range: 0...8,
                    suffix: $model.minBedrooms.wrappedValue == 1 ? "camera" : "camere"
                )
                Divider().overlay(ADColor.border.opacity(0.5))
                stepperRow(
                    label: "Bagni",
                    value: $model.minBathrooms,
                    range: 0...6,
                    suffix: $model.minBathrooms.wrappedValue == 1 ? "bagno" : "bagni",
                    isLast: true
                )
            }
        }
    }

    private var disclaimer: some View {
        Text("Il parametro di eccellenza si aggiorna automaticamente in base alla completezza del tuo Passaporto e ti consente di ricevere selezioni di immobili coerenti con il tuo profilo.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ADSpacing.s2)
    }

    // MARK: - Sticky bar

    private var saveBar: some View {
        VStack(spacing: ADSpacing.s2) {
            Button {
                Task { await model.save() }
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    if model.phase == .saving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(model.phase == .saving ? "Salvataggio…" : "Salva il Passaporto")
                }
            }
            .buttonStyle(.adPrimary)
            .disabled(model.phase == .saving)
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

    // MARK: - Reusable rows

    private func currencyField(title: String, value: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: ADSpacing.s3) {
            Text(title)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            HStack(spacing: 4) {
                Text("€")
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
                TextField(placeholder, text: value)
                    .keyboardType(.numberPad)
                    .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 110)
            }
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private func percentField(title: String, value: Binding<String>) -> some View {
        HStack(spacing: ADSpacing.s3) {
            Text(title)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            HStack(spacing: 4) {
                TextField("60", text: value)
                    .keyboardType(.numberPad)
                    .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 60)
                Text("%")
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.textMuted)
            }
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String, isLast: Bool = false) -> some View {
        HStack(spacing: ADSpacing.s3) {
            Text(label)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
            Spacer(minLength: ADSpacing.s2)
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue) \(suffix)")
                    .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
            }
            .labelsHidden()
            Text("\(value.wrappedValue) \(suffix)")
                .font(ADTypography.bodyMedium.weight(.semibold).monospacedDigit())
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
    }

    private func formCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(title)
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)
                .padding(.horizontal, ADSpacing.s2)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.card)
                        .stroke(ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }

    // MARK: - Error binding

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = model.phase { return true }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    if case .error = model.phase { model.phase = .loaded }
                }
            }
        )
    }

    private var currentErrorMessage: String {
        if case .error(let msg) = model.phase { return msg }
        return ""
    }
}

// MARK: - Category multi-selection flow

private struct FlexibleCategoryRow: View {
    let categories: [(key: String, label: String)]
    @Binding var selection: Set<String>

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: ADSpacing.s2)]
        LazyVGrid(columns: columns, spacing: ADSpacing.s2) {
            ForEach(categories, id: \.key) { item in
                FilterPill(
                    label: item.label,
                    isSelected: selection.contains(item.key)
                ) {
                    if selection.contains(item.key) {
                        selection.remove(item.key)
                    } else {
                        selection.insert(item.key)
                    }
                }
            }
        }
    }
}

#Preview {
    BuyerPassportEditView(model: BuyerPassportViewModel())
}
