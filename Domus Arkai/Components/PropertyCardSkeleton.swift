//
//  PropertyCardSkeleton.swift
//  Domus Arkai
//

import SwiftUI

struct PropertyCardSkeleton: View {
    @State private var pulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(shimmerColor)
                .aspectRatio(16/10, contentMode: .fit)

            GeometryReader { proxy in
                let w = proxy.size.width
                VStack(alignment: .leading, spacing: ADSpacing.s2) {
                    Capsule().fill(shimmerColor).frame(width: w * 0.40, height: 22)
                    Capsule().fill(shimmerColor).frame(width: w * 0.78, height: 18).padding(.top, ADSpacing.s1)
                    Capsule().fill(shimmerColor).frame(width: w * 0.55, height: 12)
                    Capsule().fill(shimmerColor).frame(width: w * 0.70, height: 10).padding(.top, ADSpacing.s1)
                }
                .padding(ADSpacing.Card.paddingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
        }
        .background(ADColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ADRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ADRadius.card)
                .stroke(ADColor.border.opacity(0.6), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var shimmerColor: Color {
        ADColor.surfaceSoft.opacity(pulse ? 1.0 : 0.55)
    }
}

#Preview {
    PropertyCardSkeleton()
        .padding()
        .background(ADColor.background)
}
