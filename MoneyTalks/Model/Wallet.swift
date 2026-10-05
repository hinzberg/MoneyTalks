//
//  Wallet.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation
import SwiftData

@Model
final class Wallet: Hashable {

    @Attribute(.unique) var id: UUID

    /// Name of the wallet, e.g. "Girokonto"
    var name: String

    /// IBAN of the wallet account
    var iban: String

    /// Preferred ISO currency code of the wallet
    var currency: String

    init(id: UUID = UUID(), name: String, iban: String, currency: String = "EUR") {
        self.id = id
        self.name = name
        self.iban = iban
        self.currency = currency
    }
}