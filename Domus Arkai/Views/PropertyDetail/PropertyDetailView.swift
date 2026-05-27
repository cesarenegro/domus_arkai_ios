//
//  PropertyDetailView.swift
//  Domus Arkai
//
//  Spec: `04_ios_property_detail.json`. Premium dossier, image-led.
//  Layout: hero overlay + scroll content + CTA bar glassmorphism flottante.
//  Gerarchia CTA: 1 primary "Prenota visita" (sticky) + 2 secondary inline (Mutuo, Ristrutturazione).
//

import SwiftUI
import Auth
import Helpers

struct PropertyDetailView: View {
    let property: Property

    @State private var model: PropertyDetailViewModel
    @State private var showGallery: Bool = false
    @State private var showFloorplan2D: Bool = false
    @State private var showFloorplan3D: Bool = false
    @State private var showVisitBooking: Bool = false
    @State private var showMortgage: Bool = false
    @State private var showValuation: Bool = false
    @State private var showRenovation: Bool = false
    @State private var showVisualBOQ: Bool = false
    @State private var showPaywall: Bool = false
    @State private var visualBOQModel: VisualBOQViewModel?
    @State private var subscription = SubscriptionService.shared
    @State private var dossierVM: PropertyDossierViewModel
    @State private var auth = AuthService.shared
    @State private var showPDFPreview: Bool = false
    @State private var showDossierLoginRequired: Bool = false
    @State private var isQuickSavingDossier: Bool = false
    @State private var dossierJustAdded: Bool = false

    @Environment(\.dismiss) private var dismiss

    init(property: Property) {
        self.property = property
        _model = State(initialValue: PropertyDetailViewModel(property: property))
        _dossierVM = State(initialValue: PropertyDossierViewModel(property: property))
    }

    private let heroHeight: CGFloat = 320

    var body: some View {
        ZStack(alignment: .bottom) {
            ADColor.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: ADSpacing.s5) {
                    heroSection
                        .containerRelativeFrame(.horizontal)
                    priceTitleHeader
                    mainSpecsRow
                    spatialStagingSection
                    descriptionSection
                    mediaSection
                    actionEntries
                    dossierSection
                    technicalDetails
                }
                .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)

