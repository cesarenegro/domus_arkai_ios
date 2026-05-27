//
//  VisitBookingView.swift
//  Domus Arkai
//
//  Spec: `12_ios_visit_booking.json`. Crea lead + visit_request.
//

import SwiftUI

struct VisitBookingView: View {
    @State var model: VisitBookingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s5) {
                        if let success = model.submissionResult {
                            successView(success)
                        } else {
                            introBlock
                            dateTimeSection
                            contactSection
                            notesSection
                            Color.clear.frame(height: 100)
                        }
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                }

                if model.submissionResult == nil {
                    bottomBar
                }
            }
            .navigationTitle("Prenota visita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(model.submissionResult == nil ? "Annulla" : "Chiudi") {
                        dismiss()
                    }
                    .foregroundStyle(ADColor.primary)
                }
            }
        }
    }

    private var introBlock: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(model.property.title)
                .font(ADTypography.cardTitle)
                .foregroundStyle(ADColor.primary)
            Text(model.property.locationLine)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Quando vorresti visitare?")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            DatePicker(
                "Data preferita",
                selection: $model.preferredDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding(ADSpacing.s4)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.md)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))

            VStack(spacing: ADSpacing.s2) {
                ForEach(VisitRequest.TimeSlot.allCases, id: \.self) { slot in
                    Button {
                        model.timeSlot = slot
                    } label: {
                        HStack {
                            Text(slot.label)
                                .font(ADTypography.smallMedium)
                                .foregroundStyle(model.timeSlot == slot ? ADColor.primary : ADColor.text)
                            Spacer()
                            Image(systemName: model.timeSlot == slot ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(model.timeSlot == slot ? ADColor.primarySoft : ADColor.border)
                        }
                        .padding(ADSpacing.s4)
                        .background(model.timeSlot == slot ? ADColor.primaryLight.opacity(0.5) : ADColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: ADRadius.md)
                                .stroke(model.timeSlot == slot ? ADColor.primarySoft : ADColor.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("I tuoi contatti")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(ADColor.textMuted)
                .tracking(0.5)

            textField(label: "Nome e cognome", placeholder: "Mario Rossi", text: $model.name)
            textField(label: "Telefono", placeholder: "+39 333 1234567", text: $model.phone, keyboard: .phonePad)
            textField(label: "Email", placeholder: "mario.rossi@email.it", text: $model.email, keyboard: .emailAddress)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Note (opzionale)")
                .font(ADTypography.smallMedium)
                .foregroundStyle(ADColor.textMuted)

            TextEditor(text: $model.notes)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .frame(height: 96)
                .padding(.horizontal, ADSpacing.s2)
                .padding(.vertical, ADSpacing.s2)
                .scrollContentBackground(.hidden)
                .background(ADColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .stroke(ADColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
        }
    }

    private func textField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s1) {
            Text(label)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
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

    private var bottomBar: some View {
        Button {
            Task { await model.submit() }
        } label: {
            if model.isSubmitting {
                ProgressView().tint(.white)
            } else {
                Text("Invia richiesta")
            }
        }
        .buttonStyle(.adPrimary)
        .disabled(!model.canSubmit || model.isSubmitting)
        .opacity(model.canSubmit && !model.isSubmitting ? 1 : 0.5)
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.vertical, ADSpacing.s3)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func successView(_ request: VisitRequest) -> some View {
        VStack(spacing: ADSpacing.s5) {
            ZStack {
                Circle()
                    .fill(ADColor.primaryLight)
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(ADColor.primarySoft)
            }
            .padding(.top, ADSpacing.s6)

            VStack(spacing: ADSpacing.s2) {
                Text("Richiesta ricevuta")
                    .font(ADTypography.pageTitle)
                    .foregroundStyle(ADColor.primary)
                Text("L'agenzia ti contatterà per confermare la visita.")
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ADSpacing.s2)
            }

            VStack(spacing: 0) {
                row("Data", request.preferredDate.formatted(date: .complete, time: .omitted))
                row("Fascia oraria", request.preferredTimeSlot.label, isLast: true)
            }
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            .padding(.top, ADSpacing.s3)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ label: String, _ value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: ADSpacing.s3) {
                Text(label)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(1)
                Spacer(minLength: ADSpacing.s2)
                Text(value)
                    .font(ADTypography.smallMedium)
                    .foregroundStyle(ADColor.text)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
            if !isLast {
                Divider().overlay(ADColor.border.opacity(0.6))
            }
        }
    }
}
