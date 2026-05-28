//
//  ProfessionalModeView.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — menu centralizzato per agenti/admin/super_admin.
//  Raggruppa tutte le funzioni "professionali" accessibili da un unico punto.
//
//  Accesso: voce "Modalità professionale" in ProfileView, visibile solo per
//  ruoli super_admin/agency_admin/agent + device con LiDAR.
//

import SwiftUI
import RoomPlan

struct ProfessionalModeView: View {
    let agencyRole: AgencyRole?

    @State private var showScanFlow: Bool = false
    @State private var showARDemo: Bool = false
    @State private var demoErrorMessage: String?

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: ADSpacing.s4) {
                    header
                    primaryActions
                    infoCards
                    Color.clear.frame(height: ADSpacing.s6)
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.top, ADSpacing.s3)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Modalità professionale")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showScanFlow) {
            RoomScanFlowView()
        }
        .fullScreenCover(isPresented: $showARDemo) {
            if let url = USDZDownloader.bundledDemoURL() {
                ARQuickLookPresenter(localFileURL: url)
                    .ignoresSafeArea()
            }
        }
        .alert("Demo AR non disponibile", isPresented: Binding(
            get: { demoErrorMessage != nil },
            set: { if !$0 { demoErrorMessage = nil } }
        )) {
            Button("OK") { demoErrorMessage = nil }
        } message: {
            Text(demoErrorMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s2) {
                Text("RUOLO")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(ADColor.accentWarm)
                if let role = agencyRole {
                    Text(role.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ADColor.background)
                        .padding(.horizontal, ADSpacing.s2)
                        .padding(.vertical, 3)
                        .background(ADColor.primary)
                        .clipShape(Capsule())
                }
            }
            Text("Strumenti scansione 3D")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            Text("Crea scansioni RoomPlan degli immobili in gestione. La pipeline server genera in pochi minuti l'arredo USDZ pronto per la visualizzazione AR del cliente.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, ADSpacing.s2)
    }

    // MARK: - Primary actions

    @ViewBuilder
    private var primaryActions: some View {
        if RoomCaptureSession.isSupported {
            actionRow(
                icon: "cube.transparent.fill",
                tint: ADColor.accentWarm,
                title: "Nuova scansione 3D",
                subtitle: "Avvia il flusso RoomPlan e carica un immobile",
                accent: true
            ) {
                showScanFlow = true
            }
        } else {
            unsupportedHardwareNote
        }

        NavigationLink {
            MyScansListView()
        } label: {
            actionRowLabel(
                icon: "list.bullet.rectangle.portrait",
                tint: ADColor.primarySoft,
                title: "Le mie scansioni",
                subtitle: "Storico, status pipeline, USDZ pronti",
                accent: false
            )
        }
        .buttonStyle(.plain)

        actionRow(
            icon: "arkit",
            tint: ADColor.primary,
            title: "Prova AR demo",
            subtitle: "Apri AR Quick Look col modello USDZ bundlato (test rapido)",
            accent: false
        ) {
            if USDZDownloader.bundledDemoURL() != nil {
                showARDemo = true
            } else {
                demoErrorMessage = "File `demo_room.usdz` non bundlato. Aggiungilo al target Xcode per testare l'AR Quick Look."
            }
        }
    }

    private func actionRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        accent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionRowLabel(icon: icon, tint: tint, title: title, subtitle: subtitle, accent: accent)
        }
        .buttonStyle(.plain)
    }

    private func actionRowLabel(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        accent: Bool
    ) -> some View {
        HStack(spacing: ADSpacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ADColor.textLight)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(accent ? ADColor.accentWarm.opacity(0.4) : ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var unsupportedHardwareNote: some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 18))
                .foregroundStyle(ADColor.textLight)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Hardware non supportato")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Text("La scansione 3D richiede un iPhone Pro o iPad Pro con sensore LiDAR.")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    // MARK: - Info cards

    private var infoCards: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("COME FUNZIONA")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
                .padding(.top, ADSpacing.s3)

            infoRow(step: "01", title: "Scansiona", body: "Cammina lentamente lungo le pareti con il LiDAR attivo.")
            infoRow(step: "02", title: "Carica", body: "Dai un nome alla scansione e associa a un immobile esistente oppure creane uno nuovo.")
            infoRow(step: "03", title: "Aspetta", body: "La pipeline server genera l'arredo USDZ \"Minimal Premium\". Riceverai una notifica push.")
            infoRow(step: "04", title: "Visualizza AR", body: "L'immobile mostra al cliente la card \"Spatial Staging\" per il walkthrough 1:1.")
        }
    }

    private func infoRow(step: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Text(step)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(ADColor.accentWarm)
                .frame(width: 26, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Text(body)
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack {
        ProfessionalModeView(agencyRole: .superAdmin)
    }
}
