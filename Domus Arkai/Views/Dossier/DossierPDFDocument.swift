//
//  DossierPDFDocument.swift
//  Domus Arkai
//
//  Template SwiftUI per il PDF "Scheda completa" del Dossier (multipagina).
//  Formato A4 portrait (595 × 842 pt). Linguaggio istituzionale, brand-safe.
//  Suddiviso in pagine separate, renderizzate dal DossierPDFRenderer in cascata.
//

import SwiftUI
import UIKit

// MARK: - Page formatter helpers (shared)

enum DossierPDFFormat {
    static let pageSize = CGSize(width: 595, height: 842)
    static let pageMargin: CGFloat = 40

    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    static func euro(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return currencyFormatter.string(from: NSNumber(value: v)) ?? "—"
    }
}

// MARK: - Page 1 · Copertina con hero image

struct DossierPDFCoverPage: View {
    let property: Property
    let dossier: PropertyDossier
    let userDisplayName: String
    let generatedAt: Date
    let heroImage: UIImage?

    private var heroHeight: CGFloat { DossierPDFFormat.pageSize.height * 0.62 }
    private var bottomHeight: CGFloat { DossierPDFFormat.pageSize.height * 0.38 }

    var body: some View {
        VStack(spacing: 0) {
            heroBlock
            bottomBlock
        }
        .frame(width: DossierPDFFormat.pageSize.width,
               height: DossierPDFFormat.pageSize.height,
               alignment: .topLeading)
        .background(ADColor.background)
    }

    private var heroBlock: some View {
        heroImageView
            .frame(width: DossierPDFFormat.pageSize.width, height: heroHeight)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.black.opacity(0.0), Color.black.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: heroHeight)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                HStack {
                    brandMark
                    Spacer()
                    documentBadge
                }
                .padding(.horizontal, DossierPDFFormat.pageMargin)
                .padding(.top, 32)
            }
    }

    @ViewBuilder
    private var heroImageView: some View {
        if let img = heroImage {
            // L'immagine arriva già center-cropata al ratio esatto del frame:
            // basta resizable senza aspectRatio/clipped (che davano bitmap nero in ImageRenderer).
            Image(uiImage: img)
                .resizable()
                .frame(width: DossierPDFFormat.pageSize.width, height: heroHeight)
        } else {
            LinearGradient(
                colors: [ADColor.primary, ADColor.primarySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: DossierPDFFormat.pageSize.width, height: heroHeight)
        }
    }

    private var brandMark: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(.white)
                .frame(width: 18, height: 2)
            Text("ARKAI DOMUS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3)
                .foregroundStyle(.white)
        }
    }

    private var documentBadge: some View {
        Text("DOSSIER · SCHEDA COMPLETA")
            .font(.system(size: 8, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().stroke(.white.opacity(0.6), lineWidth: 0.7))
    }

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(property.title)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(property.locationLine)
                    .font(.system(size: 12))
                    .foregroundStyle(ADColor.textMuted)
                if let price = property.price {
                    Text(DossierPDFFormat.euro(price))
                        .font(.system(size: 24, weight: .semibold).monospacedDigit())
                        .foregroundStyle(ADColor.primary)
                }
            }

            Spacer(minLength: 0)

            Rectangle()
                .fill(ADColor.border)
                .frame(height: 0.6)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DOCUMENTO RISERVATO A")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(ADColor.textLight)
                    Text(userDisplayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ADColor.text)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("GENERATA IL")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(ADColor.textLight)
                    Text(DossierPDFFormat.dateFormatter.string(from: generatedAt))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ADColor.text)
                }
            }
        }
        .padding(.horizontal, DossierPDFFormat.pageMargin)
        .padding(.vertical, 24)
        .frame(width: DossierPDFFormat.pageSize.width, height: bottomHeight, alignment: .topLeading)
        .background(ADColor.background)
    }
}

// MARK: - Page 2 · Sintesi (immobile + investimento + 5 sotto-totali + mappa+floorplan a destra)