            stickyCtaBar
        }
        .navigationTitle(property.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await handleQuickAddToDossier() }
                } label: {
                    if isQuickSavingDossier {
                        ProgressView()
                    } else {
                        Image(systemName: hasDossierForThisProperty ? "folder.fill" : "folder.badge.plus")
                            .foregroundStyle(hasDossierForThisProperty ? ADColor.primarySoft : ADColor.primary)
                    }
                }
                .disabled(isQuickSavingDossier)
            }
        }
        .task {
            await model.load()
            if auth.isAuthenticated, dossierVM.dossier == nil {
                await dossierVM.load()
            }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth { Task { await dossierVM.load() } }
        }
        .sheet(isPresented: $showGallery) {
            PropertyGalleryView(media: model.media)
        }
        .sheet(isPresented: $showFloorplan2D) {
            if let floorplan = model.floorplan2D {
                PropertyFloorplan2DView(property: property, floorplan: floorplan)
            }
        }
        .sheet(isPresented: $showFloorplan3D) {
            if let floorplan = model.floorplan3D {
                PropertyFloorplan3DView(property: property, floorplan: floorplan)
            }
        }
        .sheet(isPresented: $showMortgage) {
            MortgageFormView(model: MortgageViewModel(property: property))
        }
        .sheet(isPresented: $showValuation) {
            PropertyValuationView(model: PropertyValuationViewModel(property: property))
        }
        .sheet(isPresented: $showRenovation) {
            RenovationSelectionView(model: RenovationViewModel(property: property))
        }
        .sheet(isPresented: $showVisitBooking) {
            VisitBookingView(model: VisitBookingViewModel(property: property))
        }
        .sheet(isPresented: $showPaywall) {
            ArkaiProPaywallView(onActivated: {
                // Riprendi il flow originale appena attivato PRO
                print("🟢 [VisionPRO][Detail] paywall activated → resuming VisualBOQ flow")
                visualBOQModel = VisualBOQViewModel(property: property)
                showVisualBOQ = true
            })
        }
        .sheet(isPresented: $showVisualBOQ) {
            if let visualBOQModel {
                VisualBOQCaptureView(model: visualBOQModel)
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let dossier = dossierVM.dossier {
                DossierPDFPreviewView(
                    property: property,
                    dossier: dossier,
                    userDisplayName: pdfUserDisplayName
                )
            }
        }
        .sheet(isPresented: $showDossierLoginRequired) {
            LoginRequiredSheet(
                actionTitle: "Aggiungi al mio Dossier",
                reason: "Per conservare questo immobile nel tuo Dossier e iniziare a costruire le tue stime, accedi al tuo profilo riservato.",
                onGoToProfile: nil
            )
        }
        .overlay(alignment: .top) {
            if dossierJustAdded {
                dossierAddedToast
            }
        }
    }

    private var hasDossierForThisProperty: Bool {
        dossierVM.dossier != nil
    }

    private func handleQuickAddToDossier() async {
        print("🟢 [Dossier][Detail] tap 'Aggiungi al mio Dossier' — isAuth=\(auth.isAuthenticated), exists=\(hasDossierForThisProperty)")
        guard auth.isAuthenticated else {
            showDossierLoginRequired = true
            return
        }
        if hasDossierForThisProperty { return }
        isQuickSavingDossier = true
        defer { isQuickSavingDossier = false }
        do {
            _ = try await dossierVM.quickSave()
            withAnimation(.spring(duration: 0.3)) { dossierJustAdded = true }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeOut(duration: 0.3)) { dossierJustAdded = false }
        } catch {
            print("🔴 [Dossier][Detail] quickSave failed — \(error)")
        }
    }

    private var dossierAddedToast: some View {
        HStack(spacing: ADSpacing.s2) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .semibold))
            Text("Aggiunto al tuo Dossier")
                .font(ADTypography.smallMedium.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, ADSpacing.s4)
        .padding(.vertical, ADSpacing.s3)
        .background(Capsule().fill(ADColor.primary))
        .padding(.top, ADSpacing.s5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var pdfUserDisplayName: String {
        if let user = auth.currentUser {
            if let name = user.userMetadata["full_name"]?.stringValue, !name.isEmpty {
                return name
            }
            if let email = user.email, let prefix = email.split(separator: "@").first {
                return String(prefix)
            }
        }
        return "Utente Arkai Domus"
    }

    private func openVisualBOQ() {
        print("🟢 [Vision][Detail] tap 'Analizza una stanza' — isAuth=\(auth.isAuthenticated), remaining=\(subscription.visionRemainingThisMonth)/\(SubscriptionService.monthlyVisionQuota)")
        // Gate: serve login + quota disponibile.
        // Se manca uno dei due → apri info sheet che guida l'utente.
        if !auth.isAuthenticated || !subscription.canUseVisionAnalysis {
            showPaywall = true
            return
        }
        print("🟢 [Vision][Detail] quota OK → presenting VisualBOQCaptureView")
        visualBOQModel = VisualBOQViewModel(property: property)
        showVisualBOQ = true
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: property.coverImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty:
                    ADColor.surfaceSoft.overlay(ProgressView().tint(ADColor.primarySoft))
                default:
                    ADColor.surfaceSoft
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: heroHeight)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: ADRadius.panel,
                bottomTrailingRadius: ADRadius.panel,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
    }

    private var priceTitleHeader: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(property.formattedPrice)
                .font(ADTypography.priceLarge)
                .foregroundStyle(ADColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(property.title)
                .font(ADTypography.pageTitle)
                .foregroundStyle(ADColor.primary)
                .lineLimit(2)
            Text(property.locationLine)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .lineLimit(1)

            if let agency = model.agency {
                NavigationLink(value: agency) {
                    HStack(spacing: ADSpacing.s2) {
                        Image(systemName: "building.2")
                            .font(.system(size: 11, weight: .medium))
                        Text("Pubblicato da \(agency.name)")
                            .font(ADTypography.metadata.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(ADColor.primarySoft)
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var mainSpecsRow: some View {
        HStack(spacing: ADSpacing.s2) {
            if let sqm = property.surfaceCommercial {
                SpecCard(icon: "ruler", value: "\(Int(sqm))", label: "mq")
            }
            if let r = property.rooms {
                SpecCard(icon: "square.split.2x2", value: "\(r)", label: r == 1 ? "locale" : "locali")
            }
            if let b = property.bathrooms {
                SpecCard(icon: "shower", value: "\(b)", label: b == 1 ? "bagno" : "bagni")
            }
            if let e = property.energyClass {
                SpecCard(icon: "leaf", value: e.rawValue, label: "Classe")
            }
        }
    }

    @ViewBuilder
    private var spatialStagingSection: some View {
        if let scan = model.primaryStagingScan {
            SpatialStagingCard(scan: scan)
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let desc = property.descriptionShort, !desc.isEmpty {
            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                Text("Descrizione")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                Text(desc)
                    .font(ADTypography.body)
                    .foregroundStyle(ADColor.text)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            HStack {
                Text("Esplora gli spazi")
                    .font(ADTypography.sectionTitle)
                    .foregroundStyle(ADColor.primary)
                Spacer()
            }

            HStack(spacing: ADSpacing.s3) {
                mediaCard(
                    icon: "photo.on.rectangle.angled",
                    title: "Gallery",
                    subtitle: "\(model.media.count) foto",
                    image: model.media.first?.url,
                    action: { showGallery = true }
                )
                mediaCard(
                    icon: "ruler",
                    title: "Planimetria",
                    subtitle: "Vista 2D",
                    image: model.floorplan2D?.url,
                    action: { showFloorplan2D = true }
                )
            }

            if let plan3D = model.floorplan3D {
                Button {
                    showFloorplan3D = true
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: plan3D.previewImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                ADColor.surfaceSoft
                            }
                        }
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vista 3D")
                                    .font(ADTypography.cardTitle)
                                    .foregroundStyle(ADColor.primary)
                                    .lineLimit(1)
                                Text("Anteprima architettonica")
                                    .font(ADTypography.metadata)
                                    .foregroundStyle(ADColor.textMuted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: ADSpacing.s2)
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(ADColor.primary)
                        }
                        .padding(ADSpacing.s4)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: ADRadius.card)
                            .stroke(ADColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func mediaCard(
        icon: String,
        title: String,
        subtitle: String,
        image: URL?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: image) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        ADColor.surfaceSoft
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ADSpacing.s1) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundStyle(ADColor.primarySoft)
                        Text(title)
                            .font(ADTypography.smallMedium)
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                    }
                    Text(subtitle)
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .lineLimit(1)
                }
                .padding(ADSpacing.s3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dossierSection: some View {
        if let dossier = dossierVM.dossier, hasAnyDossierEntry(dossier) {
            DossierSummaryCard(dossier: dossier, onTapPrint: {
                showPDFPreview = true
            })
        }
    }

    private func hasAnyDossierEntry(_ d: PropertyDossier) -> Bool {
        d.avmEstimatedTotal != nil
            || d.mortgageMonthlyPayment != nil
            || d.renovationTotal != nil
            || d.visualBOQTotal != nil
    }

    private var actionEntries: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Strumenti")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            // Card protagonista: AVM (valutazione di zona)
            Button {
                showValuation = true
            } label: {
                HStack(alignment: .top, spacing: ADSpacing.s3) {
                    Image(systemName: "location.viewfinder")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(ADColor.primaryLight)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Valuta questo immobile")
                            .font(ADTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Confronta con i prezzi di riferimento della zona")
                            .font(ADTypography.metadata)
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ADSpacing.Card.paddingLarge)
                .background(ADColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
            }
            .buttonStyle(.plain)

            HStack(spacing: ADSpacing.s3) {
                ActionEntryCard(
                    icon: "function",
                    title: "Calcola mutuo",
                    subtitle: "Stima rata e sostenibilità",
                    action: { showMortgage = true }
                )
                ActionEntryCard(
                    icon: "hammer",
                    title: "Stima ristrutturazione",
                    subtitle: "Lavori e costi indicativi",
                    action: { showRenovation = true }
                )
            }

            visualBOQEntryCard
        }
    }

    private var visualBOQEntryCard: some View {
        Button(action: openVisualBOQ) {
            HStack(alignment: .top, spacing: ADSpacing.s3) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(ADColor.primarySoft)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ADColor.primaryLight.opacity(0.5)))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: ADSpacing.s2) {
                        Text("Analizza una stanza")
                            .font(ADTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(ADColor.primary)
                            .lineLimit(1)
                        proBadge
                    }
                    Text("Stima dei lavori dalle foto · Arkai Vision Pro")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(ADColor.textLight)
                    .font(.system(size: 13, weight: .semibold))
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
        .buttonStyle(.plain)
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .tracking(0.8)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(ADColor.primary)
            )
    }

    private var technicalDetails: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("Dati tecnici")
                .font(ADTypography.sectionTitle)
                .foregroundStyle(ADColor.primary)

            VStack(spacing: 0) {
                if let type = property.propertyType { row("Tipologia", type.displayName) }
                if let contract = property.contractType { row("Contratto", contract.displayName) }
                if let s = property.surfaceCommercial { row("Superficie", "\(Int(s)) mq") }
                if let r = property.rooms { row("Locali", "\(r)") }
                if let bed = property.bedrooms { row("Camere", "\(bed)") }
                if let b = property.bathrooms { row("Bagni", "\(b)") }
                if let floor = property.floor { row("Piano", floor) }
                if property.hasElevator { row("Ascensore", "Sì") }
                if property.hasTerrace { row("Terrazza", "Sì") }
                if property.hasBalcony { row("Balcone", "Sì") }
                if property.hasGarden { row("Giardino", "Sì") }
                if property.hasGarage { row("Box", "Sì") }
                if let e = property.energyClass { row("Classe energetica", e.rawValue) }
                if let c = property.conditionStatus { row("Stato", c, isLast: true) }
            }
            .background(ADColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ADRadius.card)
                    .stroke(ADColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        }
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
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
            if !isLast {
                Divider().overlay(ADColor.border.opacity(0.6))
            }
        }
    }

    // MARK: - Sticky CTA bar

    private var stickyCtaBar: some View {
        HStack(spacing: ADSpacing.s2) {
            Button {
                // share placeholder
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ADColor.primary)
                    .frame(width: 44, height: 44)
                    .background(ADColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ADRadius.md)
                            .stroke(ADColor.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ADRadius.md))
            }
            .buttonStyle(.plain)

            Button {
                showVisitBooking = true
            } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Prenota visita")
                        .font(ADTypography.smallMedium.weight(.semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, ADSpacing.s5)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: ADRadius.md)
                        .fill(ADColor.primarySoft)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.vertical, ADSpacing.s3)
        .background(
            ADColor.surface
                .overlay(
                    Rectangle()
                        .fill(ADColor.border.opacity(0.4))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

}
#Preview("Attico Brera") {
    NavigationStack {
        PropertyDetailView(property: Property.preview)
    }
}

