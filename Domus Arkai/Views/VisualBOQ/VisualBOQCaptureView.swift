//
//  VisualBOQCaptureView.swift
//  Domus Arkai
//
//  Arkai Vision Pro — schermata di acquisizione foto stanza + parametri.
//  Brand safety: mostriamo SOLO label brand-safe dei difficulty factor, mai % o multiplier.
//  Modello AI sempre identificato come "Arkai Vision Pro" — mai citare fornitori esterni.
//

import SwiftUI
import PhotosUI

struct VisualBOQCaptureView: View {
    @Bindable var model: VisualBOQViewModel
    @State private var subscription = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showResult: Bool = false

    private let maxPhotos = 3

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ADColor.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                        introCard
                        quotaCard
                        photosSection
                        roomTypeSection
                        locationSection
                        difficultySection
                        privacyNote
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s3)
                    .padding(.bottom, 130)
                }
                .scrollIndicators(.hidden)

                stickyAnalyzeBar
            }
            .navigationTitle("Arkai Vision Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(ADColor.primary)
                }
            }
            .task {
                if model.availableDifficultyFactors.isEmpty {
                    await model.loadDifficultyFactors()
                }
            }
            .onChange(of: pickerItems) { _, newItems in
                Task { await loadImages(from: newItems) }
            }
            .onChange(of: model.phase) { _, newPhase in
                if case .result = newPhase {
                    showResult = true
                }
            }
            .sheet(isPresented: $showResult, onDismiss: {
                model.resetToCapture()
                pickerItems = []
            }) {
                VisualBOQResultView(model: model)
            }
            .overlay {
                if model.phase == .analyzing {
                    analyzingOverlay
                }
            }
            .alert("Analisi non riuscita", isPresented: errorBinding) {
                Button("OK", role: .cancel) { model.resetToCapture() }
            } message: {
                Text(currentErrorMessage)
            }
        }
    }

    // MARK: - Sections

    private var introCard: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            HStack(spacing: ADSpacing.s2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("ARKAI PRO")
                    .font(ADTypography.metadata.weight(.semibold))
                    .tracking(1.2)
            }
            .foregroundStyle(ADColor.primaryLight)

            Text("Analizza una stanza dalle foto.")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(.white)

            Text("Carica fino a 3 foto dell'ambiente, indica la tipologia e gli aspetti logistici: ti restituiamo una stima dei lavori e dei costi indicativi.")
                .font(ADTypography.small)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.Card.paddingLarge)
        .background(ADColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var quotaCard: some View {
        let remaining = subscription.visionRemainingThisMonth
        let total = SubscriptionService.monthlyVisionQuota
        let isEmpty = remaining <= 0
        return HStack(spacing: ADSpacing.s3) {
            Image(systemName: isEmpty ? "hourglass" : "checkmark.seal")
                .font(.system(size: 16))
                .foregroundStyle(isEmpty ? ADColor.warning : ADColor.primarySoft)
            VStack(alignment: .leading, spacing: 2) {
                Text(isEmpty ? "Quota mensile esaurita" : "\(remaining) di \(total) analisi residue questo mese")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(1)
                Text("Servizio gratuito incluso dall'agenzia. Reset il primo del mese.")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.Card.paddingSmall)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(isEmpty ? ADColor.warning.opacity(0.4) : ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private var photosSection: some View {
        let images = model.selectedImages
        let hasImages = !images.isEmpty
        return VStack(alignment: .leading, spacing: ADSpacing.s3) {
            sectionTitle("Foto della stanza", caption: "Fino a \(maxPhotos) immagini ben illuminate.")

            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: maxPhotos,
                matching: .images,
                photoLibrary: .shared()
            ) {
                if hasImages {
                    photosGrid(images: images)
                } else {
                    emptyPhotoPlaceholder
                }
            }
            .buttonStyle(.plain)

            if hasImages {
                Button {
                    model.selectedImages.removeAll()
                    pickerItems.removeAll()
                } label: {
                    HStack(spacing: ADSpacing.s2) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Sostituisci foto")
                            .font(ADTypography.smallMedium)
                    }
                    .foregroundStyle(ADColor.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyPhotoPlaceholder: some View {
        VStack(spacing: ADSpacing.s3) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(ADColor.primarySoft)
            Text("Tocca per selezionare le foto")
                .font(ADTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(ADColor.primary)
            Text("JPEG o HEIC, massimo \(maxPhotos) immagini.")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ADSpacing.s7)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .strokeBorder(ADColor.border, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
    }

    private func photosGrid(images: [UIImage]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: ADSpacing.s2),
            GridItem(.flexible(), spacing: ADSpacing.s2),
            GridItem(.flexible(), spacing: ADSpacing.s2)
        ]
        return LazyVGrid(columns: columns, spacing: ADSpacing.s2) {
            ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ADRadius.md)
                            .stroke(ADColor.border, lineWidth: 1)
                    )
            }
        }
    }

    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            sectionTitle("Tipologia ambiente", caption: nil)
            HStack(spacing: ADSpacing.s2) {
                ForEach(VisualBOQService.RoomType.allCases, id: \.self) { type in
                    FilterPill(
                        label: type.displayName,
                        isSelected: model.roomType == type
                    ) {
                        model.roomType = type
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            sectionTitle("Comune di riferimento", caption: "Pre-compilato dalla scheda immobile.")
            HStack(spacing: ADSpacing.s3) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(ADColor.primarySoft)
                    .font(.system(size: 18))
                Text(model.city.isEmpty ? "—" : model.city)
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ADSpacing.Card.paddingSmall)
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
    }

    @ViewBuilder
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            sectionTitle("Aspetti logistici di cantiere", caption: "Seleziona quelli pertinenti: integrati nella pianificazione dei costi.")
            if model.availableDifficultyFactors.isEmpty {
                ProgressView()
                    .tint(ADColor.primarySoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ADSpacing.s5)
            } else {
                FlowDifficultyLayout(spacing: ADSpacing.s2) {
                    ForEach(model.availableDifficultyFactors) { factor in
                        FilterPill(
                            label: factor.label,
                            isSelected: model.isDifficultySelected(factor)
                        ) {
                            model.toggleDifficulty(factor)
                        }
                    }
                }
            }
        }
    }

    private var privacyNote: some View {
        Text("Le immagini caricate vengono inviate in forma riservata ai sistemi di analisi Arkai Vision Pro e utilizzate esclusivamente per generare la tua stima. Le stime hanno valore indicativo e non sostituiscono il giudizio di un tecnico abilitato.")
            .font(ADTypography.metadata)
            .foregroundStyle(ADColor.textLight)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ADSpacing.s2)
    }

    // MARK: - Sticky bar + overlays

    private var stickyAnalyzeBar: some View {
        VStack(spacing: ADSpacing.s2) {
            Button {
                Task { await model.analyze() }
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    if model.phase == .analyzing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(model.phase == .analyzing ? "Analisi in corso…" : "Analizza")
                }
            }
            .buttonStyle(.adPrimary)
            .disabled(!model.canAnalyze)
            .opacity(model.canAnalyze ? 1.0 : 0.55)

            Text(captionText)
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

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()
            VStack(spacing: ADSpacing.s3) {
                ProgressView().tint(ADColor.primarySoft)
                Text("Arkai Vision Pro sta analizzando…")
                    .font(ADTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Text("Pochi istanti.")
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
            }
            .padding(ADSpacing.s6)
            .background(ADColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            .shadow(color: .black.opacity(ADShadow.cardOpacity),
                    radius: ADShadow.cardRadius,
                    x: ADShadow.cardOffset.width,
                    y: ADShadow.cardOffset.height)
        }
        .transition(.opacity)
    }

    // MARK: - Helpers

    private var captionText: String {
        if !subscription.canUseVisionAnalysis {
            return "Quota mensile esaurita — riprova il primo del prossimo mese."
        }
        if model.selectedImages.isEmpty {
            return "Carica almeno una foto per procedere."
        }
        return "Analisi a cura di Arkai Vision Pro."
    }

    private func sectionTitle(_ title: String, caption: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)
            if let caption {
                Text(caption)
                    .font(ADTypography.metadata)
                    .foregroundStyle(ADColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        print("📸 [VisionPRO][Capture] onChange pickerItems — selected=\(items.count)")
        var images: [UIImage] = []
        for (idx, item) in items.prefix(maxPhotos).enumerated() {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    images.append(img)
                    print("📸 [VisionPRO][Capture] loaded photo[\(idx)] — \(data.count / 1024) KB, size=\(Int(img.size.width))x\(Int(img.size.height))")
                } else {
                    print("⚠️ [VisionPRO][Capture] photo[\(idx)] decoding failed (data or UIImage nil)")
                }
            } catch {
                print("🔴 [VisionPRO][Capture] photo[\(idx)] loadTransferable error — \(error)")
            }
        }
        model.selectedImages = images
        print("✅ [VisionPRO][Capture] selectedImages updated — count=\(images.count)")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = model.phase { return true }
                return false
            },
            set: { isPresented in
                if !isPresented { model.resetToCapture() }
            }
        )
    }

    private var currentErrorMessage: String {
        if case .error(let msg) = model.phase { return msg }
        return ""
    }
}

// MARK: - Flow layout per i pill di difficoltà (adaptive)

private struct FlowDifficultyLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentRowWidth + size.width + (rows[rows.count - 1].isEmpty ? 0 : spacing)
            if nextWidth > maxWidth, !rows[rows.count - 1].isEmpty {
                totalHeight += currentRowHeight + spacing
                rows.append([])
                currentRowWidth = 0
                currentRowHeight = 0
            }
            rows[rows.count - 1].append(size)
            currentRowWidth = rows[rows.count - 1].reduce(0) { $0 + $1.width } + CGFloat(rows[rows.count - 1].count - 1) * spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : currentRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    VisualBOQCaptureView(model: VisualBOQViewModel(property: nil))
}
