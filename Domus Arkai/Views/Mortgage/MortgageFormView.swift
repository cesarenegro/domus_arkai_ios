//
//  MortgageFormView.swift
//  Domus Arkai
//
//  Spec: `08_ios_mortgage_form.json`.
//

import SwiftUI

struct MortgageFormView: View {
    @State var model: MortgageViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showResult: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        introBlock
                        formFields
                        privacyNote
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                }

                bottomBar
            }
            .navigationTitle("Calcola mutuo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .sheet(isPresented: $showResult) {
                if let estimate = model.estimate {
                    MortgageResultView(estimate: estimate, property: model.property)
                }
            }
        }
    }

    private var introBlock: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(model.property.title)
                .font(ADTypography.cardTitle)
                .foregroundStyle(ADColor.primary)
            Text("Prezzo immobile: \(model.property.formattedPrice)")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var formFields: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            inputField(
                label: "Reddito mensile netto",
                placeholder: "es. 3.500",
                value: Binding(get: { model.monthlyIncome }, set: { model.monthlyIncome = $0 }),
                suffix: "€"
            )
            inputField(
                label: "Secondo reddito familiare",
                placeholder: "opzionale",
                value: Binding(get: { model.secondIncome }, set: { model.secondIncome = $0 }),
                suffix: "€"
            )
            inputField(
                label: "Anticipo disponibile",
                placeholder: "es. 160.000",
                value: Binding(get: { model.deposit }, set: { model.deposit = $0 }),
                suffix: "€"
            )
            yearsPicker
            inputField(
                label: "Altri impegni mensili",
                placeholder: "es. 250",
                value: Binding(get: { model.existingDebts }, set: { model.existingDebts = $0 }),
                suffix: "€"
            )
            firstHomeToggle
        }
    }

    private func inputField(
        label: String,
        placeholder: String,
        value: Binding<Double?>,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(label)
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)
            HStack(spacing: ADSpacing.s2) {
                TextField(placeholder, value: value, format: .number)
                    .keyboardType(.numberPad)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                Text(suffix)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
            }
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 52)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
    }

    private var yearsPicker: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Durata mutuo")
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)
            HStack(spacing: ADSpacing.s2) {
                ForEach([10, 15, 20, 25, 30], id: \.self) { year in
                    Button {
                        model.years = year
                    } label: {
                        Text("\(year) anni")
                            .font(ADTypography.smallMedium)
                            .foregroundStyle(model.years == year ? ADColor.primary : ADColor.textMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(model.years == year ? ADColor.primaryLight : ADColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: ADRadius.md)
                                    .stroke(model.years == year ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var firstHomeToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prima casa")
                    .font(ADTypography.smallMedium)
                    .foregroundStyle(ADColor.text)
                Text("Influisce sulle agevolazioni")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
            }
            Spacer()
            Toggle("", isOn: $model.isFirstHome)
                .labelsHidden()
                .tint(ADColor.primarySoft)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.md)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
    }

    private var privacyNote: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "lock.shield")
                .foregroundStyle(ADColor.primarySoft)
            Text("I tuoi dati sono al sicuro e riservati.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
            Spacer()
        }
    }

    private var bottomBar: some View {
        Button {
            model.calculate()
            showResult = model.estimate != nil
        } label: {
            Text("Calcola possibilità")
        }
        .buttonStyle(.adPrimary)
        .disabled(!model.canCalculate)
        .opacity(model.canCalculate ? 1 : 0.5)
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.vertical, ADSpacing.s3)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
