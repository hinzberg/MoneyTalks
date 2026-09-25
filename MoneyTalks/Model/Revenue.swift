//
//  Revenue.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation

struct Revenue: Identifiable, Codable, Hashable, Sendable {

    let id = UUID()

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

    var categorizedPurpose: String
}
