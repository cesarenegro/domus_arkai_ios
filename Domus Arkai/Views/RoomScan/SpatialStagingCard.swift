//
//  SpatialStagingCard.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — card editorial nel `PropertyDetailView` che invita
//  il cliente ad aprire l'AR Quick Look della scansione "Minimal Premium"
//  dell'immobile. Visibile solo se esiste almeno uno scan `.ready`.
//

import SwiftUI

struct SpatialStagingCard: View {
    let scan: PropertyScan

    @State private var showARSheet: Bool = false
    @State private var isDownloading: Bool = false
    @State private var downloadedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            eyebrow
            titleAndBody
            ctaButton
            if let errorMessage {
                errorLine(errorMessage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s5)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ADColor.accentWarm.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .fullScreenCover(isPresented: $showARSheet) {
            if let downloadedURL {
                ARQuickLookPresenter(localFileURL: downloadedURL)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Subviews

    private var eyebrow: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ADColor.accentWarm)
            Text("SPATIAL STAGING")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
        }
    }

    private var titleAndBody: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text("Vedi l'arredo in scala reale 1:1")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Inquadra il locale con la fotocamera e visualizza la proposta d'arredo \"Minimal Premium\" sovrapposta allo spazio reale.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var ctaButton: some View {
        Button {
            Task { await prepareAndPresent() }
        } label: {
            HStack(spacing: ADSpacing.s2) {
                if isDownloading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arkit")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(isDownloading ? "Preparazione AR…" : "Proietta nello Spazio 1:1")
                    .font(ADTypography.bodyMedium)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(isDownloading ? 0 : 1)
            }
            .padding(.horizontal, ADSpacing.s4)
            .frame(height: 50)
            .background(ADColor.primary)
            .foregroundStyle(ADColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isDownloading || scan.stagingUSDZUrl == nil)
        .padding(.top, ADSpacing.s1)
    }

    private func errorLine(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(ADColor.warning)
            Text(message)
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.warning)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Action

    private func prepareAndPresent() async {
        guard let remote = scan.stagingUSDZUrl else {
            errorMessage = "USDZ non disponibile per questo immobile."
            return
        }
        errorMessage = nil
        isDownloading = true
        defer { isDownloading = false }
        do {
            let local = try await USDZDownloader.download(remote: remote)
            downloadedURL = local
            showARSheet = true
        } catch {
            errorMessage = error.localizedDescription
            print("🔴 [SpatialStagingCard] download failed — \(error.localizedDescription)")
        }
    }
}
