//
//  RenovationInfoView.swift
//  Domus Arkai
//
//  Pagina informativa: come funziona la Stima Ristrutturazione.
//  Stesso pattern di Arkai Vision PRO: flow di card pastello con
//  frecce animate tap-to-scroll + banner prerequisito.
//

import SwiftUI

struct RenovationInfoView: View {
    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: ADSpacing.s6) {
                        heroHeader
                            .id("top")
                        prerequisiteNote
                        workflowFlow(proxy: proxy)
                        categoriesFlow(proxy: proxy)
                        regionalizedSection
                        Color.clear.frame(height: ADSpacing.s8)
                    }
                    .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
                    .padding(.top, ADSpacing.s4)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Stima ristrutturazione")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("CONFIGURATORE PARAMETRICO")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Quanto costa renderla tua.")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
                .fixedSize(horizontal: false, vertical: true)
            Image("RenovationHeroDetail")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.vertical, ADSpacing.s1)
            Text("Una stima dettagliata e trasparente di ogni intervento di ristrutturazione, basata su configuratori parametrici e listini italiani regionalizzati 2026.")
                .font(ADTypography.body)
                .foregroundStyle(ADColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, ADSpacing.s3)
    }

    // MARK: - Prerequisite note (richiesta di Cesare)

    private var prerequisiteNote: some View {
        HStack(alignment: .top, spacing: ADSpacing.s3) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(ADColor.accentWarm)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: ADSpacing.s1) {
                Text("Come si attiva")
                    .font(ADTypography.smallMedium.weight(.semibold))
                    .foregroundStyle(ADColor.primary)
                Text("La Stima ristrutturazione funziona solo dopo aver selezionato un immobile dalla Lista immobili. Apri un immobile dal catalogo per avviare il configuratore.")
                    .font(ADTypography.small)
                    .foregroundStyle(ADColor.text.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s4)
        .background(ADColor.primaryLight.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ADColor.primarySoft.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Workflow flow

    private let workflowSteps: [FlowStep] = [
        FlowStep(id: "ren-1", number: "01", icon: "house.fill", title: "Selezioni l'immobile", detail: "Apri un immobile dal catalogo. La stima parte automaticamente dai suoi metri quadri e dalla città di riferimento.", tint: PastelPalette.sand, imageName: "RenoStep1Selezioni"),
        FlowStep(id: "ren-2", number: "02", icon: "slider.horizontal.below.rectangle", title: "Configuri gli interventi", detail: "Per ogni categoria scegli materiali, finiture e quantità — come faresti con un capitolato professionale, con la guida di chip e selettori dedicati.", tint: PastelPalette.peach, imageName: "RenoStep2Configuri"),
        FlowStep(id: "ren-3", number: "03", icon: "doc.text.fill", title: "Ricevi il computo", detail: "Costo totale e dettaglio voce per voce. Salva il risultato nel Dossier personale e scaricalo come PDF da consegnare a banca, agenzia o notaio.", tint: PastelPalette.sage, imageName: "RenoStep3Computo")
    ]

    private func workflowFlow(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            sectionHeader(eyebrow: "COME FUNZIONA", title: "Tre passaggi", subtitle: "Dalla selezione al computo, in pochi tap.")

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

    // MARK: - Categories flow

    private let categorySteps: [FlowStep] = [
        FlowStep(id: "cat-1", number: "I", icon: "square.grid.2x2", title: "Pavimenti", detail: "Parquet rovere, teak, ciliegio o wengè · marmo di Carrara · gres porcellanato · resine continue · finiture sintetiche.", tint: PastelPalette.terracotta, imageName: "RenoCatPavimenti"),
        FlowStep(id: "cat-2", number: "II", icon: "paintbrush.fill", title: "Tinteggiature e pareti", detail: "Pittura tradizionale o traspirante · intonaci minerali · rivestimenti decorativi · cartongesso e contropareti.", tint: PastelPalette.ivory, imageName: "RenoCatTinteggiature"),
        FlowStep(id: "cat-3", number: "III", icon: "rectangle.portrait", title: "Serramenti e porte", detail: "PVC, alluminio termico, legno massello · porte di design e blindate · sistemi vetrati e oscuranti.", tint: PastelPalette.lavender, imageName: "RenoCatSerramenti"),
        FlowStep(id: "cat-4", number: "IV", icon: "stove.fill", title: "Cucine su misura", detail: "Metri lineari, isole centrali, top in pietra naturale o quarzo, elettrodomestici da incasso premium.", tint: PastelPalette.dustBlue, imageName: "RenoCatCucine"),
        FlowStep(id: "cat-5", number: "V", icon: "thermometer.sun.fill", title: "Climatizzazione e riscaldamento", detail: "Caloriferi alta efficienza · pompe di calore inverter · pavimento radiante · stufe a pellet o biocamini.", tint: PastelPalette.mint, imageName: "RenoCatClimatizzazione"),
        FlowStep(id: "cat-6", number: "VI", icon: "bolt.fill", title: "Impianti elettrici e domotica", detail: "Impianto tradizionale o domotico evoluto · idraulico · gas · sistemi di sicurezza e antifurto integrati.", tint: PastelPalette.rose, imageName: "RenoCatImpianti")
    ]

    private func categoriesFlow(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: ADSpacing.s4) {
            sectionHeader(eyebrow: "CATEGORIE", title: "Cosa puoi configurare", subtitle: "Sei famiglie di intervento, parametriche.")

            VStack(spacing: 0) {
                ForEach(Array(categorySteps.enumerated()), id: \.element.id) { index, step in
                    FlowCard(step: step)
                        .id(step.id)
                    if index < categorySteps.count - 1 {
                        FlowConnector {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo(categorySteps[index + 1].id, anchor: .top)
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

    // MARK: - Regionalized (card singola)

    private var regionalizedSection: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            Text("PRECISIONE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Listini italiani regionalizzati")
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(ADColor.primary)
            Text("I costi sono calibrati città per città sul mercato italiano 2026. Il modello tiene conto delle complessità reali del cantiere:")
                .font(ADTypography.body)
                .foregroundStyle(ADColor.text)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: ADSpacing.s2) {
                BulletText(text: "Coefficiente regionale (es. Milano 1,12 — Bari 0,87)")
                BulletText(text: "Centro storico, ZTL, accessibilità del cantiere")
                BulletText(text: "Piano alto, condominio, vincoli architettonici")
                BulletText(text: "Tempi di esecuzione e stagione di intervento")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ADSpacing.s5)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct BulletText: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            Circle()
                .fill(ADColor.accentWarm.opacity(0.7))
                .frame(width: 5, height: 5)
                .padding(.top, 8)
            Text(text)
                .font(ADTypography.small)
                .foregroundStyle(ADColor.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack {
        RenovationInfoView()
    }
}
