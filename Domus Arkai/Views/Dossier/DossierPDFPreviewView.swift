//
//  DossierPDFPreviewView.swift
//  Domus Arkai
//
//  Anteprima del PDF "Scheda completa" + ShareLink per salvare/condividere.
//

import SwiftUI
import PDFKit

struct DossierPDFPreviewView: View {
    let property: Property
    let dossier: PropertyDossier
    let userDisplayName: String

    @State private var pdfData: Data?
    @State private var fileURL: URL?
    @State private var phase: Phase = .generating

    @Environment(\.dismiss) private var dismiss

    enum Phase: Equatable {
        case generating
        case ready
        case failed
    }

    private var suggestedFileName: String {
        let title = property.title.prefix(40)
        return "Dossier_\(title)"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                content

                if phase == .ready, let url = fileURL {
                    shareBar(url: url)
                }
            }
            .navigationTitle("Scheda completa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                await generate()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .generating:
            VStack(spacing: ADSpacing.s3) {
                ProgressView().tint(ADColor.primarySoft)
                Text("Composizione del documento…")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready:
            if let data = pdfData {
                PDFPreview(data: data)
                    .padding(.bottom, 100)
            }

        case .failed:
            VStack(spacing: ADSpacing.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundStyle(ADColor.warning)
                Text("Impossibile generare il documento")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                Button("Riprova") { Task { await generate() } }
                    .buttonStyle(.adSecondary(fullWidth: false))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func shareBar(url: URL) -> some View {
        VStack(spacing: ADSpacing.s2) {
            ShareLink(item: url) {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Salva o condividi PDF")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: ADRadius.md).fill(ADColor.primarySoft)
                )
                .foregroundStyle(.white)
                .font(ADTypography.bodyMedium.weight(.semibold))
            }
            .buttonStyle(.plain)

            Text("Il file viene salvato sul tuo dispositivo. Puoi condividerlo via email, AirDrop o messaggio.")
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

    private func generate() async {
        phase = .generating
        let data = await DossierPDFRenderer.render(
            property: property,
            dossier: dossier,
            userDisplayName: userDisplayName
        )
        guard let data else {
            phase = .failed
            return
        }
        let url = DossierPDFRenderer.writeToTemporaryFile(data: data, suggestedName: suggestedFileName)
        pdfData = data
        fileURL = url
        phase = .ready
    }
}

// MARK: - PDFKit bridge

private struct PDFPreview: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
