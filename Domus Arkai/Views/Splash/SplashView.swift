//
//  SplashView.swift
//  Domus Arkai
//
//  Spec: `01_ios_splash_brand_intro.json`. Durata max 1s, no animazioni invasive.
//

import SwiftUI

struct SplashView: View {
    var agencyName: String = "Arkai Domus"
    var onFinish: () -> Void

    @State private var opacity: Double = 0
    @State private var divider: CGFloat = 0

    var body: some View {
        ZStack {
            ADColor.background.ignoresSafeArea()

            VStack(spacing: ADSpacing.s5) {
                Spacer()

                VStack(spacing: ADSpacing.s3) {
                    Text(agencyName)
                        .font(ADTypography.pageTitle)
                        .foregroundStyle(ADColor.primary)

                    Rectangle()
                        .fill(ADColor.primarySoft)
                        .frame(width: divider, height: 1)

                    Text("powered by Arkai Domus")
                        .font(ADTypography.metadata)
                        .foregroundStyle(ADColor.textMuted)
                        .tracking(0.6)
                }
                .opacity(opacity)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        }
        .task {
            withAnimation(.easeOut(duration: 0.35)) {
                opacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                divider = 36
            }
            try? await Task.sleep(nanoseconds: 950_000_000)
            withAnimation(.easeIn(duration: 0.25)) {
                opacity = 0
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
