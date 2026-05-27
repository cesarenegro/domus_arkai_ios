//
//  VisionProInfoView.swift
//  Domus Arkai
//
//  Pagina informativa Arkai Vision PRO.
//  Workflow + Tecnologia in flow di card pastello con frecce animate
//  (tap-to-scroll alla card successiva).
//

import SwiftUI

struct VisionProInfoView: View {
    @State private var showCapture: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ADColor.background.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s6) {
                        heroHeader
                            .id("top")
                        workflowFlow(proxy: proxy)
                        technologyFlow(proxy: proxy)
                        precisionSection
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s4)
                }
                .scrollIndicators(.hidden)
            }

            ctaBar
        }
        .navigationTitle("Arkai Vision PRO")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCapture) {
            VisualBOQCaptureView(model: VisualBOQViewModel(property: nil))
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            visionBadge
            Text("L'AI proprietaria che riconosce lavori e costi.")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
                .fixedSize(horizontal: false, vertical: true)
            Image("VisionProHeroRoom")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.vertical, ADSpacing.s1)
            Text("Arkai Vision PRO è il nostro modello visivo proprietario, addestrato sui parametri tecnici del settore edile italiano per riconoscere finiture, criticità e interventi necessari in pochi secondi.")
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, ADSpacing.s3)
    }

    private var visionBadge: some View {
        HStack(spacing: ADSpacing.s2) {
            Text("A")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 0.78, green: 0.12, blue: 0.12))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle().stroke(Color(red: 0.78, green: 0.12, blue: 0.12), lineWidth: 1.2)
                )
            Text("ARKAI VisionPro")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, ADSpacing.s3)
        .padding(.vertical, ADSpacing.s2)
        .background(Color(red: 0.74, green: 0.91, blue: 0.20))
        .overlay(
            Capsule().stroke(Color(red: 0.85, green: 0.72, blue: 0.42), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Workflow flow

    private let workflowSteps: [FlowStep] = [
        FlowStep(id: "wf-1", number: "01", icon: "camera.fill", title: "Scatta o seleziona la foto", detail: "Una sola foto è sufficiente. Inquadra pavimento, pareti, finiture o eventuali criticità — il modello le riconoscerà istantaneamente.", tint: PastelPalette.sand, imageName: "VisionStep1Foto"),
        FlowStep(id: "wf-2", number: "02", icon: "mappin.and.ellipse", title: "Indica città e tipologia", detail: "Il costo viene calcolato sui listini italiani 2026 della città di riferimento, con il coefficiente regionale corretto.", tint: PastelPalette.sage, imageName: "VisionStep2Citta"),
        FlowStep(id: "wf-3", number: "03", icon: "slider.horizontal.3", title: "Aggiungi fattori di complessità", detail: "Centro storico, ZTL, piani alti, urgenze: il modello integra ogni vincolo reale del cantiere nella stima.", tint: PastelPalette.peach, imageName: "VisionStep3Fattori"),
        FlowStep(id: "wf-4", number: "04", icon: "doc.text.fill", title: "Ricevi il computo", detail: "Elenco opere, materiali, quantità e costo totale in formato professionale, pronto per il Dossier.", tint: PastelPalette.ivory, imageName: "VisionStep4Computo")
    ]

    private func workflowFlow(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            sectionHeader(eyebrow: "WORKFLOW", title: "Come funziona", subtitle: "Quattro passaggi, qualche secondo.")

            VStack(spacing: 0) {
                ForEach(Array(workflowSteps.enumerated()), id: \.element.id) { index, step in
                    FlowCard(step: step)
                        .id(step.id)
                    if index < workflowSteps.count - 1 {
                        FlowConnector {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo(workflowSteps[index + 1].id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Technology flow

    private let technologySteps: [FlowStep] = [
        FlowStep(id: "tech-1", number: "I", icon: "eye.fill", title: "Vede la stanza", detail: "Il modello identifica la tipologia di ambiente, le superfici e gli elementi architettonici principali partendo da una sola immagine.", tint: PastelPalette.terracotta, imageName: "VisionTech1Vede"),
        FlowStep(id: "tech-2", number: "II", icon: "square.grid.2x2.fill", title: "Riconosce materiali e finiture", detail: "Parquet, marmo, gres, intonaci, tinteggiature, rivestimenti: distingue qualità e stato di conservazione di ogni superficie.", tint: PastelPalette.lavender, imageName: "VisionTech2Materiali"),
        FlowStep(id: "tech-3", number: "III", icon: "wrench.and.screwdriver.fill", title: "Mappa gli interventi", detail: "Serramenti, porte, sanitari, impianti idraulici ed elettrici. Per ognuno determina se è necessario intervenire e con quale livello di lavoro.", tint: PastelPalette.dustBlue, imageName: "VisionTech3Interventi"),
        FlowStep(id: "tech-4", number: "IV", icon: "chart.bar.doc.horizontal.fill", title: "Calcola il costo", detail: "Incrocia gli interventi con il listino regionale, applica i coefficienti di complessità e restituisce il computo metrico professionale.", tint: PastelPalette.mint, imageName: "VisionTech4Costo")
    ]

    private func technologyFlow(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            sectionHeader(eyebrow: "TECNOLOGIA", title: "Cosa c'è dietro", subtitle: "Quattro capacità del modello, in ordine.")

            VStack(spacing: 0) {
                ForEach(Array(technologySteps.enumerated()), id: \.element.id) { index, step in
                    FlowCard(step: step)
                        .id(step.id)
                    if index < technologySteps.count - 1 {
                        FlowConnector {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo(technologySteps[index + 1].id, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s2) {
            Text(eyebrow)
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text(title)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
            Text(subtitle)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
        }
    }

    // MARK: - Precision (card singola)

    private var precisionSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("PRECISIONE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Capitolato professionale")
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
            Text("Ogni stima è calibrata sul listino base nazionale, sul coefficiente regionale della tua città e sui fattori di complessità del cantiere. Il risultato è un report dettagliato — non una stima a colpo d'occhio.")
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Cinque analisi gratuite al mese. Salva l'esito nel Dossier per portarlo all'agenzia, alla banca, al notaio.")
                .font(ADTypography.small)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s5)
        .background(ADColor.surfaceSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - CTA bar

    private var ctaBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [ADColor.background.opacity(0), ADColor.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 28)

            Button { showCapture = true } label: {
                HStack(spacing: ADSpacing.s2) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Avvia analisi stanza")
                        .font(ADTypography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ADColor.primary)
                .foregroundStyle(ADColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
            .padding(.bottom, ADSpacing.s4)
            .background(ADColor.background)
        }
    }
}

// MARK: - Shared flow card model + components (riusati in RenovationInfoView)

struct FlowStep: Identifiable {
    let id: String
    let number: String
    let icon: String
    let title: String
    let detail: String
    let tint: Color
    /// Se valorizzato, la card mostra un'immagine wide in alto al posto del cerchio-icona.
    var imageName: String? = nil
}

enum PastelPalette {
    static let sand        = Color(red: 0.945, green: 0.910, blue: 0.847)
    static let sage        = Color(red: 0.866, green: 0.898, blue: 0.827)
    static let peach       = Color(red: 0.945, green: 0.866, blue: 0.788)
    static let ivory       = Color(red: 0.937, green: 0.898, blue: 0.831)
    static let terracotta  = Color(red: 0.913, green: 0.835, blue: 0.796)
    static let lavender    = Color(red: 0.886, green: 0.866, blue: 0.905)
    static let dustBlue    = Color(red: 0.847, green: 0.882, blue: 0.898)
    static let mint        = Color(red: 0.835, green: 0.898, blue: 0.866)
    static let rose        = Color(red: 0.945, green: 0.874, blue: 0.866)
}

struct FlowCard: View {
    let step: FlowStep

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let imageName = step.imageName {
                ZStack(alignment: .topLeading) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    numberBadge
                        .padding(ADSpacing.s2)
                }
            }

            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                if step.imageName == nil {
                    HStack(alignment: .center) {
                        numberBadge
                        Spacer(minLength: ADSpacing.s3)
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.7))
                                .frame(width: 44, height: 44)
                            Image(systemName: step.icon)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(ADColor.primary)
                        }
                    }
                }

                Text(step.title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(ADColor.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(ADColor.text.opacity(0.78))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(step.tint)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ADColor.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var numberBadge: some View {
        ZStack {
            Circle()
                .fill(ADColor.primary)
                .frame(width: 34, height: 34)
                .overlay(
                    Circle().stroke(.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: ADColor.primary.opacity(0.35), radius: 4, x: 0, y: 2)
            Text(step.number)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(.white)
        }
    }
}

struct FlowConnector: View {
    let onTap: () -> Void
    @State private var animate: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Rectangle()
                    .fill(ADColor.accentWarm.opacity(0.4))
                    .frame(width: 1, height: 16)
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ADColor.accentWarm)
                    .offset(y: animate ? 6 : -2)
                    .opacity(animate ? 0.55 : 1.0)
                Text("tocca per continuare")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(ADColor.accentWarm.opacity(animate ? 0.5 : 0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ADSpacing.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        VisionProInfoView()
    }
}
