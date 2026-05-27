//
//  ADRadius.swift
//  Domus Arkai
//

import CoreGraphics

enum ADRadius {
    static let sm: CGFloat = 8
    static let input: CGFloat = 12
    static let md: CGFloat = 14
    static let card: CGFloat = 20
    static let panel: CGFloat = 24
    static let large: CGFloat = 28
}

enum ADShadow {
    static let cardOffset = CGSize(width: 0, height: 12)
    static let cardRadius: CGFloat = 30
    static let cardOpacity: Double = 0.08

    static let softOffset = CGSize(width: 0, height: 8)
    static let softRadius: CGFloat = 20
    static let softOpacity: Double = 0.06
}
