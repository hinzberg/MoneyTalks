//
//  Revenue.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import CryptoKit
import Foundation
import SwiftData

@Model
final class Revenue: Hashable {

    /// Deterministic UUID derived from "Kundenreferenz (End-to-End)", or from booking date, purpose and beneficiary combined
    @Attribute(.unique) var id: UUID

    /// "Auftragskonto" – account the booking belongs to (own IBAN)
    var accountNumber: String

    /// "Buchungstag" – date the booking was entered (CSV format: dd.MM.yy)
    var bookingDate: Date

    /// "Valutadatum" – date the booking becomes effective (CSV format: dd.MM.yy)
    var valueDate: Date

    /// "Buchungstext" – booking type, e.g. FOLGELASTSCHRIFT
    var bookingText: String

    /// "Verwendungszweck" – purpose of the transfer
    var purpose: String

    /// "Glaeubiger ID" – SEPA creditor identifier
    var creditorIdentifier: String?

    /// "Mandatsreferenz" – SEPA mandate reference
    var mandateReference: String?

    /// "Kundenreferenz (End-to-End)" – SEPA end-to-end reference
    var endToEndReference: String?

    /// "Sammlerreferenz" – collector reference
    var collectorReference: String?

    /// "Lastschrift Ursprungsbetrag" – original amount of the underlying direct debit
    var originalDirectDebitAmount: Decimal?

    /// "Auslagenersatz Ruecklastschrift" – costs reimbursed for a returned direct debit
    var directDebitReturnCosts: Decimal?

    /// "Beguenstigter/Zahlungspflichtiger" – beneficiary or payer name
    var beneficiaryOrPayer: String

    /// "Kontonummer/IBAN" – counterparty account number / IBAN
    var iban: String

    /// "BIC (SWIFT-Code)" – counterparty BIC (SWIFT code), may contain trailing spaces
    var bic: String

    /// "Betrag" – amount, negative for money spent, positive for money received
    var amount: Decimal

    /// "Waehrung" – ISO currency code of the amount
    var currency: String

    /// "Info" – additional booking information, e.g. Umsatz gebucht
    var info: String

    /// "Kategorie" – user defined category
    var category: String?

    var note: String

    var wallet: String

    var walletConfirmed: Bool

    init(accountNumber: String,
         bookingDate: Date,
         valueDate: Date,
         bookingText: String,
         purpose: String,
         creditorIdentifier: String?,
         mandateReference: String?,
         endToEndReference: String?,
         collectorReference: String?,
         originalDirectDebitAmount: Decimal?,
         directDebitReturnCosts: Decimal?,
         beneficiaryOrPayer: String,
         iban: String,
         bic: String,
         amount: Decimal,
         currency: String,
         info: String,
         category: String?,
         note: String = "",
         wallet: String = "",
         walletConfirmed: Bool = false) {
        self.id = Self.stableUUID(from: Self.identifier(endToEndReference: endToEndReference,
                                                          bookingDate: bookingDate,
                                                          purpose: purpose,
                                                          beneficiaryOrPayer: beneficiaryOrPayer))
        self.accountNumber = accountNumber
        self.bookingDate = bookingDate
        self.valueDate = valueDate
        self.bookingText = bookingText
        self.purpose = purpose
        self.creditorIdentifier = creditorIdentifier
        self.mandateReference = mandateReference
        self.endToEndReference = endToEndReference
        self.collectorReference = collectorReference
        self.originalDirectDebitAmount = originalDirectDebitAmount
        self.directDebitReturnCosts = directDebitReturnCosts
        self.beneficiaryOrPayer = beneficiaryOrPayer
        self.iban = iban
        self.bic = bic
        self.amount = amount
        self.currency = currency
        self.info = info
        self.category = category
        self.note = note
        self.wallet = wallet
        self.walletConfirmed = walletConfirmed
    }

    private static func identifier(endToEndReference: String?,
                                   bookingDate: Date,
                                   purpose: String,
                                   beneficiaryOrPayer: String) -> String {
        if let endToEndReference, !endToEndReference.isEmpty {
            return endToEndReference
        }
        return "\(bookingDay(bookingDate))|\(purpose)|\(beneficiaryOrPayer)"
    }

    private static func bookingDay(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func stableUUID(from identifier: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(identifier.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}