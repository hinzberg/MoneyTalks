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



