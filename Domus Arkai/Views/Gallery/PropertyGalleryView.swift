//
//  PropertyGalleryView.swift
//  Domus Arkai
//
//  Spec: `05_ios_gallery.json`. Fullscreen viewer, swipe, zoom (pinch),
//  counter glass, back/share buttons glass.
//

import SwiftUI

struct PropertyGalleryView: View {
    let media: [PropertyMedia]

    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    ZoomableImage(url: item.url)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                topBar
                Spacer()
                bottomCounter
            }
        }
        .statusBarHidden()
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                // share placeholder
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ADSpacing.Screen.horizontalPadding)
        .padding(.top, ADSpacing.s2)
    }

    private var bottomCounter: some View {
        Text("\(currentIndex + 1) di \(media.count)")
            .font(ADTypography.smallMedium)
            .foregroundStyle(.white)
            .padding(.horizontal, ADSpacing.s4)
            .padding(.vertical, ADSpacing.s2)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)
            .padding(.bottom, ADSpacing.s5)
    }
}

private struct ZoomableImage: View {
    let url: URL

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1, min(4, lastScale * value))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale <= 1 {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + gesture.translation.width,
                                            height: lastOffset.height + gesture.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if scale > 1 {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                case .empty:
                    ProgressView().tint(.white)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