struct DossierPDFSummaryPage: View {
    let property: Property
    let dossier: PropertyDossier
    let pageNumber: Int
    let totalPages: Int
    var mapSnapshot: UIImage? = nil
    var floorplanImage: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DossierPDFHeader(pageNumber: pageNumber, totalPages: totalPages, title: "Sintesi")

            propertyFacts

            // Layout 2 colonne: a sinistra investimento + summary rows, a destra mappa+floorplan
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 16) {
                    investmentBlock
                    summaryRows
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                rightColumn
                    .frame(width: 200)
            }

            Spacer(minLength: 0)
            DossierPDFFooter()
        }
        .padding(DossierPDFFormat.pageMargin)
        .frame(width: DossierPDFFormat.pageSize.width,
               height: DossierPDFFormat.pageSize.height,
               alignment: .topLeading)
        .background(ADColor.background)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            mapBlock
            floorplanBlock
        }
    }

    @ViewBuilder
    private var mapBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            DossierPDFSectionLabel("LOCALIZZAZIONE")
            if let snap = mapSnapshot {
                Image(uiImage: snap)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 140)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(ADColor.border, lineWidth: 0.5)
                    )
            } else {
                placeholder(label: "Mappa non disponibile", icon: "map", height: 140)
            }
            if !property.locationLine.isEmpty {
                Text(property.locationLine)
                    .font(.system(size: 9))
                    .foregroundStyle(ADColor.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var floorplanBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            DossierPDFSectionLabel("PLANIMETRIA")
            if let img = floorplanImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .background(ADColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(ADColor.border, lineWidth: 0.5)
                    )
            } else {
                placeholder(label: "Planimetria non disponibile", icon: "ruler", height: 200)
            }
        }
    }

    private func placeholder(label: String, icon: String, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(ADColor.surfaceSoft)
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(ADColor.textLight)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(ADColor.textLight)
            }
        }
        .frame(width: 200, height: height)
    }

    private var propertyFacts: some View {
        VStack(alignment: .leading, spacing: 10) {
            DossierPDFSectionLabel("L'IMMOBILE")
            HStack(spacing: 24) {
                if let surface = property.surfaceCommercial {
                    DossierPDFFact(label: "Superficie", value: "\(Int(surface)) mq")
                }
                if let rooms = property.rooms {
                    DossierPDFFact(label: "Locali", value: "\(rooms)")
                }
                if let bedrooms = property.bedrooms {
                    DossierPDFFact(label: "Camere", value: "\(bedrooms)")
                }
                if let baths = property.bathrooms {
                    DossierPDFFact(label: "Bagni", value: "\(baths)")
                }
                if let energy = property.energyClass {
                    DossierPDFFact(label: "Classe energetica", value: energy.rawValue)
                }
                Spacer()
            }
            if let cond = property.conditionStatus, !cond.isEmpty {
                Text("Stato conservativo: \(cond)")
                    .font(.system(size: 10))
                    .foregroundStyle(ADColor.textMuted)
            }
        }
    }

    @ViewBuilder
    private var investmentBlock: some View {
        if let total = dossier.totalInvestment {
            VStack(alignment: .leading, spacing: 8) {
                DossierPDFSectionLabel("INVESTIMENTO TOTALE STIMATO", onPrimary: true)
                    .padding(.bottom, 2)
                Text(DossierPDFFormat.euro(total))
                    .font(.system(size: 42, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Prezzo richiesto + ristrutturazione parametrica + analisi visive degli ambienti.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(ADColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var summaryRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            DossierPDFSectionLabel("STIME SALVATE")

            DossierPDFRow(
                label: "Prezzo richiesto dall'agenzia",
                value: DossierPDFFormat.euro(dossier.askingPriceSnapshot),
                tone: .neutral
            )
            DossierPDFRow(
                label: "Valutazione di zona (Arkai Domus)",
                value: DossierPDFFormat.euro(dossier.avmEstimatedTotal),
                detail: dossier.avmEstimatedPerSqm.map { "\(DossierPDFFormat.euro($0)) / mq" },
                tone: .neutral
            )
            DossierPDFRow(
                label: "Mutuo stimato — rata mensile",
                value: dossier.mortgageMonthlyPayment.map { "\(DossierPDFFormat.euro($0)) / mese" } ?? "—",
                tone: .neutral
            )
            DossierPDFRow(
                label: "Ristrutturazione (preventivo parametrico)",
                value: DossierPDFFormat.euro(dossier.renovationTotal),
                detail: renovationRowDetail,
                tone: .accent
            )
            DossierPDFRow(
                label: "Arkai Vision Pro (analisi visiva ambienti)",
                value: DossierPDFFormat.euro(dossier.visualBOQTotal),
                detail: visionRowDetail,
                tone: .accent
            )
        }
    }

    private var renovationRowDetail: String? {
        guard let lines = dossier.renovationItems, !lines.isEmpty else { return nil }
        return "\(lines.count) interventi · dettaglio nelle pagine seguenti"
    }

    private var visionRowDetail: String? {
        guard let ids = dossier.visualBOQEstimateIDs, !ids.isEmpty else { return nil }
        return "\(ids.count) ambient\(ids.count == 1 ? "e analizzato" : "i analizzati")"
    }
}

// MARK: - Page 3 · Dettaglio Ristrutturazione

struct DossierPDFRenovationPage: View {
    let dossier: PropertyDossier
    let pageNumber: Int
    let totalPages: Int

    /// Numero massimo di interventi visualizzati per pagina (cap a 8 per lasciare spazio alla galleria).
    static let maxItemsPerPage: Int = 8

    let items: [DossierRenovationLine]
    let pageIndex: Int
    let totalItemPages: Int
    var galleryImages: [UIImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DossierPDFHeader(pageNumber: pageNumber, totalPages: totalPages, title: "Ristrutturazione")

            VStack(alignment: .leading, spacing: 8) {
                DossierPDFSectionLabel("PREVENTIVO PARAMETRICO")
                if totalItemPages > 1 {
                    Text("Pagina \(pageIndex + 1) di \(totalItemPages) sezioni del preventivo")
                        .font(.system(size: 9))
                        .foregroundStyle(ADColor.textLight)
                }

                tableHeader
                Rectangle().fill(ADColor.border).frame(height: 0.5)

                ForEach(items, id: \.itemID) { line in
                    itemRow(line)
                    Rectangle().fill(ADColor.border.opacity(0.5)).frame(height: 0.3)
                }
            }

            if pageIndex == totalItemPages - 1 {
                difficultyBlock
                totalBlock
                if !galleryImages.isEmpty {
                    galleryBlock
                }
            }

            Spacer(minLength: 0)
            DossierPDFFooter()
        }
        .padding(DossierPDFFormat.pageMargin)
        .frame(width: DossierPDFFormat.pageSize.width,
               height: DossierPDFFormat.pageSize.height,
               alignment: .topLeading)
        .background(ADColor.background)
    }

    @ViewBuilder
    private var galleryBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            DossierPDFSectionLabel("AMBIENTI DELL'IMMOBILE")
            let columns = [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ]
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(galleryImages.prefix(6).enumerated()), id: \.offset) { _, img in
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6).stroke(ADColor.border.opacity(0.4), lineWidth: 0.5)
                        )
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 8) {
            Text("INTERVENTO")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("QTÀ")
                .frame(width: 60, alignment: .trailing)
            Text("UNITARIO")
                .frame(width: 80, alignment: .trailing)
            Text("TOTALE")
                .frame(width: 80, alignment: .trailing)
        }
        .font(.system(size: 8, weight: .semibold))
        .tracking(0.8)
        .foregroundStyle(ADColor.textMuted)
    }

    private func itemRow(_ line: DossierRenovationLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ADColor.text)
                    .lineLimit(2)
                Text("Livello: \(levelLabel(line.level))")
                    .font(.system(size: 8))
                    .foregroundStyle(ADColor.textLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(quantityLabel(line))
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(ADColor.text)
                .frame(width: 60, alignment: .trailing)

            Text(DossierPDFFormat.euro(line.unitPrice))
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(ADColor.textMuted)
                .frame(width: 80, alignment: .trailing)

            Text(DossierPDFFormat.euro(line.lineTotal))
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(ADColor.primary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private func levelLabel(_ level: String) -> String {
        switch level {
        case "essential": "Essenziale"
        case "medium": "Medio"
        case "premium": "Premium"
        default: level.capitalized
        }
    }

    private func quantityLabel(_ line: DossierRenovationLine) -> String {
        let q = String(format: "%g", line.quantity)
        return "\(q)"
    }

    @ViewBuilder
    private var difficultyBlock: some View {
        if let factors = dossier.renovationDifficultyFactors, !factors.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                DossierPDFSectionLabel("COMPLESSITÀ LOGISTICHE CONSIDERATE")
                FlexibleHStack(spacing: 6) {
                    ForEach(factors, id: \.self) { key in
                        Text(brandSafeLabel(for: key))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(ADColor.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(ADColor.primaryLight)
                            )
                    }
                }
                Text("Integrate nella pianificazione dei costi di cantiere.")
                    .font(.system(size: 9))
                    .foregroundStyle(ADColor.textLight)
            }
        }
    }

    private func brandSafeLabel(_ key: String) -> String {
        brandSafeLabel(for: key)
    }

    private func brandSafeLabel(for key: String) -> String {
        switch key {
        case "centro_storico": "Centro Storico"
        case "ztl_access": "ZTL"
        case "piano_alto_no_ascensore": "Piano Alto senza Ascensore"
        case "appartamento_occupato": "Appartamento Occupato"
        case "micro_cantiere_lt40mq": "Micro-cantiere (<40 mq)"
        case "urgenza": "Urgenza / Fast-Track"
        case "venezia_insulare": "Venezia Laguna / Insulare"
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    @ViewBuilder
    private var totalBlock: some View {
        if let total = dossier.renovationTotal {
            HStack {
                Text("Totale ristrutturazione indicativo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ADColor.text)
                Spacer()
                Text(DossierPDFFormat.euro(total))
                    .font(.system(size: 18, weight: .semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(ADColor.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Page 4 · AVM + Mutuo + Visual BOQ details + disclaimer

struct DossierPDFDetailsPage: View {
    let property: Property
    let dossier: PropertyDossier
    let pageNumber: Int
    let totalPages: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DossierPDFHeader(pageNumber: pageNumber, totalPages: totalPages, title: "Dettagli")

            avmBlock
            mortgageBlock
            visualBOQBlock

            Spacer(minLength: 0)
            disclaimerBlock
            DossierPDFFooter()
        }
        .padding(DossierPDFFormat.pageMargin)
        .frame(width: DossierPDFFormat.pageSize.width,
               height: DossierPDFFormat.pageSize.height,
               alignment: .topLeading)
        .background(ADColor.background)
    }

    @ViewBuilder
    private var avmBlock: some View {
        if dossier.avmEstimatedTotal != nil {
            VStack(alignment: .leading, spacing: 6) {
                DossierPDFSectionLabel("VALUTAZIONE DI ZONA")
                if let perSqm = dossier.avmEstimatedPerSqm {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Valore di riferimento al mq")
                            .font(.system(size: 10))
                            .foregroundStyle(ADColor.textMuted)
                        Spacer()
                        Text(DossierPDFFormat.euro(perSqm))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(ADColor.primary)
                    }
                }
                if let total = dossier.avmEstimatedTotal {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Valore totale stimato dell'immobile")
                            .font(.system(size: 10))
                            .foregroundStyle(ADColor.textMuted)
                        Spacer()
                        Text(DossierPDFFormat.euro(total))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(ADColor.primary)
                    }
                }
                Text("Elaborata sulla base dei parametri di mercato di Arkai Domus per l'area di riferimento.")
                    .font(.system(size: 9))
                    .foregroundStyle(ADColor.textLight)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ADColor.border, lineWidth: 0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var mortgageBlock: some View {
        if let payment = dossier.mortgageMonthlyPayment {
            VStack(alignment: .leading, spacing: 6) {
                DossierPDFSectionLabel("MUTUO STIMATO")
                HStack(alignment: .firstTextBaseline) {
                    Text("Rata mensile indicativa")
                        .font(.system(size: 10))
                        .foregroundStyle(ADColor.textMuted)
                    Spacer()
                    Text("\(DossierPDFFormat.euro(payment)) / mese")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(ADColor.primary)
                }
                Text("Stima orientativa; la sottoscrizione richiede l'istruttoria formale di un istituto bancario.")
                    .font(.system(size: 9))
                    .foregroundStyle(ADColor.textLight)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ADColor.border, lineWidth: 0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var visualBOQBlock: some View {
        if let total = dossier.visualBOQTotal, total > 0 {
            VStack(alignment: .leading, spacing: 6) {
                DossierPDFSectionLabel("ARKAI VISION PRO · ANALISI VISIVA")
                if let ids = dossier.visualBOQEstimateIDs, !ids.isEmpty {
                    Text("\(ids.count) ambient\(ids.count == 1 ? "e analizzato" : "i analizzati") tramite il modello visivo Arkai Vision Pro.")
                        .font(.system(size: 10))
                        .foregroundStyle(ADColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Costo complessivo stimato")
                        .font(.system(size: 10))
                        .foregroundStyle(ADColor.textMuted)
                    Spacer()
                    Text(DossierPDFFormat.euro(total))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(ADColor.primary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ADColor.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ADColor.border, lineWidth: 0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var disclaimerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(ADColor.border).frame(height: 0.6)
            Text("AVVERTENZA")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(ADColor.textLight)
            Text("Il presente documento ha natura puramente indicativa ed è elaborato sulla base dei parametri di riferimento di Arkai Domus per il mercato residenziale di pregio. Le stime di ristrutturazione e di analisi visiva degli ambienti non sostituiscono il giudizio di un tecnico abilitato; le valutazioni di sostenibilità del mutuo non costituiscono offerta da parte di alcun istituto bancario. Il documento è riservato all'utente destinatario.")
                .font(.system(size: 8))
                .foregroundStyle(ADColor.textLight)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Shared components

struct DossierPDFHeader: View {
    let pageNumber: Int
    let totalPages: Int
    let title: String

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(ADColor.primarySoft)
                    .frame(width: 14, height: 1.5)
                Text("ARKAI DOMUS · DOSSIER")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(ADColor.textMuted)
            }
            Spacer()
            Text(title.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(ADColor.textMuted)
            Spacer()
            Text("\(pageNumber) / \(totalPages)")
                .font(.system(size: 8, weight: .medium).monospacedDigit())
                .foregroundStyle(ADColor.textLight)
        }
        .padding(.bottom, 6)
        .overlay(
            Rectangle().fill(ADColor.border).frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct DossierPDFFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Rectangle().fill(ADColor.border).frame(height: 0.5)
            HStack {
                Text("© ARKAI DOMUS")
                    .font(.system(size: 7, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(ADColor.textLight)
                Spacer()
                Text("Documento riservato")
                    .font(.system(size: 7))
                    .foregroundStyle(ADColor.textLight)
            }
        }
    }
}

struct DossierPDFSectionLabel: View {
    let text: String
    let onPrimary: Bool

    init(_ text: String, onPrimary: Bool = false) {
        self.text = text
        self.onPrimary = onPrimary
    }

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(onPrimary ? Color.white.opacity(0.85) : ADColor.textMuted)
    }
}

struct DossierPDFFact: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 7, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(ADColor.textLight)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ADColor.text)
        }
    }
}

struct DossierPDFRow: View {
    enum Tone { case neutral, accent }
    let label: String
    let value: String
    var detail: String? = nil
    let tone: Tone

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(tone == .accent ? ADColor.accentWarm : ADColor.primarySoft)
                .frame(width: 3)
                .cornerRadius(1.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(ADColor.textMuted)
                Text(value)
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .foregroundStyle(ADColor.primary)
                if let detail {
                    Text(detail)
                        .font(.system(size: 9))
                        .foregroundStyle(ADColor.textLight)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Flexible HStack (capsule pills che vanno a capo)

struct FlexibleHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            content
        }
    }
}

#Preview("Cover") {
    DossierPDFCoverPage(
        property: Property.preview,
        dossier: previewDossier,
        userDisplayName: "Cesare Negro",
        generatedAt: Date(),
        heroImage: nil
    )
}

#Preview("Cover - with hero") {
    DossierPDFCoverPage(
        property: Property.preview,
        dossier: previewDossier,
        userDisplayName: "Cesare Negro",
        generatedAt: Date(),
        heroImage: previewHeroImage(width: 595, height: 522)
    )
}

private func previewHeroImage(width: CGFloat, height: CGFloat) -> UIImage {
    // Immagine sintetica: gradient diagonal sage-warm con texture
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
    return renderer.image { ctx in
        let cg = ctx.cgContext
        let colors = [
            UIColor(red: 0.32, green: 0.42, blue: 0.27, alpha: 1).cgColor,
            UIColor(red: 0.74, green: 0.65, blue: 0.41, alpha: 1).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray,
                                  locations: [0.0, 1.0])!
        cg.drawLinearGradient(gradient,
                              start: .zero,
                              end: CGPoint(x: width, y: height),
                              options: [])
        // Pattern: cerchi semi-trasparenti
        UIColor.white.withAlphaComponent(0.08).setFill()
        for _ in 0..<20 {
            let x = CGFloat.random(in: 0...width)
            let y = CGFloat.random(in: 0...height)
            let r = CGFloat.random(in: 30...80)
            UIBezierPath(ovalIn: CGRect(x: x, y: y, width: r, height: r)).fill()
        }
    }
}

#Preview("Summary") {
    DossierPDFSummaryPage(
        property: Property.preview,
        dossier: previewDossier,
        pageNumber: 2,
        totalPages: 4
    )
}

#Preview("Renovation") {
    let lines = (0..<6).map { i in
        DossierRenovationLine(
            itemID: UUID(),
            categoryID: nil,
            name: ["Tinteggiatura", "Pavimenti", "Sostituzione serramenti", "Punti acqua", "Sanitari", "Demolizioni"][i],
            level: "medium",
            quantity: [120, 95, 8, 4, 1, 30][i],
            unitPrice: [9.5, 35, 320, 180, 150, 18.5][i],
            lineTotal: [1140, 3325, 2560, 720, 150, 555][i],
            variantKey: nil,
            variantLabel: nil
        )
    }
    return DossierPDFRenovationPage(
        dossier: previewDossier,
        pageNumber: 3,
        totalPages: 4,
        items: lines,
        pageIndex: 0,
        totalItemPages: 1
    )
}

#Preview("Details") {
    DossierPDFDetailsPage(
        property: Property.preview,
        dossier: previewDossier,
        pageNumber: 4,
        totalPages: 4
    )
}

private var previewDossier: PropertyDossier {
    PropertyDossier(
        id: UUID(),
        userID: UUID(),
        propertyID: UUID(),
        askingPriceSnapshot: 780_000,
        avmZoneID: "PMP-120",
        avmEstimatedPerSqm: 9_500,
        avmEstimatedTotal: 745_000,
        mortgageEstimateID: nil,
        mortgageMonthlyPayment: 1_950,
        renovationTotal: 38_500,
        renovationItems: [],
        renovationDifficultyFactors: ["centro_storico", "ztl_access"],
        visualBOQEstimateIDs: [UUID(), UUID()],
        visualBOQTotal: 12_300,
        userNotes: nil,
        createdAt: nil,
        updatedAt: nil
    )
}
