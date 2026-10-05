//  Wallet.swift
//  MoneyTalks
//  Created by Holger Hinzberg on 25.09.26.

import SwiftUI
import SwiftData

@Model
final class Wallet: Hashable {

    @Attribute(.unique) var id: UUID

    var name: String
    var imageName: String
    var colorHex: String
    var isIncomming : Bool

    var color: Color {
        get { Color(hex: colorHex) ?? .red }
        set { colorHex = newValue.toHex() ?? "#FF0000" }
    }

    init(name: String, imageName: String, isIncomming: Bool, color : Color = Color.red) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.colorHex = color.toHex() ?? "#FF0000"
        self.isIncomming = isIncomming
    }
}

// Helper extension for Color <-> hex string
extension Color {
    init?(hex: String) {
        let r, g, b, a: Double
        var hexColor = hex
        if hexColor.hasPrefix("#") { hexColor.removeFirst() }
        guard hexColor.count == 6 || hexColor.count == 8,
            let int = UInt64(hexColor, radix: 16) else { return nil }
        if hexColor.count == 8 {
            r = Double((int & 0xFF000000) >> 24) / 255.0
            g = Double((int & 0x00FF0000) >> 16) / 255.0
            b = Double((int & 0x0000FF00) >> 8) / 255.0
            a = Double( int & 0x000000FF       ) / 255.0
        } else {
            r = Double((int & 0xFF0000) >> 16) / 255.0
            g = Double((int & 0x00FF00) >> 8) / 255.0
            b = Double( int & 0x0000FF      ) / 255.0
            a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    func toHex() -> String? {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif
        let nativeColor = NativeColor(self)
        guard let cgColor = nativeColor.cgColor.copy(alpha: 1.0),
              let components = cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        let a = Int(nativeColor.cgColor.alpha * 255)
        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

