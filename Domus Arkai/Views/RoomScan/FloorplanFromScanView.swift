//
//  FloorplanFromScanView.swift
//  Domus Arkai
//
//  v2.1 — Floorplan 2D autogenerata dal `CapturedRoom` di RoomPlan.
//  Proiezione top-down (piano xz) di walls, porte, finestre, oggetti rilevati.
//  Tutto client-side: zero dipendenze da server o API esterne.
//

import SwiftUI
import RoomPlan
import simd

struct FloorplanFromScanView: View {
    let room: CapturedRoom

    private struct Bounds {
        let minX: Float
        let maxX: Float
        let minZ: Float
        let maxZ: Float

        var width: Float { maxX - minX }
        var depth: Float { maxZ - minZ }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ADSpacing.s3) {
            header
            canvasCard
            legend
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PLANIMETRIA 2D")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ADColor.accentWarm)
            Text("Vista dall'alto")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(ADColor.primary)
            Text("Generata automaticamente dalla scansione · scala approssimata")
                .font(ADTypography.metadata)
                .foregroundStyle(ADColor.textMuted)
        }
    }

    private var canvasCard: some View {
        Canvas { context, size in
            let bounds = computeBounds()
            let scale = computeScale(for: bounds, canvasSize: size)
            let offset = computeOffset(for: bounds, scale: scale, canvasSize: size)

            // 1. Walls — linea spessa primary
            for wall in room.walls {
                drawSegment(
                    transform: wall.transform,
                    width: wall.dimensions.x,
                    in: context,
                    scale: scale, offset: offset,
                    color: ADColor.primary,
                    lineWidth: 3
                )
            }

            // 2. Doors — gap arancione sand
            for door in room.doors {
                drawSegment(
                    transform: door.transform,
                    width: door.dimensions.x,
                    in: context,
                    scale: scale, offset: offset,
                    color: ADColor.accentWarm,
                    lineWidth: 4
                )
            }

            // 3. Windows — linea tratteggiata
            for window in room.windows {
                drawSegment(
                    transform: window.transform,
                    width: window.dimensions.x,
                    in: context,
                    scale: scale, offset: offset,
                    color: ADColor.primarySoft,
                    lineWidth: 2.5,
                    dashed: true
                )
            }

            // 4. Openings — gap chiaro
            for opening in room.openings {
                drawSegment(
                    transform: opening.transform,
                    width: opening.dimensions.x,
                    in: context,
                    scale: scale, offset: offset,
                    color: ADColor.textLight,
                    lineWidth: 2,
                    dashed: true
                )
            }

            // 5. Objects — piccoli rettangoli
            for object in room.objects {
                drawObject(object: object, in: context, scale: scale, offset: offset)
            }
        }
        .frame(height: 280)
        .padding(ADSpacing.s4)
        .background(ADColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ADColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var legend: some View {
        HStack(spacing: ADSpacing.s4) {
            legendItem(color: ADColor.primary, label: "Pareti")
            legendItem(color: ADColor.accentWarm, label: "Porte")
            legendItem(color: ADColor.primarySoft, label: "Finestre")
            legendItem(color: ADColor.textLight, label: "Aperture")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ADSpacing.s1)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 14, height: 3)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(ADColor.textMuted)
        }
    }

    // MARK: - Drawing helpers

    private func drawSegment(
        transform: simd_float4x4,
        width: Float,
        in context: GraphicsContext,
        scale: CGFloat,
        offset: CGPoint,
        color: Color,
        lineWidth: CGFloat,
        dashed: Bool = false
    ) {
        let half = width / 2
        let p1Local = SIMD4<Float>(-half, 0, 0, 1)
        let p2Local = SIMD4<Float>(half, 0, 0, 1)
        let p1World = transform * p1Local
        let p2World = transform * p2Local
        let cgP1 = project(p1World, scale: scale, offset: offset)
        let cgP2 = project(p2World, scale: scale, offset: offset)
        var path = Path()
        path.move(to: cgP1)
        path.addLine(to: cgP2)
        var style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        if dashed {
            style.dash = [3, 4]
        }
        context.stroke(path, with: .color(color), style: style)
    }

    private func drawObject(object: CapturedRoom.Object, in context: GraphicsContext, scale: CGFloat, offset: CGPoint) {
        // Disegno l'oggetto come piccolo rettangolo ruotato (footprint xz)
        let halfX = object.dimensions.x / 2
        let halfZ = object.dimensions.z / 2
        let corners: [SIMD4<Float>] = [
            SIMD4(-halfX, 0, -halfZ, 1),
            SIMD4(halfX, 0, -halfZ, 1),
            SIMD4(halfX, 0, halfZ, 1),
            SIMD4(-halfX, 0, halfZ, 1)
        ]
        let worldCorners = corners.map { object.transform * $0 }
        let cgCorners = worldCorners.map { project($0, scale: scale, offset: offset) }
        var path = Path()
        path.move(to: cgCorners[0])
        for i in 1..<cgCorners.count { path.addLine(to: cgCorners[i]) }
        path.closeSubpath()
        context.fill(path, with: .color(ADColor.surfaceSoft))
        context.stroke(path, with: .color(ADColor.textLight), lineWidth: 0.8)
    }

    // MARK: - Geometry math

    private func computeBounds() -> Bounds {
        var minX: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude
        var maxZ: Float = -.greatestFiniteMagnitude

        // Use walls endpoints come anchor del bounding box
        for wall in room.walls {
            let half = wall.dimensions.x / 2
            for x in [-half, half] {
                let local = SIMD4<Float>(Float(x), 0, 0, 1)
                let world = wall.transform * local
                minX = min(minX, world.x)
                maxX = max(maxX, world.x)
                minZ = min(minZ, world.z)
                maxZ = max(maxZ, world.z)
            }
        }
        // Fallback per scan senza walls
        if minX == .greatestFiniteMagnitude {
            minX = -2; maxX = 2; minZ = -2; maxZ = 2
        }
        return Bounds(minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ)
    }

    private func computeScale(for bounds: Bounds, canvasSize: CGSize) -> CGFloat {
        let padding: CGFloat = 24
        let availableW = canvasSize.width - padding * 2
        let availableH = canvasSize.height - padding * 2
        let sx = availableW / CGFloat(max(bounds.width, 0.01))
        let sz = availableH / CGFloat(max(bounds.depth, 0.01))
        return min(sx, sz)
    }

    private func computeOffset(for bounds: Bounds, scale: CGFloat, canvasSize: CGSize) -> CGPoint {
        let totalW = CGFloat(bounds.width) * scale
        let totalH = CGFloat(bounds.depth) * scale
        let offsetX = (canvasSize.width - totalW) / 2 - CGFloat(bounds.minX) * scale
        let offsetY = (canvasSize.height - totalH) / 2 - CGFloat(bounds.minZ) * scale
        return CGPoint(x: offsetX, y: offsetY)
    }

    private func project(_ world: SIMD4<Float>, scale: CGFloat, offset: CGPoint) -> CGPoint {
        let x = CGFloat(world.x) * scale + offset.x
        let y = CGFloat(world.z) * scale + offset.y
        return CGPoint(x: x, y: y)
    }
}