#Preview("Villa con giardino") {
    NavigationStack {
        PropertyDetailView(property: Property.previewVilla)
    }
}

// MARK: - Preview data

extension Property {
    static var preview: Property {
        Property(
            id: UUID(),
            agencyID: UUID(),
            title: "Attico in Brera",
            descriptionShort: "Attico panoramico con terrazza vista Duomo, finiture sartoriali e luce naturale tutto il giorno. Ristrutturato di recente con materiali di pregio e impianti certificati di ultima generazione.",
            descriptionLong: nil,
            propertyType: .attico,
            contractType: .vendita,
            price: 780_000,
            city: "Milano",
            area: "Brera",
            addressPublic: "Via Brera",
            latitude: 45.4716,
            longitude: 9.1879,
            surfaceCommercial: 120,
            surfaceInternal: 110,
            rooms: 3,
            bedrooms: 2,
            bathrooms: 2,
            floor: "5",
            totalFloors: 6,
            hasElevator: true,
            hasBalcony: false,
            hasTerrace: true,
            hasGarden: false,
            hasGarage: false,
            hasParking: false,
            hasCellar: true,
            conditionStatus: "Ristrutturato",
            energyClass: .a2,
            publishedStatus: .online,
            isFeatured: true,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80")
        )
    }

    static var previewVilla: Property {
        Property(
            id: UUID(),
            agencyID: UUID(),
            title: "Villa con giardino",
            descriptionShort: "Villa singola con giardino privato e box doppio, zona residenziale tranquilla a pochi passi dal centro.",
            descriptionLong: nil,
            propertyType: .villa,
            contractType: .vendita,
            price: 1_350_000,
            city: "Milano",
            area: "San Siro",
            addressPublic: "Via Novara",
            latitude: 45.4781,
            longitude: 9.1232,
            surfaceCommercial: 230,
            surfaceInternal: 210,
            rooms: 5,
            bedrooms: 4,
            bathrooms: 3,
            floor: "T",
            totalFloors: 2,
            hasElevator: false,
            hasBalcony: false,
            hasTerrace: true,
            hasGarden: true,
            hasGarage: true,
            hasParking: true,
            hasCellar: true,
            conditionStatus: "Ottimo",
            energyClass: .a1,
            publishedStatus: .online,
            isFeatured: true,
            coverImageURL: URL(string: "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80")
        )
    }
}

