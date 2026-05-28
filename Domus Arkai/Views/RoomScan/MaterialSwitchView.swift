//
//  MaterialSwitchView.swift
//  Domus Arkai
//
//  v2.1 (punto 3/5) — Switch materiali su USDZ con RealityKit.
//  Mostra il modello in un viewer 3D interattivo (rotazione/zoom/pan
//  gestures native di RealityView) + pillole per cambiare la finitura
//  materiale (Rovere / Gres / Calacatta) applicando un PhysicallyBasedMaterial
//  override a tutti i ModelEntity della scena.
//
//  Limite noto: il material override è "all surfaces" perché il USDZ generico
//  bundlato non ha mesh nominati semanticamente. Quando Marco genererà USDZ
//  con naming "Floor"/"Wall"/"Counter", possiamo evolvere ad uno switch
//  mesh-specifico (es. solo pavimento).
//

import SwiftUI
import RealityKit

@MainActor
struct MaterialSwitchView: View {
    let usdzURL: URL

    @Environment(\.dismiss) private var dismiss

    @State private var rootEntity: Entity?
    @State private var selectedMaterial: MaterialOption = .oak
    @State private var loadError: String?

    enum MaterialOption: String, CaseIterable, Identifiable {
        case oak     = "Rovere"
        case stone   = "Gres"
        case marble  = "Calacatta"

        var id: String { rawValue }

        var tint: UIColor {
            switch self {
            case .oak:    return UIColor(red: 0.78, green: 0.62, blue: 0.43, alpha: 1)
            case .stone:  return UIColor(red: 0.42, green: 0.40, blue: 0.38, alpha: 1)
            case .marble: return UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
            }
        }

        var roughness: Float {
            switch self {
            case .oak:    return 0.65
            case .stone:  return 0.45
            case .marble: return 0.15
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                await loadModel(into: content)
            }
            .background(ADColor.background)
            .ignoresSafeArea()

            VStack(spacing: ADSpacing.s3) {
                if let loadError {
                    errorBanner(loadError)
                }
                materialPills
            }
            .padding(.horizontal, ADSpacing.s4)
            .padding(.bottom, ADSpacing.s4)

            VStack {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, ADSpacing.s4)
                .padding(.top, ADSpacing.s5)
                Spacer()
            }
        }
    }

    // MARK: - Subviews

    private var closeButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: ADSpacing.s1) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                Text("Chiudi")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s2)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var materialPills: some View {
        HStack(spacing: ADSpacing.s2) {
            ForEach(MaterialOption.allCases) { option in
                Button {
                    selectedMaterial = option
                    applyMaterial(option)
                } label: {
                    materialPill(option, selected: option == selectedMaterial)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func materialPill(_ option: MaterialOption, selected: Bool) -> some View {
        HStack(spacing: ADSpacing.s1) {
            Circle()
                .fill(Color(option.tint))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            Text(option.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? ADColor.background : .white)
        }
        .padding(.horizontal, ADSpacing.s3)
        .padding(.vertical, ADSpacing.s2)
        .background(selected ? ADColor.primary : Color.black.opacity(0.5))
        .overlay(
            Capsule().stroke(.white.opacity(selected ? 0.7 : 0.2), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ADSpacing.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(ADSpacing.s3)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Loading + material swap

    private func loadModel(into content: RealityViewCameraContent) async {
        do {
            let entity = try await Entity(contentsOf: usdzURL)
            entity.position = SIMD3<Float>(0, 0, 0)
            content.add(entity)
            rootEntity = entity
            applyMaterial(selectedMaterial)
        } catch {
            loadError = "Impossibile caricare USDZ: \(error.localizedDescription)"
            print("🔴 [MaterialSwitch] load failed — \(error.localizedDescription)")
        }
    }

    private func applyMaterial(_ option: MaterialOption) {
        guard let rootEntity else { return }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: option.tint)
        material.roughness = .init(floatLiteral: option.roughness)
        material.metallic = .init(floatLiteral: 0)
        applyMaterialRecursive(to: rootEntity, material: material)
        print("✅ [MaterialSwitch] applied \(option.rawValue)")
    }

    private func applyMaterialRecursive(to entity: Entity, material: PhysicallyBasedMaterial) {
        if let modelEntity = entity as? ModelEntity, var model = modelEntity.model {
            model.materials = Array(repeating: material, count: max(1, model.materials.count))
            modelEntity.model = model
        }
        for child in entity.children {
            applyMaterialRecursive(to: child, material: material)
        }
    }
}
