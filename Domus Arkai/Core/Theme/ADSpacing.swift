//
//  ADSpacing.swift
//  Domus Arkai
//
//  8-point spacing system.
//

import CoreGraphics

enum ADSpacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32
    static let s7: CGFloat = 40
    static let s8: CGFloat = 48
    static let s9: CGFloat = 64

    enum Card {
        static let paddingSmall: CGFloat = 16
        static let paddingLarge: CGFloat = 24
    }

    enum Screen {
        static let horizontalPadding: CGFloat = 20
        static let horizontalPaddingCompact: CGFloat = 16
        static let sectionGap: CGFloat = 24
    }
}
