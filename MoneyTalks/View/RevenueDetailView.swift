//
//  RevenueDetailView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import SwiftData
import SwiftUI

struct RevenueDetailView: View {

    let revenue: Revenue

    @Environment(RevenueRepository.self) private var repository
    @Environment(WalletRepository.self) private var walletRepository

    var body: some View {
        Form {
            Section("Classification") {
                LabeledContent("Category") { text(revenue.category) }
                Picker("Wallet", selection: walletSelection) {
                    Label("No Wallet", systemImage: "minus.circle")
                        .tag("")
                    ForEach(walletRepository.wallets) { wallet in
                        WalletLabel(wallet: wallet)
                            .tag(wallet.id.uuidString)
                    }
                }
                .pickerStyle(.menu)
                Toggle("Wallet Confirmed", isOn: walletConfirmedSelection)
                    .disabled(selectedWallet == nil)
                    .help(selectedWallet == nil ? "Select a wallet to confirm this revenue" : "")
            }

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
            Section("Note") {
                TextField("Add a note…", text: noteSelection, axis: .vertical)
                    .lineLimit(4...12)
            }

        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }

    /// The wallet stored on the revenue, resolved to a wallet that still exists.
    /// A deleted wallet resolves to no selection.
    private var selectedWallet: Wallet? {
        guard !revenue.wallet.isEmpty else { return nil }
        return walletRepository.wallets.first { $0.id.uuidString == revenue.wallet }
    }

    private var walletSelection: Binding<String> {
        Binding(
            get: { selectedWallet?.id.uuidString ?? "" },
            set: { repository.setWallet(UUID(uuidString: $0), for: revenue) }
        )
    }

    private var walletConfirmedSelection: Binding<Bool> {
        Binding(
            get: { revenue.walletConfirmed },
            set: { repository.setWalletConfirmed($0, for: revenue) }
        )
    }

    private var noteSelection: Binding<String> {
        Binding(
            get: { revenue.note },
            set: { repository.setNote($0, for: revenue) }
        )
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

private struct WalletLabel: View {

    let wallet: Wallet

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: wallet.imageName)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(wallet.color, in: Circle())
            Text(wallet.name)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let revenue = Revenue(
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
        wallet: "")
    let repository = RevenueRepository(modelContext: container.mainContext)
    repository.add(revenue)
    let walletRepository = WalletRepository(modelContext: container.mainContext)
    walletRepository.add(Wallet(name: "Girokonto", imageName: "banknote.fill", isIncomming: true, color: .blue))
    walletRepository.add(Wallet(name: "Kreditkarte", imageName: "creditcard.fill", isIncomming: false, color: .red))
    return RevenueDetailView(revenue: revenue)
        .environment(repository)
        .environment(walletRepository)
}