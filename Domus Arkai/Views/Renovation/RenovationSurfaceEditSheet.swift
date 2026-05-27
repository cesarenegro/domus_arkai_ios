//
//  RenovationSurfaceEditSheet.swift
//  Domus Arkai
//
//  Sheet per modificare la metratura usata per il calcolo della stima.
//  Default = surfaceCommercial dell'immobile. L'utente può fare ipotesi
//  su un appartamento di metratura diversa.
//

import SwiftUI

struct RenovationSurfaceEditSheet: View {
    @Bindable var model: RenovationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftSurface: Double = 80

    var body: some View {
        NavigationStack {
            ZStack {
                ADColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: ADSpacing.s5) {
                    intro

                    surfaceDisplay

                    slider

                    Spacer()

                    actionButtons
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s4)
                .padding(.bottom, ADSpacing.s5)
            }
            .navigationTitle("Metratura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .onAppear {
                draftSurface = model.workingSurface
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Modifica la metratura")
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
            Text("La superficie da ristrutturare può differire dalla commerciale dell'immobile (es. solo zona giorno, esclusione di balconi).")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var surfaceDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(Int(draftSurface))")
                .font(.system(size: 64, weight: .bold).monospacedDigit())
                .foregroundStyle(ADColor.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("mq")
                .font(ADTypography.priceMedium.weight(.semibold))
                .foregroundStyle(ADColor.primarySoft)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, ADSpacing.s3)
    }

    private var slider: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Slider(
                value: $draftSurface,
                in: 20...500,
                step: 5
            )
            .tint(ADColor.primarySoft)

            HStack {
                Text("20 mq")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
                Spacer()
                Text("500 mq")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textLight)
            }

            if abs(draftSurface - model.propertySurface) > 1 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        draftSurface = model.propertySurface
                    }
                } label: {
                    HStack(spacing: ADSpacing.s2) {
                        Image(systemName: "arrow.uturn.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Reimposta a \(Int(model.propertySurface)) mq (immobile)")
                            .font(ADTypography.metadata.weight(.medium))
                    }
                    .foregroundStyle(ADColor.primarySoft)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionButtons: some View {
        Button {
            // Se l'utente lascia la metratura uguale all'immobile, niente override
            if abs(draftSurface - model.propertySurface) < 1 {
                model.surfaceOverride = nil
            } else {
                model.surfaceOverride = draftSurface
            }
            dismiss()
        } label: {
            Text("Applica")
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .fill(ADColor.primary)
                )
        }
        .buttonStyle(.plain)
    }
}
