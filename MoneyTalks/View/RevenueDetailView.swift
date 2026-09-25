//
//  RevenueDetailView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import SwiftUI

struct RevenueDetailView: View {

    let revenue: Revenue

    var body: some View {
        Form {
            Section("Booking") {
                LabeledContent("Account Number") { text(revenue.accountNumber) }
                LabeledContent("Booking Date") { date(revenue.bookingDate) }
                LabeledContent("Value Date") { date(revenue.valueDate) }
                LabeledContent("Booking Text") { text(revenue.bookingText) }
                LabeledContent("Info") { text(revenue.info) }
                LabeledContent("Purpose") { text(revenue.purpose) }
            }
            Section("Counterparty") {
                LabeledContent("Beneficiary or Payer") { text(revenue.beneficiaryOrPayer) }
                LabeledContent("IBAN") { text(revenue.iban) }
                LabeledContent("BIC") { text(revenue.bic) }
            }
            Section("Amount") {
                LabeledContent("Amount") { amount(revenue.amount) }
                LabeledContent("Currency") { text(revenue.currency) }
                LabeledContent("Original Amount") { amount(revenue.originalDirectDebitAmount) }
                LabeledContent("Return Costs") { amount(revenue.directDebitReturnCosts) }
            }
            Section("SEPA") {
                LabeledContent("Creditor ID") { text(revenue.creditorIdentifier) }
                LabeledContent("Mandate Reference") { text(revenue.mandateReference) }
                LabeledContent("End-to-End Reference") { text(revenue.endToEndReference) }
                LabeledContent("Collector Reference") { text(revenue.collectorReference) }
            }
            Section("Classification") {
                LabeledContent("Category") { text(revenue.category) }
                LabeledContent("Categorized Purpose") { text(revenue.categorizedPurpose) }
                LabeledContent("Note") { text(revenue.note) }
            }
        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }

    private func text(_ value: String?) -> Text {
        guard let value, !value.isEmpty else { return Text("—") }
        return Text(value)
    }

    private func date(_ value: Date) -> Text {
        Text(value, format: .dateTime.day().month(.twoDigits).year())
    }

    private func amount(_ value: Decimal?) -> Text {
        guard let value else { return Text("—") }
        return Text(value, format: .currency(code: revenue.currency))
    }
}

#Preview {
    RevenueDetailView(revenue: Revenue(
        accountNumber: "DE43443500600018309831",
        bookingDate: Date(timeIntervalSince1970: 1_790_745_600),
        valueDate: Date(timeIntervalSince1970: 1_790_832_000),
        bookingText: "FOLGELASTSCHRIFT",
        purpose: "Mobilfunk Kundenkonto 0032292074 RG 37167193000621/15.09.2026",
        creditorIdentifier: "DE93ZZZ00000078611",
        mandateReference: "DE000205000610000000000000001177739",
        endToEndReference: nil,
        collectorReference: nil,
        originalDirectDebitAmount: nil,
        directDebitReturnCosts: nil,
        beneficiaryOrPayer: "Telekom Deutschland GmbH",
        iban: "DE07512108001095000911",
        bic: "SOGEDEFFXXX",
        amount: -49.95,
        currency: "EUR",
        info: "Umsatz vorgemerkt",
        category: nil,
        note: "",
        categorizedPurpose: ""))
}
